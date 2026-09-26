from datetime import datetime, date, timedelta, timezone
from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import User, SmokingLog, CravingEvent, DailyTarget, Achievement, UserAchievement
from app.schemas.schemas import ProgressSummaryResponse, AchievementItem
from app.services.reduction_engine import ReductionEngine

router = APIRouter(prefix="/progress", tags=["Progress & Gamification"])

DEFAULT_ACHIEVEMENTS = [
    {"code": "first_delay", "title": "First Delay Victory", "description": "Delayed a cigarette craving for 10 minutes.", "icon": "shield-check"},
    {"code": "10_delays", "title": "Crest Rider", "description": "Successfully rode through 10 craving peaks.", "icon": "waves"},
    {"code": "below_baseline", "title": "Under the Baseline", "description": "Kept your daily count below baseline for 3 consecutive days.", "icon": "trending-down"},
    {"code": "50_avoided", "title": "50 Smokes Avoided", "description": "Spared your body 50 cigarettes from your baseline.", "icon": "heart-pulse"},
    {"code": "money_saver", "title": "Pocket Guardian", "description": "Saved substantial money through mindful reduction.", "icon": "piggy-bank"}
]

@router.get("/summary", response_model=ProgressSummaryResponse)
def get_progress_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    baseline = profile.baseline_cigs_per_day if profile else 15
    currency = current_user.settings.currency_symbol if current_user.settings else "₹"
    delay_cap = profile.current_delay_capacity_mins if profile else 10
    
    # 7-day average
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
    recent_logs = db.query(SmokingLog).filter(
        SmokingLog.user_id == current_user.id,
        SmokingLog.logged_at >= seven_days_ago
    ).all()
    
    total_7d_cigs = sum(l.count for l in recent_logs)
    avg_7d = round(total_7d_cigs / 7.0, 1)
    
    reduction_pct = round(((baseline - avg_7d) / baseline) * 100, 1) if baseline > 0 else 0.0
    if avg_7d > baseline:
        reduction_pct = 0.0
        
    # All-time cravings & delays
    all_cravings = db.query(CravingEvent).filter(
        CravingEvent.user_id == current_user.id
    ).all()
    
    total_cravings = len(all_cravings)
    successful_delays = sum(1 for c in all_cravings if c.status == "delayed_success")
    
    # All-time cigarettes avoided
    all_targets = db.query(DailyTarget).filter(
        DailyTarget.user_id == current_user.id
    ).all()
    
    total_avoided = 0
    consecutive_maintained = 0
    sorted_targets = sorted(all_targets, key=lambda x: x.target_date, reverse=True)
    
    counting_streak = True
    for t in sorted_targets:
        avoided_day = max(0, baseline - t.actual_cigs)
        total_avoided += avoided_day
        if counting_streak:
            if t.actual_cigs <= t.target_cigs:
                consecutive_maintained += 1
            else:
                counting_streak = False
                
    money_saved = ReductionEngine.calculate_savings(profile, total_avoided)
    
    return ProgressSummaryResponse(
        baseline_cigs_per_day=baseline,
        current_7day_average=avg_7d,
        reduction_percentage=reduction_pct,
        total_cigarettes_avoided=total_avoided,
        total_cravings_logged=total_cravings,
        total_successful_delays=successful_delays,
        estimated_money_saved=money_saved,
        currency_symbol=currency,
        consecutive_days_with_target_maintained=consecutive_maintained,
        current_delay_capacity_mins=delay_cap
    )

@router.get("/achievements", response_model=List[AchievementItem])
def get_achievements(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Ensure default achievements are seeded
    for item in DEFAULT_ACHIEVEMENTS:
        ach = db.query(Achievement).filter(Achievement.code == item["code"]).first()
        if not ach:
            ach = Achievement(
                code=item["code"],
                title=item["title"],
                description=item["description"],
                icon=item["icon"]
            )
            db.add(ach)
    db.commit()
    
    # Check unlock states
    unlocked = db.query(UserAchievement).filter(
        UserAchievement.user_id == current_user.id
    ).all()
    unlocked_map = {u.achievement.code: u.unlocked_at for u in unlocked if u.achievement}
    
    # Evaluate triggers dynamically
    delays_count = db.query(CravingEvent).filter(
        CravingEvent.user_id == current_user.id,
        CravingEvent.status == "delayed_success"
    ).count()
    
    all_achievements = db.query(Achievement).all()
    result = []
    
    for a in all_achievements:
        is_unlocked = a.code in unlocked_map
        if not is_unlocked:
            if a.code == "first_delay" and delays_count >= 1:
                is_unlocked = True
            elif a.code == "10_delays" and delays_count >= 10:
                is_unlocked = True
                
        result.append(AchievementItem(
            code=a.code,
            title=a.title,
            description=a.description,
            icon=a.icon,
            unlocked=is_unlocked,
            unlocked_at=unlocked_map.get(a.code)
        ))
        
    return result

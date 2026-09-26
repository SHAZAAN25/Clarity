from datetime import datetime, date, timedelta, timezone
from collections import defaultdict
from typing import List, Dict, Any, Optional
from sqlalchemy.orm import Session

from app.models.models import User, UserProfile, SmokingLog, CravingEvent, DailyTarget
from app.schemas.schemas import (
    SmokingClockItem, SmokingClockResponse, 
    TriggerStatItem, TriggerAnalyticsResponse,
    HighRiskWindowResponse, WeeklyReportResponse
)

class AnalyticsService:
    @classmethod
    def get_smoking_clock(cls, db: Session, user: User, days_lookback: int = 14) -> SmokingClockResponse:
        cutoff = datetime.now(timezone.utc) - timedelta(days=days_lookback)
        logs = db.query(SmokingLog).filter(
            SmokingLog.user_id == user.id,
            SmokingLog.logged_at >= cutoff
        ).all()
        
        hour_counts = defaultdict(int)
        total_logged = 0
        for log in logs:
            hour = log.logged_at.hour
            hour_counts[hour] += log.count
            total_logged += log.count
            
        clock_items: List[SmokingClockItem] = []
        peak_hour = None
        max_count = 0
        
        for h in range(24):
            cnt = hour_counts[h]
            pct = round((cnt / total_logged * 100), 1) if total_logged > 0 else 0.0
            if cnt > max_count:
                max_count = cnt
                peak_hour = h
                
            clock_items.append(SmokingClockItem(
                hour=h,
                label=f"{h:02d}:00",
                count=cnt,
                percentage=pct,
                is_high_risk=False
            ))
            
        # Mark high-risk if count is significantly above average
        avg_per_hour = total_logged / 24.0 if total_logged > 0 else 0
        for item in clock_items:
            if item.count > 0 and item.count >= avg_per_hour * 1.5:
                item.is_high_risk = True
                
        peak_label = f"{peak_hour:02d}:00 - {((peak_hour + 1) % 24):02d}:00" if peak_hour is not None else "No data yet"
        
        note = (
            f"Observed pattern: Over the past {days_lookback} days, your most frequent smoking window was around {peak_label}."
            if total_logged > 0 else "Log a few cigarettes to reveal your 24-hour smoking clock."
        )
        
        return SmokingClockResponse(
            clock_data=clock_items,
            peak_hour=peak_hour,
            peak_window_label=peak_label if total_logged > 0 else None,
            observation_note=note
        )

    @classmethod
    def get_trigger_analytics(cls, db: Session, user: User) -> TriggerAnalyticsResponse:
        logs = db.query(SmokingLog).filter(
            SmokingLog.user_id == user.id,
            SmokingLog.trigger != None
        ).all()
        
        cravings = db.query(CravingEvent).filter(
            CravingEvent.user_id == user.id,
            CravingEvent.trigger != None
        ).all()
        
        counts = defaultdict(int)
        total = 0
        for l in logs:
            if l.trigger:
                counts[l.trigger] += 1
                total += 1
        for c in cravings:
            if c.trigger:
                counts[c.trigger] += 1
                total += 1
                
        top_list: List[TriggerStatItem] = []
        for trigger_name, cnt in sorted(counts.items(), key=lambda x: x[1], reverse=True):
            pct = round((cnt / total * 100), 1) if total > 0 else 0.0
            top_list.append(TriggerStatItem(
                trigger=trigger_name,
                count=cnt,
                percentage=pct
            ))
            
        if top_list:
            primary_obs = f"Most of your logged cigarettes and cravings occurred during or right after '{top_list[0].trigger}'."
        else:
            primary_obs = "No trigger data logged yet. Next time you smoke or feel a craving, select an optional trigger."
            
        caveat = "Note: Triggers describe observed circumstances when cravings occur; they do not imply sole medical causality."
        
        return TriggerAnalyticsResponse(
            top_triggers=top_list[:8],
            primary_observation=primary_obs,
            caveat_note=caveat
        )

    @classmethod
    def get_high_risk_windows(cls, db: Session, user: User) -> HighRiskWindowResponse:
        clock_resp = cls.get_smoking_clock(db, user)
        high_risk_items = [item for item in clock_resp.clock_data if item.is_high_risk]
        
        windows = []
        for h in high_risk_items:
            windows.append({
                "window": f"{h.hour:02d}:00 - {((h.hour + 1) % 24):02d}:00",
                "frequency_count": h.count,
                "percentage_of_daily": h.percentage
            })
            
        recommendation = (
            f"Your strongest smoking window is {clock_resp.peak_window_label}. "
            "Preparing a glass of water, mints, or a 5-minute distraction activity before this window can help you delay the first cigarette."
            if windows else "Continue logging your normal routine to map high-risk windows."
        )
        
        return HighRiskWindowResponse(
            detected_windows=windows,
            recommendation=recommendation
        )

    @classmethod
    def generate_weekly_report(cls, db: Session, user: User) -> WeeklyReportResponse:
        profile: UserProfile = user.profile
        baseline = profile.baseline_cigs_per_day if profile else 15
        
        today = date.today()
        week_start = today - timedelta(days=7)
        
        logs = db.query(SmokingLog).filter(
            SmokingLog.user_id == user.id,
            SmokingLog.logged_at >= datetime.combine(week_start, datetime.min.time())
        ).all()
        
        total_cigs = sum(l.count for l in logs)
        avg_cigs = round(total_cigs / 7.0, 1)
        
        change_pct = round(((avg_cigs - baseline) / baseline) * 100, 1) if baseline > 0 else 0.0
        
        # Successful delays
        delays = db.query(CravingEvent).filter(
            CravingEvent.user_id == user.id,
            CravingEvent.created_at >= datetime.combine(week_start, datetime.min.time()),
            CravingEvent.status == "delayed_success"
        ).count()
        
        trigger_resp = cls.get_trigger_analytics(db, user)
        top_trigger = trigger_resp.top_triggers[0].trigger if trigger_resp.top_triggers else "Habit"
        
        clock_resp = cls.get_smoking_clock(db, user, days_lookback=7)
        peak_period = clock_resp.peak_window_label or "Varied"
        
        obs = (
            f"Over the last 7 days, you averaged {avg_cigs} cigarettes/day (Baseline: {baseline}). "
            f"You successfully completed {delays} craving delays. "
            f"Your most frequent circumstance was '{top_trigger}', especially around {peak_period}."
        )
        
        disclaimer = "This report summarizes observed behaviors to support your self-awareness; it is not a clinical diagnosis or guarantee of future cessation."
        
        return WeeklyReportResponse(
            week_start=week_start.isoformat(),
            week_end=today.isoformat(),
            average_cigs_per_day=avg_cigs,
            baseline_cigs_per_day=baseline,
            change_percentage=change_pct,
            successful_delays=delays,
            most_common_trigger=top_trigger,
            highest_risk_period=peak_period,
            ai_observation=obs,
            disclaimer=disclaimer
        )

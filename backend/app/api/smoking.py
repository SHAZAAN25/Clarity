from datetime import datetime, date, timedelta, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.core.database import get_db, utc_now
from app.core.deps import get_current_user
from app.models.models import User, SmokingLog, DailyTarget, CravingEvent
from app.schemas.schemas import SmokingLogCreate, SmokingLogResponse, SmokingTodayResponse
from app.services.reduction_engine import ReductionEngine
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/smoking", tags=["Smoking Tracker"])

@router.post("/log", response_model=SmokingLogResponse, status_code=status.HTTP_201_CREATED)
def log_cigarette(
    payload: SmokingLogCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    log_time = payload.logged_at if payload.logged_at else utc_now()
    if log_time.tzinfo is not None:
        log_time = log_time.replace(tzinfo=None)
    
    log = SmokingLog(
        user_id=current_user.id,
        logged_at=log_time,
        count=payload.count,
        trigger=payload.trigger,
        mood=payload.mood,
        location=payload.location,
        craving_intensity=payload.craving_intensity,
        notes=payload.notes,
        is_quick_log=payload.is_quick_log,
        craving_event_id=payload.craving_event_id
    )
    db.add(log)
    db.commit()
    db.refresh(log)
    
    # Sync today's target
    target = ReductionEngine.get_or_create_daily_target(db, current_user, log_time.strftime("%Y-%m-%d"))
    ReductionEngine.sync_actual_count(db, target)
    
    return log

@router.get("/today", response_model=SmokingTodayResponse)
def get_today_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    now = utc_now()
    today_dt = now.date()
    today_str = today_dt.isoformat()
    start_of_day = datetime.combine(today_dt, datetime.min.time())
    
    # Get or create target
    target = ReductionEngine.get_or_create_daily_target(db, current_user, today_str)
    
    # Get today's logs
    logs = db.query(SmokingLog).filter(
        SmokingLog.user_id == current_user.id,
        SmokingLog.logged_at >= start_of_day
    ).order_by(SmokingLog.logged_at.desc()).all()
    
    total_cigs = sum(l.count for l in logs)
    
    # Last cigarette
    last_log = logs[0] if logs else None
    mins_ago = None
    if last_log:
        diff = now - last_log.logged_at
        mins_ago = max(0, int(diff.total_seconds() / 60))
        
    # Baseline & avoided
    profile = current_user.profile
    baseline = profile.baseline_cigs_per_day if profile else 15
    avoided = max(0, baseline - total_cigs)
    
    # Successful delays today
    delays_today = db.query(CravingEvent).filter(
        CravingEvent.user_id == current_user.id,
        CravingEvent.created_at >= start_of_day,
        CravingEvent.status == "delayed_success"
    ).count()
    
    # Money saved
    currency = current_user.settings.currency_symbol if current_user.settings else "₹"
    money_saved = ReductionEngine.calculate_savings(profile, avoided)
    
    # Status
    if total_cigs > target.target_cigs:
        status_flag = "exceeded"
    elif total_cigs >= target.target_cigs:
        status_flag = "caution"
    else:
        status_flag = "on_track"
        
    # Next high risk window
    clock_resp = AnalyticsService.get_smoking_clock(db, current_user)
    next_window = clock_resp.peak_window_label
    
    return SmokingTodayResponse(
        today_date=today_str,
        total_cigarettes=total_cigs,
        target_cigarettes=target.target_cigs,
        last_cigarette_logged_at=last_log.logged_at if last_log else None,
        minutes_since_last_cigarette=mins_ago,
        cigarettes_avoided=avoided,
        successful_delays=delays_today,
        money_saved_today=money_saved,
        currency_symbol=currency,
        status=status_flag,
        next_high_risk_window=next_window
    )

@router.get("/history", response_model=List[SmokingLogResponse])
def get_smoking_history(
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    logs = db.query(SmokingLog).filter(
        SmokingLog.user_id == current_user.id
    ).order_by(SmokingLog.logged_at.desc()).offset(offset).limit(limit).all()
    return logs

@router.delete("/log/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_smoking_log(
    log_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    log = db.query(SmokingLog).filter(
        SmokingLog.id == log_id,
        SmokingLog.user_id == current_user.id
    ).first()
    if not log:
        raise HTTPException(status_code=404, detail="Log entry not found")
        
    log_date_str = log.logged_at.strftime("%Y-%m-%d")
    db.delete(log)
    db.commit()
    
    # Resync target
    target = db.query(DailyTarget).filter(
        DailyTarget.user_id == current_user.id,
        DailyTarget.target_date == log_date_str
    ).first()
    if target:
        ReductionEngine.sync_actual_count(db, target)
        
    return None

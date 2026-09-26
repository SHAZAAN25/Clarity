from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db, utc_now
from app.core.deps import get_current_user
from app.models.models import User, UserSettings, SmokingLog, CravingEvent, DailyTarget, ProgressSnapshot
from app.schemas.schemas import UserSettingsResponse, UserSettingsUpdate, AccountExportData

router = APIRouter(prefix="/settings", tags=["Settings & Privacy"])

@router.get("", response_model=UserSettingsResponse)
def get_user_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    settings = current_user.settings
    if not settings:
        settings = UserSettings(user_id=current_user.id)
        db.add(settings)
        db.commit()
        db.refresh(settings)
    return settings

@router.patch("", response_model=UserSettingsResponse)
def update_user_settings(
    payload: UserSettingsUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    settings = current_user.settings
    if not settings:
        settings = UserSettings(user_id=current_user.id)
        db.add(settings)
        
    for k, v in payload.dict(exclude_unset=True).items():
        setattr(settings, k, v)
        
    db.commit()
    db.refresh(settings)
    return settings

@router.get("/export-data", response_model=AccountExportData)
def export_user_data(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    logs = db.query(SmokingLog).filter(SmokingLog.user_id == current_user.id).all()
    cravings = db.query(CravingEvent).filter(CravingEvent.user_id == current_user.id).all()
    targets = db.query(DailyTarget).filter(DailyTarget.user_id == current_user.id).all()
    snapshots = db.query(ProgressSnapshot).filter(ProgressSnapshot.user_id == current_user.id).all()
    
    return AccountExportData(
        user_info={
            "id": current_user.id,
            "email": current_user.email,
            "created_at": current_user.created_at.isoformat()
        },
        profile={
            "baseline_cigs_per_day": profile.baseline_cigs_per_day if profile else 0,
            "goal": profile.goal if profile else "reduce",
            "cost_per_pack": profile.cost_per_pack if profile else 0,
            "delay_capacity_mins": profile.current_delay_capacity_mins if profile else 10
        },
        smoking_logs=[
            {"id": l.id, "logged_at": l.logged_at.isoformat(), "count": l.count, "trigger": l.trigger, "mood": l.mood}
            for l in logs
        ],
        craving_events=[
            {"id": c.id, "created_at": c.created_at.isoformat(), "intensity": c.intensity, "status": c.status, "delayed_seconds": c.actual_delayed_seconds}
            for c in cravings
        ],
        daily_targets=[
            {"date": t.target_date, "target": t.target_cigs, "actual": t.actual_cigs, "status": t.status}
            for t in targets
        ],
        progress_snapshots=[
            {"date": s.snapshot_date, "avoided": s.cigarettes_avoided, "money_saved": s.estimated_money_saved}
            for s in snapshots
        ],
        export_generated_at=utc_now().isoformat()
    )

@router.delete("/account", status_code=status.HTTP_204_NO_CONTENT)
def delete_account(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Cascades all logs, profile, settings, AI history via relationship cascade
    db.delete(current_user)
    db.commit()
    return None

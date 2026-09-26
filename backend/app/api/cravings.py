from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db, utc_now
from app.core.deps import get_current_user
from app.models.models import User, CravingEvent, CravingIntervention, SmokingLog
from app.schemas.schemas import (
    CravingStartRequest, CravingInterventionRequest, 
    CravingCompleteRequest, CravingResponse
)
from app.services.reduction_engine import ReductionEngine

router = APIRouter(prefix="/cravings", tags=["Craving Intervention"])

@router.post("/start", response_model=CravingResponse, status_code=status.HTTP_201_CREATED)
def start_craving_session(
    payload: CravingStartRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    suggested_mins = profile.current_delay_capacity_mins if profile else 10
    
    event = CravingEvent(
        user_id=current_user.id,
        intensity=payload.intensity,
        trigger=payload.trigger,
        mood=payload.mood,
        suggested_delay_mins=suggested_mins,
        status="in_progress"
    )
    db.add(event)
    db.commit()
    db.refresh(event)
    return event

@router.post("/{craving_id}/intervention", status_code=status.HTTP_201_CREATED)
def record_intervention(
    craving_id: str,
    payload: CravingInterventionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    event = db.query(CravingEvent).filter(
        CravingEvent.id == craving_id,
        CravingEvent.user_id == current_user.id
    ).first()
    if not event:
        raise HTTPException(status_code=404, detail="Craving session not found")
        
    intervention = CravingIntervention(
        craving_event_id=event.id,
        intervention_type=payload.intervention_type,
        duration_seconds=payload.duration_seconds,
        was_helpful=payload.was_helpful
    )
    db.add(intervention)
    db.commit()
    return {"message": "Intervention recorded", "intervention_type": payload.intervention_type}

@router.post("/{craving_id}/complete", response_model=CravingResponse)
def complete_craving_session(
    craving_id: str,
    payload: CravingCompleteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    event = db.query(CravingEvent).filter(
        CravingEvent.id == craving_id,
        CravingEvent.user_id == current_user.id
    ).first()
    if not event:
        raise HTTPException(status_code=404, detail="Craving session not found")
        
    event.completed_at = utc_now()
    event.did_smoke = payload.did_smoke
    event.post_feeling = payload.post_feeling
    event.actual_delayed_seconds = payload.actual_delayed_seconds
    
    if payload.did_smoke:
        event.status = "smoked"
        # Record the cigarette log with linking
        cig_log = SmokingLog(
            user_id=current_user.id,
            logged_at=utc_now(),
            count=1,
            trigger=payload.trigger or event.trigger,
            craving_intensity=event.intensity,
            notes="Logged following craving intervention delay attempt.",
            is_quick_log=False,
            craving_event_id=event.id
        )
        db.add(cig_log)
        
        # Non-punitive delay capacity adjustment
        ReductionEngine.update_delay_capacity(db, current_user, did_succeed=False)
    else:
        event.status = "delayed_success"
        # Positive delay adaptation
        ReductionEngine.update_delay_capacity(db, current_user, did_succeed=True)
        
    db.commit()
    db.refresh(event)
    return event

@router.get("/history", response_model=List[CravingResponse])
def get_craving_history(
    limit: int = 30,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    cravings = db.query(CravingEvent).filter(
        CravingEvent.user_id == current_user.id
    ).order_by(CravingEvent.created_at.desc()).limit(limit).all()
    return cravings

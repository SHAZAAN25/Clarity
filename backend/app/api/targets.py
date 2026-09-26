from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import User, DailyTarget
from app.schemas.schemas import DailyTargetResponse, TargetAdjustRequest, RelapseActionRequest
from app.services.reduction_engine import ReductionEngine

router = APIRouter(prefix="/targets", tags=["Reduction Targets"])

@router.get("/current", response_model=DailyTargetResponse)
def get_current_target(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today_str = date.today().isoformat()
    target = ReductionEngine.get_or_create_daily_target(db, current_user, today_str)
    
    advice = "Your target is a flexible guideline to help build awareness. You can adjust or pause anytime."
    if target.status == "exceeded":
        advice = "You smoked more than planned today. Let's understand what happened—one day does not erase your progress."
    elif target.actual_cigs == 0:
        advice = "Off to a peaceful start today. Focus on one delay at a time."
        
    return DailyTargetResponse(
        target_date=target.target_date,
        target_cigs=target.target_cigs,
        actual_cigs=target.actual_cigs,
        status=target.status,
        user_adjusted=target.user_adjusted,
        relapse_reason=target.relapse_reason,
        relapse_action_taken=target.relapse_action_taken,
        reduction_advice=advice
    )

@router.post("/adjust", response_model=DailyTargetResponse)
def adjust_target(
    payload: TargetAdjustRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today_str = date.today().isoformat()
    target = ReductionEngine.get_or_create_daily_target(db, current_user, today_str)
    
    target.target_cigs = payload.target_cigs
    target.user_adjusted = True
    ReductionEngine.sync_actual_count(db, target)
    db.commit()
    db.refresh(target)
    
    return DailyTargetResponse(
        target_date=target.target_date,
        target_cigs=target.target_cigs,
        actual_cigs=target.actual_cigs,
        status=target.status,
        user_adjusted=target.user_adjusted,
        relapse_reason=target.relapse_reason,
        relapse_action_taken=target.relapse_action_taken,
        reduction_advice="Target adjusted to your preference. You remain in complete control."
    )

@router.post("/relapse-action", response_model=DailyTargetResponse)
def handle_relapse_action(
    payload: RelapseActionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    today_str = date.today().isoformat()
    target = ReductionEngine.get_or_create_daily_target(db, current_user, today_str)
    
    ReductionEngine.handle_relapse(db, target, payload.reason, payload.action)
    db.refresh(target)
    
    return DailyTargetResponse(
        target_date=target.target_date,
        target_cigs=target.target_cigs,
        actual_cigs=target.actual_cigs,
        status=target.status,
        user_adjusted=target.user_adjusted,
        relapse_reason=target.relapse_reason,
        relapse_action_taken=target.relapse_action_taken,
        reduction_advice="Thank you for noting what happened. Relapses provide valuable behavioral insight."
    )

import json
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import User, UserProfile, DailyTarget
from app.schemas.schemas import OnboardingRequest, ProfileResponse, ProfileUpdateRequest
from app.services.reduction_engine import ReductionEngine

router = APIRouter(prefix="/onboarding", tags=["Onboarding"])

@router.post("/complete", response_model=ProfileResponse)
def complete_onboarding(
    payload: OnboardingRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)
        
    profile.baseline_cigs_per_day = payload.baseline_cigs_per_day
    profile.cost_per_pack = payload.cost_per_pack
    profile.cigs_per_pack = payload.cigs_per_pack
    profile.years_smoking = payload.years_smoking
    profile.first_cig_after_waking_mins = payload.first_cig_after_waking_mins
    profile.goal = payload.goal
    profile.motivations = json.dumps(payload.motivations)
    profile.common_triggers = json.dumps(payload.common_triggers)
    profile.onboarding_completed = True
    
    # Baseline period: 3 days observation if user chose "not_sure" or "reduce"
    profile.is_in_baseline_period = True if payload.goal in ["reduce", "not_sure"] else False
    
    db.commit()
    db.refresh(profile)
    
    # Initialize today's target
    ReductionEngine.get_or_create_daily_target(db, current_user, date.today().isoformat())
    
    return ProfileResponse(
        user_id=current_user.id,
        baseline_cigs_per_day=profile.baseline_cigs_per_day,
        cost_per_pack=profile.cost_per_pack,
        cigs_per_pack=profile.cigs_per_pack,
        years_smoking=profile.years_smoking,
        first_cig_after_waking_mins=profile.first_cig_after_waking_mins,
        goal=profile.goal,
        is_in_baseline_period=profile.is_in_baseline_period,
        current_delay_capacity_mins=profile.current_delay_capacity_mins,
        motivations=payload.motivations,
        common_triggers=payload.common_triggers,
        onboarding_completed=profile.onboarding_completed
    )

@router.get("/profile", response_model=ProfileResponse)
def get_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    if not profile:
        profile = UserProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        db.refresh(profile)
        
    motivations = []
    triggers = []
    try:
        motivations = json.loads(profile.motivations) if profile.motivations else []
        triggers = json.loads(profile.common_triggers) if profile.common_triggers else []
    except Exception:
        pass
        
    return ProfileResponse(
        user_id=current_user.id,
        baseline_cigs_per_day=profile.baseline_cigs_per_day,
        cost_per_pack=profile.cost_per_pack,
        cigs_per_pack=profile.cigs_per_pack,
        years_smoking=profile.years_smoking,
        first_cig_after_waking_mins=profile.first_cig_after_waking_mins,
        goal=profile.goal,
        is_in_baseline_period=profile.is_in_baseline_period,
        current_delay_capacity_mins=profile.current_delay_capacity_mins,
        motivations=motivations,
        common_triggers=triggers,
        onboarding_completed=profile.onboarding_completed
    )

@router.patch("/profile", response_model=ProfileResponse)
def update_profile(
    payload: ProfileUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
        
    if payload.goal is not None:
        profile.goal = payload.goal
    if payload.cost_per_pack is not None:
        profile.cost_per_pack = payload.cost_per_pack
    if payload.cigs_per_pack is not None:
        profile.cigs_per_pack = payload.cigs_per_pack
    if payload.first_cig_after_waking_mins is not None:
        profile.first_cig_after_waking_mins = payload.first_cig_after_waking_mins
    if payload.motivations is not None:
        profile.motivations = json.dumps(payload.motivations)
    if payload.common_triggers is not None:
        profile.common_triggers = json.dumps(payload.common_triggers)
    if payload.is_in_baseline_period is not None:
        profile.is_in_baseline_period = payload.is_in_baseline_period
        
    db.commit()
    db.refresh(profile)
    return get_profile(db, current_user)

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import User
from app.schemas.schemas import (
    SmokingClockResponse, TriggerAnalyticsResponse,
    HighRiskWindowResponse, WeeklyReportResponse
)
from app.services.analytics_service import AnalyticsService

router = APIRouter(prefix="/analytics", tags=["Behavioral Analytics"])

@router.get("/smoking-clock", response_model=SmokingClockResponse)
def get_smoking_clock(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return AnalyticsService.get_smoking_clock(db, current_user)

@router.get("/triggers", response_model=TriggerAnalyticsResponse)
def get_trigger_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return AnalyticsService.get_trigger_analytics(db, current_user)

@router.get("/high-risk-windows", response_model=HighRiskWindowResponse)
def get_high_risk_windows(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return AnalyticsService.get_high_risk_windows(db, current_user)

@router.get("/weekly-report", response_model=WeeklyReportResponse)
def get_weekly_report(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return AnalyticsService.generate_weekly_report(db, current_user)

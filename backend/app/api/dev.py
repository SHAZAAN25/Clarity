from datetime import datetime, date, timedelta, timezone
import random
from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.database import get_db, utc_now
from app.core.config import settings
from app.core.deps import get_current_user
from app.models.models import User, SmokingLog, CravingEvent, DailyTarget, RAGDocument
from app.services.rag_service import RAGService
from app.services.reduction_engine import ReductionEngine

router = APIRouter(prefix="/dev", tags=["Developer & Health Diagnostics"])

@router.get("/health")
def system_health(db: Session = Depends(get_db)):
    db_ok = True
    try:
        db.execute(text("SELECT 1"))
    except Exception as e:
        db_ok = False
        
    rag_doc_count = db.query(RAGDocument).count()
    
    return {
        "status": "healthy" if db_ok else "degraded",
        "app_name": settings.APP_NAME,
        "database_connected": db_ok,
        "database_url": settings.DATABASE_URL.split("@")[-1] if "@" in settings.DATABASE_URL else "local_sqlite",
        "llm_provider": settings.LLM_PROVIDER,
        "rag_documents_indexed": rag_doc_count,
        "timestamp": utc_now().isoformat()
    }

@router.post("/seed-sample-data")
def seed_sample_data(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    profile = current_user.profile
    if profile:
        profile.baseline_cigs_per_day = 18
        profile.cost_per_pack = 18.0
        profile.onboarding_completed = True
        
    triggers = ["Stress", "Coffee", "After meal", "Work", "Boredom", "Social"]
    today = date.today()
    
    # Clean previous demo logs
    db.query(SmokingLog).filter(SmokingLog.user_id == current_user.id).delete()
    db.query(CravingEvent).filter(CravingEvent.user_id == current_user.id).delete()
    db.query(DailyTarget).filter(DailyTarget.user_id == current_user.id).delete()
    
    typical_hours = [8, 10, 13, 15, 19, 20, 21, 22]
    
    for day_offset in range(6, -1, -1):
        target_day = today - timedelta(days=day_offset)
        target_day_str = target_day.isoformat()
        
        target_count = max(13, 18 - (6 - day_offset))
        actual_count = target_count - (1 if day_offset <= 2 else 0)
        
        target_record = DailyTarget(
            user_id=current_user.id,
            target_date=target_day_str,
            target_cigs=target_count,
            actual_cigs=actual_count,
            status="met" if actual_count <= target_count else "active"
        )
        db.add(target_record)
        
        for i in range(actual_count):
            hour = typical_hours[i % len(typical_hours)]
            minute = random.randint(5, 55)
            log_time = datetime.combine(target_day, datetime.min.time()).replace(
                hour=hour, minute=minute
            )
            trigger_chosen = triggers[i % len(triggers)]
            
            db.add(SmokingLog(
                user_id=current_user.id,
                logged_at=log_time,
                count=1,
                trigger=trigger_chosen,
                mood="Tense" if trigger_chosen == "Stress" else "Neutral",
                craving_intensity=random.randint(1, 4),
                is_quick_log=True
            ))
            
        for _ in range(random.randint(1, 2)):
            db.add(CravingEvent(
                user_id=current_user.id,
                created_at=datetime.combine(target_day, datetime.min.time()).replace(
                    hour=random.choice([11, 16, 20]), minute=random.randint(0, 50)
                ),
                intensity=random.randint(2, 4),
                trigger=random.choice(triggers),
                suggested_delay_mins=10,
                status="delayed_success",
                post_feeling="weaker",
                did_smoke=False,
                actual_delayed_seconds=600
            ))
            
    db.commit()
    return {"message": "Sample historical data seeded successfully for 7 days."}

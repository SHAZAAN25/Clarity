from datetime import datetime, time, timezone
from typing import Optional, List
from sqlalchemy.orm import Session

from app.models.models import User, UserSettings, Notification
from app.core.database import utc_now

class NotificationService:
    @classmethod
    def can_send_notification(cls, db: Session, user: User, notif_type: str) -> bool:
        settings: UserSettings = user.settings
        if not settings or not settings.notifications_enabled:
            return False
            
        if notif_type == "high_risk_window" and not settings.high_risk_window_alerts:
            return False
        if notif_type == "craving_reminder" and not settings.craving_reminders:
            return False
        if notif_type == "reflection_reminder" and not settings.daily_reflection_reminders:
            return False
            
        # Check quiet hours
        now_time = datetime.now().time()
        try:
            q_start = datetime.strptime(settings.quiet_hours_start, "%H:%M").time()
            q_end = datetime.strptime(settings.quiet_hours_end, "%H:%M").time()
            if q_start < q_end:
                if q_start <= now_time <= q_end:
                    return False
            else: # Overnight quiet hours, e.g. 22:00 to 08:00
                if now_time >= q_start or now_time <= q_end:
                    return False
        except Exception:
            pass
            
        # Check daily frequency limit
        today_start = datetime.combine(datetime.now().date(), datetime.min.time())
        sent_today = db.query(Notification).filter(
            Notification.user_id == user.id,
            Notification.sent_at >= today_start
        ).count()
        
        if sent_today >= settings.max_notifications_per_day:
            return False
            
        return True

    @classmethod
    def create_notification(
        cls, 
        db: Session, 
        user: User, 
        notif_type: str, 
        title: str, 
        body: str
    ) -> Optional[Notification]:
        if not cls.can_send_notification(db, user, notif_type):
            return None
            
        notif = Notification(
            user_id=user.id,
            type=notif_type,
            title=title,
            body=body,
            sent_at=utc_now()
        )
        db.add(notif)
        db.commit()
        db.refresh(notif)
        return notif

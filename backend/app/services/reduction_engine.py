from datetime import datetime, date, timedelta
from typing import Dict, Any, Tuple, Optional
from sqlalchemy.orm import Session

from app.models.models import User, UserProfile, DailyTarget, SmokingLog, CravingEvent
from app.core.database import utc_now

class ReductionEngine:
    """
    Adaptive engine for generating realistic, non-punitive daily reduction targets,
    evaluating adherence, updating delay capacities, and calculating money saved.
    """

    @classmethod
    def get_or_create_daily_target(cls, db: Session, user: User, target_date_str: Optional[str] = None) -> DailyTarget:
        if not target_date_str:
            target_date_str = date.today().isoformat()
            
        target = db.query(DailyTarget).filter(
            DailyTarget.user_id == user.id,
            DailyTarget.target_date == target_date_str
        ).first()
        
        if target:
            cls.sync_actual_count(db, target)
            return target
            
        # Generate new adaptive target
        profile: UserProfile = user.profile
        baseline = profile.baseline_cigs_per_day if profile else 15
        goal = profile.goal if profile else "reduce"
        
        # Check previous target
        prev_target = db.query(DailyTarget).filter(
            DailyTarget.user_id == user.id,
            DailyTarget.target_date < target_date_str
        ).order_by(DailyTarget.target_date.desc()).first()
        
        if not prev_target:
            # First day: start with baseline or baseline - 1 depending on goal
            new_target_cigs = baseline if (goal == "not_sure" or profile.is_in_baseline_period) else max(1, baseline - 1)
        else:
            new_target_cigs = cls._calculate_next_target(db, user, prev_target)
            
        target = DailyTarget(
            user_id=user.id,
            target_date=target_date_str,
            target_cigs=new_target_cigs,
            actual_cigs=0,
            status="active"
        )
        db.add(target)
        db.commit()
        db.refresh(target)
        cls.sync_actual_count(db, target)
        return target

    @classmethod
    def sync_actual_count(cls, db: Session, target: DailyTarget):
        """Update actual cigarettes logged on target date and update status"""
        try:
            target_dt = datetime.strptime(target.target_date, "%Y-%m-%d").date()
        except ValueError:
            target_dt = date.today()
            
        start_of_day = datetime.combine(target_dt, datetime.min.time())
        end_of_day = datetime.combine(target_dt, datetime.max.time())
        
        logs = db.query(SmokingLog).filter(
            SmokingLog.user_id == target.user_id,
            SmokingLog.logged_at >= start_of_day,
            SmokingLog.logged_at <= end_of_day
        ).all()
        
        total = sum(log.count for log in logs)
        target.actual_cigs = total
        
        if total > target.target_cigs:
            target.status = "exceeded"
        elif target_dt < date.today() and total <= target.target_cigs:
            target.status = "met"
        else:
            target.status = "active"
            
        db.commit()

    @classmethod
    def _calculate_next_target(cls, db: Session, user: User, prev_target: DailyTarget) -> int:
        profile: UserProfile = user.profile
        if not profile:
            return prev_target.target_cigs
            
        # If user paused reduction, maintain previous
        if prev_target.status == "paused" or profile.is_in_baseline_period:
            return prev_target.target_cigs
            
        # Review recent 3 days performance
        recent_targets = db.query(DailyTarget).filter(
            DailyTarget.user_id == user.id,
            DailyTarget.target_date <= prev_target.target_date
        ).order_by(DailyTarget.target_date.desc()).limit(3).all()
        
        all_met = all(t.actual_cigs <= t.target_cigs for t in recent_targets) and len(recent_targets) >= 2
        any_exceeded = any(t.actual_cigs > t.target_cigs for t in recent_targets)
        
        if all_met and prev_target.target_cigs > 1:
            # Gradual step down: reduce by 1
            return max(1, prev_target.target_cigs - 1)
        elif any_exceeded:
            # Maintain to allow stabilization without punitive increases
            return prev_target.target_cigs
            
        return prev_target.target_cigs

    @classmethod
    def update_delay_capacity(cls, db: Session, user: User, did_succeed: bool):
        """
        Adapts delay capability (10 -> 15 -> 20 mins) after 3 consecutive successes.
        If struggling, avoids punishing the user with steeper requirements.
        """
        profile: UserProfile = user.profile
        if not profile:
            return
            
        if did_succeed:
            profile.consecutive_delays_succeeded += 1
            if profile.consecutive_delays_succeeded >= 3:
                # Level up delay capacity
                if profile.current_delay_capacity_mins == 10:
                    profile.current_delay_capacity_mins = 15
                elif profile.current_delay_capacity_mins == 15:
                    profile.current_delay_capacity_mins = 20
                profile.consecutive_delays_succeeded = 0
        else:
            # Reset streak without shame, maintain current capacity or ease if high
            profile.consecutive_delays_succeeded = 0
            if profile.current_delay_capacity_mins > 10:
                profile.current_delay_capacity_mins -= 5
                
        db.commit()

    @classmethod
    def handle_relapse(cls, db: Session, target: DailyTarget, reason: str, action: str):
        """
        Treats exceeding a target as valuable behavioral data.
        action: 'maintain', 'adjust_plus_1', or 'pause'
        """
        target.relapse_reason = reason
        target.relapse_action_taken = action
        
        if action == "adjust_plus_1":
            target.target_cigs += 1
            target.user_adjusted = True
        elif action == "pause":
            target.status = "paused"
            
        db.commit()

    @classmethod
    def calculate_savings(cls, profile: Optional[UserProfile], avoided_cigs: int) -> float:
        """
        Calculates estimated money saved based on pack cost.
        """
        if not profile or profile.cigs_per_pack <= 0:
            return round(avoided_cigs * 0.75, 2)
            
        cost_per_cig = profile.cost_per_pack / profile.cigs_per_pack
        return round(avoided_cigs * cost_per_cig, 2)

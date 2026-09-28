import json
from datetime import datetime, date
from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session

from app.models.models import User, UserProfile, SmokingLog, CravingEvent, DailyTarget, AIConversation, AIMessage
from app.services.safety_service import SafetyService
from app.services.ai_service import AIService
from app.schemas.schemas import ChatMessageResponse, SourceCitation
from app.core.database import utc_now

class CoachService:
    @classmethod
    def get_or_create_conversation(cls, db: Session, user_id: str, conversation_id: Optional[str] = None) -> AIConversation:
        if conversation_id:
            conv = db.query(AIConversation).filter(
                AIConversation.id == conversation_id,
                AIConversation.user_id == user_id
            ).first()
            if conv:
                return conv
                
        # Look for most recent conversation or create one
        conv = db.query(AIConversation).filter(
            AIConversation.user_id == user_id
        ).order_by(AIConversation.updated_at.desc()).first()
        
        if not conv:
            conv = AIConversation(
                user_id=user_id,
                title="Cessation Coaching"
            )
            db.add(conv)
            db.commit()
            db.refresh(conv)
            
        return conv

    @classmethod
    def build_structured_context(cls, db: Session, user: User) -> str:
        """
        Builds the minimal necessary user context for the coach.
        Avoids sending raw personal identifiable dumps.
        """
        profile: UserProfile = user.profile
        today_str = date.today().isoformat()
        
        # Today's count
        today_logs = db.query(SmokingLog).filter(
            SmokingLog.user_id == user.id,
            SmokingLog.logged_at >= datetime.combine(date.today(), datetime.min.time())
        ).all()
        today_cigs = sum(log.count for log in today_logs)
        
        # Target
        target_obj = db.query(DailyTarget).filter(
            DailyTarget.user_id == user.id,
            DailyTarget.target_date == today_str
        ).first()
        target_cigs = target_obj.target_cigs if target_obj else (profile.baseline_cigs_per_day if profile else 15)
        
        # Recent delays
        recent_cravings = db.query(CravingEvent).filter(
            CravingEvent.user_id == user.id
        ).order_by(CravingEvent.created_at.desc()).limit(5).all()
        
        successful_delays = sum(1 for c in recent_cravings if c.status == "delayed_success")
        
        baseline = profile.baseline_cigs_per_day if profile else 15
        goal = profile.goal if profile else "reduce"
        delay_cap = profile.current_delay_capacity_mins if profile else 10
        triggers = []
        if profile and profile.common_triggers:
            try:
                triggers = json.loads(profile.common_triggers)
            except Exception:
                pass

        context_lines = [
            f"User Goal: {goal}",
            f"Baseline Consumption: {baseline} cigarettes/day",
            f"Today's Target: {target_cigs} cigarettes",
            f"Smoked Today: {today_cigs} cigarettes",
            f"Current Adaptive Delay Capacity: {delay_cap} minutes",
            f"Recent Craving Delays Succeeded: {successful_delays} of last {len(recent_cravings)}",
            f"Known Common Triggers: {', '.join(triggers) if triggers else 'None noted yet'}"
        ]
        
        return "\n".join(context_lines)

    @classmethod
    async def process_user_message(
        cls, 
        db: Session, 
        user: User, 
        user_message: str, 
        conversation_id: Optional[str] = None
    ) -> ChatMessageResponse:
        conv = cls.get_or_create_conversation(db, user.id, conversation_id)
        
        # 1. Safety check
        is_unsafe, safety_type, safe_reply = SafetyService.evaluate_input(user_message)
        
        # Store user message
        user_msg_record = AIMessage(
            conversation_id=conv.id,
            role="user",
            content=user_message
        )
        db.add(user_msg_record)
        
        if is_unsafe and safe_reply:
            assistant_msg_record = AIMessage(
                conversation_id=conv.id,
                role="assistant",
                content=safe_reply,
                is_safety_diverted=True
            )
            db.add(assistant_msg_record)
            conv.updated_at = utc_now()
            db.commit()
            db.refresh(assistant_msg_record)
            
            return ChatMessageResponse(
                conversation_id=conv.id,
                message_id=assistant_msg_record.id,
                role="assistant",
                content=safe_reply,
                is_safety_diverted=True,
                citations=[],
                suggested_quick_actions=["Consult a doctor", "Back to dashboard"]
            )
            
        # 2. Build structured context
        user_context = cls.build_structured_context(db, user)
        
        system_prompt = (
            "You are Clarity, an empathetic, evidence-based smoking reduction and cessation coach.\n"
            "Core Principles:\n"
            "- NEVER shame the user or use words like 'failed', 'streak lost', 'bad'.\n"
            "- A cigarette is not a failure; it is behavioral data.\n"
            "- Encourage: TRACK -> UNDERSTAND -> DELAY -> REDUCE -> GAIN CONTROL.\n"
            "- Be concise, practical, calm, and supportive (under 120 words).\n"
            "- Do NOT diagnose medical conditions or prescribe medication.\n"
            "- Do NOT say '10 cigarettes are safe' or claim reduction is harmless.\n"
            "- The user's goal may be gradual reduction, not immediate quitting. Support their chosen pace.\n\n"
            f"User Context:\n{user_context}\n"
        )
        
        # Fetch conversation history (last 6 messages)
        past_msgs = db.query(AIMessage).filter(
            AIMessage.conversation_id == conv.id
        ).order_by(AIMessage.created_at.asc()).limit(6).all()
        
        msg_payload = [{"role": m.role, "content": m.content} for m in past_msgs]
        msg_payload.append({"role": "user", "content": user_message})
        
        # Generate AI response
        ai_reply = await AIService.generate_response(system_prompt, msg_payload)
        ai_reply = SafetyService.sanitize_ai_output(ai_reply)
        
        # Determine contextual quick actions
        quick_actions = ["I have a craving", "Log a cigarette", "Check today's target"]
        if "craving" in user_message.lower():
            quick_actions = ["Start 10-min delay", "Try 4-4-4 breathing", "Drink water"]
            
        assistant_msg_record = AIMessage(
            conversation_id=conv.id,
            role="assistant",
            content=ai_reply,
            is_safety_diverted=False
        )
        db.add(assistant_msg_record)
        conv.updated_at = utc_now()
        db.commit()
        db.refresh(assistant_msg_record)
        
        return ChatMessageResponse(
            conversation_id=conv.id,
            message_id=assistant_msg_record.id,
            role="assistant",
            content=ai_reply,
            is_safety_diverted=False,
            citations=[],
            suggested_quick_actions=quick_actions
        )

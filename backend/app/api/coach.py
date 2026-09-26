from typing import List, Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.models.models import User, AIConversation, AIMessage
from app.schemas.schemas import ChatMessageRequest, ChatMessageResponse, ConversationResponse
from app.services.coach_service import CoachService

router = APIRouter(prefix="/coach", tags=["AI Coach"])

@router.post("/message", response_model=ChatMessageResponse)
async def send_coach_message(
    payload: ChatMessageRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    return await CoachService.process_user_message(
        db=db,
        user=current_user,
        user_message=payload.message,
        conversation_id=payload.conversation_id
    )

@router.get("/conversations", response_model=List[ConversationResponse])
def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    convs = db.query(AIConversation).filter(
        AIConversation.user_id == current_user.id
    ).order_by(AIConversation.updated_at.desc()).all()
    return convs

@router.get("/history", response_model=List[ChatMessageResponse])
def get_chat_history(
    conversation_id: Optional[str] = None,
    limit: int = Query(50, ge=1, le=100),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    conv = CoachService.get_or_create_conversation(db, current_user.id, conversation_id)
    messages = db.query(AIMessage).filter(
        AIMessage.conversation_id == conv.id
    ).order_by(AIMessage.created_at.asc()).limit(limit).all()
    
    return [
        ChatMessageResponse(
            conversation_id=conv.id,
            message_id=m.id,
            role=m.role,
            content=m.content,
            is_safety_diverted=m.is_safety_diverted,
            citations=[],
            suggested_quick_actions=["I'm feeling a craving", "Check my progress"] if m.role == "assistant" else []
        )
        for m in messages
    ]

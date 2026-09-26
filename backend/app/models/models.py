from datetime import datetime, timezone
import json
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, 
    ForeignKey, Text, Index
)
from sqlalchemy.orm import relationship
from app.core.database import Base, generate_uuid, utc_now

class User(Base):
    __tablename__ = "users"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)
    
    # Relationships
    profile = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    settings = relationship("UserSettings", back_populates="user", uselist=False, cascade="all, delete-orphan")
    smoking_logs = relationship("SmokingLog", back_populates="user", cascade="all, delete-orphan")
    craving_events = relationship("CravingEvent", back_populates="user", cascade="all, delete-orphan")
    daily_targets = relationship("DailyTarget", back_populates="user", cascade="all, delete-orphan")
    progress_snapshots = relationship("ProgressSnapshot", back_populates="user", cascade="all, delete-orphan")
    ai_conversations = relationship("AIConversation", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    user_achievements = relationship("UserAchievement", back_populates="user", cascade="all, delete-orphan")


class UserProfile(Base):
    __tablename__ = "profiles"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    
    # Baseline smoking info
    baseline_cigs_per_day = Column(Integer, default=15, nullable=False)
    cost_per_pack = Column(Float, default=15.0, nullable=False)  # Local currency
    cigs_per_pack = Column(Integer, default=20, nullable=False)
    years_smoking = Column(Float, default=5.0, nullable=False)
    first_cig_after_waking_mins = Column(Integer, default=30)  # minutes
    
    # Goals: "reduce", "quit_eventually", "quit_asap", "not_sure"
    goal = Column(String(50), default="reduce", nullable=False)
    is_in_baseline_period = Column(Boolean, default=True)
    baseline_days_target = Column(Integer, default=3)
    
    # JSON-encoded array of motivations & triggers
    motivations = Column(Text, default="[]")  # e.g. ["health", "money", "family"]
    common_triggers = Column(Text, default="[]")  # e.g. ["stress", "coffee", "boredom"]
    
    # Adaptive delay capacity (starts at 10 minutes)
    current_delay_capacity_mins = Column(Integer, default=10, nullable=False)
    consecutive_delays_succeeded = Column(Integer, default=0)
    
    onboarding_completed = Column(Boolean, default=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)
    
    user = relationship("User", back_populates="profile")


class UserSettings(Base):
    __tablename__ = "user_settings"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    
    notifications_enabled = Column(Boolean, default=True)
    high_risk_window_alerts = Column(Boolean, default=True)
    craving_reminders = Column(Boolean, default=True)
    daily_reflection_reminders = Column(Boolean, default=True)
    quiet_hours_start = Column(String(5), default="22:00")  # HH:MM
    quiet_hours_end = Column(String(5), default="08:00")    # HH:MM
    max_notifications_per_day = Column(Integer, default=3)
    
    dark_mode = Column(Boolean, default=True)
    reduced_motion = Column(Boolean, default=False)
    currency_symbol = Column(String(10), default="₹")
    
    user = relationship("User", back_populates="settings")


class Trigger(Base):
    __tablename__ = "triggers"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(50), unique=True, nullable=False)
    category = Column(String(50), default="situational")  # emotional, habitual, situational, physical
    icon = Column(String(50), default="sparkles")


class SmokingLog(Base):
    __tablename__ = "smoking_logs"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    
    logged_at = Column(DateTime, default=utc_now, index=True, nullable=False)
    count = Column(Integer, default=1, nullable=False)
    trigger = Column(String(50), nullable=True)  # Stress, Coffee, etc.
    mood = Column(String(50), nullable=True)     # Anxious, Relaxed, Bored, etc.
    location = Column(String(50), nullable=True) # Home, Work, Car, Social
    craving_intensity = Column(Integer, nullable=True)  # 1 to 4
    notes = Column(Text, nullable=True)
    is_quick_log = Column(Boolean, default=True)
    
    # If this log came from a failed delay or craving challenge
    craving_event_id = Column(String(36), nullable=True)
    
    user = relationship("User", back_populates="smoking_logs")

    __table_args__ = (
        Index("idx_user_logged_at", "user_id", "logged_at"),
    )


class CravingEvent(Base):
    __tablename__ = "craving_events"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    
    created_at = Column(DateTime, default=utc_now, index=True, nullable=False)
    intensity = Column(Integer, default=2, nullable=False) # 1: Mild, 2: Moderate, 3: Strong, 4: Very strong
    trigger = Column(String(50), nullable=True)
    mood = Column(String(50), nullable=True)
    
    # Target challenge duration offered
    suggested_delay_mins = Column(Integer, default=10, nullable=False)
    
    # Outcome tracking
    completed_at = Column(DateTime, nullable=True)
    status = Column(String(30), default="in_progress") # in_progress, delayed_success, smoked, cancelled
    post_feeling = Column(String(30), nullable=True) # gone, weaker, same, stronger
    did_smoke = Column(Boolean, nullable=True)
    actual_delayed_seconds = Column(Integer, default=0)
    
    user = relationship("User", back_populates="craving_events")
    interventions = relationship("CravingIntervention", back_populates="craving_event", cascade="all, delete-orphan")


class CravingIntervention(Base):
    __tablename__ = "craving_interventions"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    craving_event_id = Column(String(36), ForeignKey("craving_events.id", ondelete="CASCADE"), nullable=False)
    
    # Types: breathing, water, walk, stretch, distraction, grounding, ai_coach
    intervention_type = Column(String(50), nullable=False)
    started_at = Column(DateTime, default=utc_now, nullable=False)
    duration_seconds = Column(Integer, default=0)
    was_helpful = Column(Boolean, nullable=True)
    
    craving_event = relationship("CravingEvent", back_populates="interventions")


class DailyTarget(Base):
    __tablename__ = "daily_targets"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    
    target_date = Column(String(10), index=True, nullable=False) # YYYY-MM-DD
    target_cigs = Column(Integer, nullable=False)
    actual_cigs = Column(Integer, default=0)
    status = Column(String(30), default="active") # active, met, exceeded, paused
    user_adjusted = Column(Boolean, default=False)
    
    # Relapse review if exceeded
    relapse_reason = Column(String(100), nullable=True)
    relapse_action_taken = Column(String(50), nullable=True) # maintain, adjust_plus_1, pause
    
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)
    
    user = relationship("User", back_populates="daily_targets")

    __table_args__ = (
        Index("idx_user_target_date", "user_id", "target_date"),
    )


class ProgressSnapshot(Base):
    __tablename__ = "progress_snapshots"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    
    snapshot_date = Column(String(10), index=True, nullable=False) # YYYY-MM-DD
    cigarettes_smoked = Column(Integer, default=0)
    cigarettes_avoided = Column(Integer, default=0)
    cravings_logged = Column(Integer, default=0)
    successful_delays = Column(Integer, default=0)
    estimated_money_saved = Column(Float, default=0.0)
    top_trigger = Column(String(50), nullable=True)
    
    created_at = Column(DateTime, default=utc_now, nullable=False)
    
    user = relationship("User", back_populates="progress_snapshots")


class AIConversation(Base):
    __tablename__ = "ai_conversations"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    
    title = Column(String(150), default="Cessation Coaching")
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)
    
    user = relationship("User", back_populates="ai_conversations")
    messages = relationship("AIMessage", back_populates="conversation", cascade="all, delete-orphan", order_by="AIMessage.created_at")


class AIMessage(Base):
    __tablename__ = "ai_messages"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    conversation_id = Column(String(36), ForeignKey("ai_conversations.id", ondelete="CASCADE"), index=True, nullable=False)
    
    role = Column(String(20), nullable=False) # user, assistant, system
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    
    # Metadata for safety flags and RAG citations
    is_safety_diverted = Column(Boolean, default=False)
    citations_json = Column(Text, default="[]")
    
    conversation = relationship("AIConversation", back_populates="messages")


class HealthArticle(Base):
    __tablename__ = "health_articles"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    title = Column(String(200), nullable=False)
    slug = Column(String(200), unique=True, nullable=False)
    category = Column(String(100), default="education") # cravings, withdrawal, nicotine, psychology, health_benefits
    summary = Column(Text, nullable=False)
    content = Column(Text, nullable=False)
    
    author_organization = Column(String(150), default="World Health Organization")
    source_url = Column(String(500), nullable=True)
    published_date = Column(String(50), nullable=True)
    evidence_level = Column(String(50), default="Authoritative Public Health Guidelines")
    
    is_featured = Column(Boolean, default=False)
    reading_time_mins = Column(Integer, default=3)
    created_at = Column(DateTime, default=utc_now, nullable=False)


class RAGDocument(Base):
    __tablename__ = "rag_documents"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    title = Column(String(255), nullable=False)
    source_organization = Column(String(150), nullable=False) # WHO, CDC, NHS
    source_url = Column(String(500), nullable=True)
    document_type = Column(String(50), default="guideline")
    raw_content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    
    chunks = relationship("RAGChunk", back_populates="document", cascade="all, delete-orphan")


class RAGChunk(Base):
    __tablename__ = "rag_chunks"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    document_id = Column(String(36), ForeignKey("rag_documents.id", ondelete="CASCADE"), nullable=False)
    
    chunk_index = Column(Integer, nullable=False)
    chunk_text = Column(Text, nullable=False)
    # Stored as JSON serialized vector for cross-platform zero-dependency RAG embedding retrieval
    embedding_json = Column(Text, nullable=True)
    
    document = relationship("RAGDocument", back_populates="chunks")


class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    
    type = Column(String(50), nullable=False) # high_risk_window, daily_progress, reflection_reminder, achievement
    title = Column(String(150), nullable=False)
    body = Column(Text, nullable=False)
    scheduled_for = Column(DateTime, nullable=True)
    sent_at = Column(DateTime, default=utc_now, nullable=False)
    is_read = Column(Boolean, default=False)
    
    user = relationship("User", back_populates="notifications")


class Achievement(Base):
    __tablename__ = "achievements"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    code = Column(String(50), unique=True, nullable=False) # first_delay, 10_delays, first_week_below_baseline, 50_avoided
    title = Column(String(100), nullable=False)
    description = Column(Text, nullable=False)
    icon = Column(String(50), default="trophy")
    category = Column(String(50), default="milestone")
    threshold_value = Column(Integer, default=1)


class UserAchievement(Base):
    __tablename__ = "user_achievements"
    
    id = Column(String(36), primary_key=True, default=generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    achievement_id = Column(String(36), ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False)
    unlocked_at = Column(DateTime, default=utc_now, nullable=False)
    
    user = relationship("User", back_populates="user_achievements")
    achievement = relationship("Achievement")

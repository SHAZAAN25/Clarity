from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, EmailStr, Field, ConfigDict

# --- Auth Schemas ---
class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    full_name: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    onboarding_completed: bool

class UserResponse(BaseModel):
    id: str
    email: str
    full_name: Optional[str] = None
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- Onboarding & Profile Schemas ---
class OnboardingRequest(BaseModel):
    baseline_cigs_per_day: int = Field(ge=1, le=120)
    cost_per_pack: float = Field(gt=0)
    cigs_per_pack: int = Field(ge=5, le=50, default=20)
    years_smoking: float = Field(ge=0, default=5.0)
    first_cig_after_waking_mins: int = Field(default=30)
    goal: str = Field(default="reduce") # "reduce", "quit_eventually", "quit_asap", "not_sure"
    motivations: List[str] = Field(default_factory=list)
    common_triggers: List[str] = Field(default_factory=list)

class ProfileResponse(BaseModel):
    user_id: str
    baseline_cigs_per_day: int
    cost_per_pack: float
    cigs_per_pack: int
    years_smoking: float
    first_cig_after_waking_mins: int
    goal: str
    is_in_baseline_period: bool
    current_delay_capacity_mins: int
    motivations: List[str]
    common_triggers: List[str]
    onboarding_completed: bool

class ProfileUpdateRequest(BaseModel):
    goal: Optional[str] = None
    cost_per_pack: Optional[float] = None
    cigs_per_pack: Optional[int] = None
    first_cig_after_waking_mins: Optional[int] = None
    motivations: Optional[List[str]] = None
    common_triggers: Optional[List[str]] = None
    is_in_baseline_period: Optional[bool] = None

# --- Smoking Tracker Schemas ---
class SmokingLogCreate(BaseModel):
    logged_at: Optional[datetime] = None
    count: int = Field(ge=1, le=5, default=1)
    trigger: Optional[str] = None
    mood: Optional[str] = None
    location: Optional[str] = None
    craving_intensity: Optional[int] = Field(None, ge=1, le=4)
    notes: Optional[str] = None
    is_quick_log: bool = True
    craving_event_id: Optional[str] = None

class SmokingLogResponse(BaseModel):
    id: str
    user_id: str
    logged_at: datetime
    count: int
    trigger: Optional[str] = None
    mood: Optional[str] = None
    location: Optional[str] = None
    craving_intensity: Optional[int] = None
    notes: Optional[str] = None
    is_quick_log: bool

    model_config = ConfigDict(from_attributes=True)

class SmokingTodayResponse(BaseModel):
    today_date: str
    total_cigarettes: int
    target_cigarettes: int
    last_cigarette_logged_at: Optional[datetime] = None
    minutes_since_last_cigarette: Optional[int] = None
    cigarettes_avoided: int
    successful_delays: int
    money_saved_today: float
    currency_symbol: str
    status: str # "on_track", "caution", "exceeded"
    next_high_risk_window: Optional[str] = None

# --- Craving Schemas ---
class CravingStartRequest(BaseModel):
    intensity: int = Field(ge=1, le=4) # 1: Mild, 2: Moderate, 3: Strong, 4: Very strong
    trigger: Optional[str] = None
    mood: Optional[str] = None

class CravingInterventionRequest(BaseModel):
    intervention_type: str # breathing, water, walk, stretch, distraction, grounding, ai_coach
    duration_seconds: int = 0
    was_helpful: Optional[bool] = None

class CravingCompleteRequest(BaseModel):
    did_smoke: bool
    post_feeling: str # gone, weaker, same, stronger
    actual_delayed_seconds: int
    trigger: Optional[str] = None

class CravingResponse(BaseModel):
    id: str
    user_id: str
    created_at: datetime
    intensity: int
    trigger: Optional[str] = None
    suggested_delay_mins: int
    status: str
    post_feeling: Optional[str] = None
    did_smoke: Optional[bool] = None
    actual_delayed_seconds: int

    model_config = ConfigDict(from_attributes=True)

# --- Targets & Reduction Schemas ---
class DailyTargetResponse(BaseModel):
    target_date: str
    target_cigs: int
    actual_cigs: int
    status: str # active, met, exceeded, paused
    user_adjusted: bool
    relapse_reason: Optional[str] = None
    relapse_action_taken: Optional[str] = None
    reduction_advice: Optional[str] = None

class TargetAdjustRequest(BaseModel):
    target_cigs: int = Field(ge=0, le=100)
    reason: Optional[str] = None

class RelapseActionRequest(BaseModel):
    reason: str
    action: str

# --- Progress & Financial Schemas ---
class ProgressSummaryResponse(BaseModel):
    baseline_cigs_per_day: int
    current_7day_average: float
    reduction_percentage: float
    total_cigarettes_avoided: int
    total_cravings_logged: int
    total_successful_delays: int
    estimated_money_saved: float
    currency_symbol: str
    consecutive_days_with_target_maintained: int
    current_delay_capacity_mins: int

class AchievementItem(BaseModel):
    code: str
    title: str
    description: str
    icon: str
    unlocked: bool
    unlocked_at: Optional[datetime] = None

# --- Analytics Schemas ---
class SmokingClockItem(BaseModel):
    hour: int
    label: str
    count: int
    percentage: float
    is_high_risk: bool

class SmokingClockResponse(BaseModel):
    clock_data: List[SmokingClockItem]
    peak_hour: Optional[int] = None
    peak_window_label: Optional[str] = None
    observation_note: str

class TriggerStatItem(BaseModel):
    trigger: str
    count: int
    percentage: float

class TriggerAnalyticsResponse(BaseModel):
    top_triggers: List[TriggerStatItem]
    primary_observation: str
    caveat_note: str

class HighRiskWindowResponse(BaseModel):
    detected_windows: List[Dict[str, Any]]
    recommendation: str

class WeeklyReportResponse(BaseModel):
    week_start: str
    week_end: str
    average_cigs_per_day: float
    baseline_cigs_per_day: int
    change_percentage: float
    successful_delays: int
    most_common_trigger: str
    highest_risk_period: str
    ai_observation: str
    disclaimer: str

# --- AI Coach Schemas ---
class ChatMessageRequest(BaseModel):
    conversation_id: Optional[str] = None
    message: str

class SourceCitation(BaseModel):
    title: str
    source_organization: str
    source_url: Optional[str] = None
    relevance_summary: str

class ChatMessageResponse(BaseModel):
    conversation_id: str
    message_id: str
    role: str
    content: str
    is_safety_diverted: bool = False
    citations: List[SourceCitation] = Field(default_factory=list)
    suggested_quick_actions: List[str] = Field(default_factory=list)

class ConversationResponse(BaseModel):
    id: str
    title: str
    created_at: datetime
    updated_at: datetime

# --- Health Articles & RAG Schemas ---
class HealthArticleResponse(BaseModel):
    id: str
    title: str
    slug: str
    category: str
    summary: str
    content: str
    author_organization: str
    source_url: Optional[str] = None
    published_date: Optional[str] = None
    evidence_level: str
    reading_time_mins: int

class RAGQueryRequest(BaseModel):
    query: str

class RAGQueryResponse(BaseModel):
    query: str
    answer: str
    citations: List[SourceCitation]
    uncertainty_statement: str
    medical_disclaimer: str

# --- Settings & Privacy Schemas ---
class UserSettingsResponse(BaseModel):
    notifications_enabled: bool
    high_risk_window_alerts: bool
    craving_reminders: bool
    daily_reflection_reminders: bool
    quiet_hours_start: str
    quiet_hours_end: str
    max_notifications_per_day: int
    dark_mode: bool
    reduced_motion: bool
    currency_symbol: str

class UserSettingsUpdate(BaseModel):
    notifications_enabled: Optional[bool] = None
    high_risk_window_alerts: Optional[bool] = None
    craving_reminders: Optional[bool] = None
    daily_reflection_reminders: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    max_notifications_per_day: Optional[int] = None
    dark_mode: Optional[bool] = None
    reduced_motion: Optional[bool] = None
    currency_symbol: Optional[str] = None

class AccountExportData(BaseModel):
    user_info: Dict[str, Any]
    profile: Dict[str, Any]
    smoking_logs: List[Dict[str, Any]]
    craving_events: List[Dict[str, Any]]
    daily_targets: List[Dict[str, Any]]
    progress_snapshots: List[Dict[str, Any]]
    export_generated_at: str

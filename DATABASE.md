# Database Architecture & Schema

Clarity implements a normalized relational database design supporting PostgreSQL in production and SQLite in zero-configuration local development.

---

## 1. Schema Diagram & Tables

### `users`
- `id`: VARCHAR(36) UUID (Primary Key)
- `email`: VARCHAR(255) Unique, Index
- `hashed_password`: VARCHAR(255)
- `full_name`: VARCHAR(100)
- `is_active`: BOOLEAN
- `created_at`, `updated_at`: DATETIME (UTC)

### `profiles`
- `id`: VARCHAR(36) UUID (Primary Key)
- `user_id`: VARCHAR(36) FK -> users.id (CASCADE)
- `baseline_cigs_per_day`: INTEGER
- `cost_per_pack`: FLOAT
- `cigs_per_pack`: INTEGER
- `years_smoking`: FLOAT
- `first_cig_after_waking_mins`: INTEGER
- `goal`: VARCHAR(50) (`reduce`, `quit_eventually`, `quit_asap`, `not_sure`)
- `is_in_baseline_period`: BOOLEAN
- `current_delay_capacity_mins`: INTEGER (Adaptive: 10, 15, 20)
- `consecutive_delays_succeeded`: INTEGER
- `motivations`: TEXT (JSON Array)
- `common_triggers`: TEXT (JSON Array)
- `onboarding_completed`: BOOLEAN

### `smoking_logs`
- `id`: VARCHAR(36) UUID (Primary Key)
- `user_id`: VARCHAR(36) FK -> users.id (CASCADE)
- `logged_at`: DATETIME Index
- `count`: INTEGER (Default 1)
- `trigger`: VARCHAR(50) (Optional: Stress, Coffee, Meal...)
- `mood`: VARCHAR(50)
- `location`: VARCHAR(50)
- `craving_intensity`: INTEGER (1 to 4)
- `is_quick_log`: BOOLEAN
- `craving_event_id`: VARCHAR(36) (Optional link)
- Composite Index: `(user_id, logged_at)`

### `craving_events`
- `id`: VARCHAR(36) UUID (Primary Key)
- `user_id`: VARCHAR(36) FK -> users.id (CASCADE)
- `created_at`: DATETIME Index
- `intensity`: INTEGER (1: Mild, 2: Moderate, 3: Strong, 4: Very Strong)
- `trigger`: VARCHAR(50)
- `suggested_delay_mins`: INTEGER
- `status`: VARCHAR(30) (`in_progress`, `delayed_success`, `smoked`, `cancelled`)
- `post_feeling`: VARCHAR(30) (`gone`, `weaker`, `same`, `stronger`)
- `did_smoke`: BOOLEAN
- `actual_delayed_seconds`: INTEGER

### `craving_interventions`
- `id`: VARCHAR(36) UUID (Primary Key)
- `craving_event_id`: VARCHAR(36) FK -> craving_events.id (CASCADE)
- `intervention_type`: VARCHAR(50) (`breathing`, `water`, `walk`, `stretch`, `grounding`, `ai_coach`)
- `duration_seconds`: INTEGER
- `was_helpful`: BOOLEAN

### `daily_targets`
- `id`: VARCHAR(36) UUID (Primary Key)
- `user_id`: VARCHAR(36) FK -> users.id (CASCADE)
- `target_date`: VARCHAR(10) Index (YYYY-MM-DD)
- `target_cigs`: INTEGER
- `actual_cigs`: INTEGER
- `status`: VARCHAR(30) (`active`, `met`, `exceeded`, `paused`)
- `user_adjusted`: BOOLEAN
- `relapse_reason`: VARCHAR(100)
- `relapse_action_taken`: VARCHAR(50)
- Composite Index: `(user_id, target_date)`

### `ai_conversations` & `ai_messages`
- Manages conversational history with the behavioral coach.
- Stores `is_safety_diverted` flag and `citations_json`.

### `rag_documents` & `rag_chunks`
- Curated evidence from WHO, CDC, NHS, and Cochrane.
- `embedding_json`: Normalized vector representation for cosine similarity retrieval.

### `user_settings`
- Quiet hours configuration (`quiet_hours_start`, `quiet_hours_end`).
- Notification throttles and preferences.

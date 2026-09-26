# API Reference

Base URL: `/api/v1`

## 1. Authentication
- `POST /auth/register` — Register a new user account with hashed password and return JWT access token.
- `POST /auth/login` — Authenticate credentials and return JWT access token.
- `GET /auth/me` — Return current authenticated user profile.

## 2. Onboarding & Baseline
- `POST /onboarding/complete` — Submit initial smoking survey (baseline cigs, cost, wake time, goal, motivations, triggers).
- `GET /onboarding/profile` — Fetch current user smoking profile.
- `PATCH /onboarding/profile` — Update goal, triggers, or baseline observation settings.

## 3. Smoking Tracker
- `POST /smoking/log` — Record a cigarette (under 2 seconds). Takes optional `trigger`, `mood`, `craving_intensity`.
- `GET /smoking/today` — Return today's status: total cigarettes, target, minutes since last cigarette, cigarettes avoided, money saved.
- `GET /smoking/history` — Paginated list of recent cigarette logs.
- `DELETE /smoking/log/{id}` — Delete a mistakenly logged cigarette.

## 4. Craving Intervention
- `POST /cravings/start` — Initiate a craving session with intensity (1 to 4) and trigger. Returns suggested delay duration.
- `POST /cravings/{id}/intervention` — Record intervention technique used (breathing, water, grounding, walk, AI coach).
- `POST /cravings/{id}/complete` — Record final outcome (`did_smoke: boolean`, `post_feeling`, `actual_delayed_seconds`).
- `GET /cravings/history` — List past craving events.

## 5. Reduction Targets & Relapse
- `GET /targets/current` — Return today's target and status (`active`, `met`, `exceeded`, `paused`).
- `POST /targets/adjust` — Allow user to manually adjust their target to their preferred comfort level.
- `POST /targets/relapse-action` — Turn an exceeded target into behavioral data (`reason`, `action`: `maintain` | `adjust_plus_1` | `pause`).

## 6. Behavioral Analytics
- `GET /analytics/smoking-clock` — 24-hour histogram of smoking events with peak window identification.
- `GET /analytics/triggers` — Ranked breakdown of observed triggers and contextual observations.
- `GET /analytics/high-risk-windows` — Clustered high-risk periods with delay preparation recommendations.
- `GET /analytics/weekly-report` — Automated 7-day behavioral summary report.

## 7. AI Behavioral Coach
- `POST /coach/message` — Send a message to Clarity Coach. Receives structured, empathetic response, safety triage, and quick action chips.
- `GET /coach/history` — Fetch recent conversation history.

## 8. Health & RAG
- `GET /health/articles` — Curated educational articles from WHO, CDC, and NHS.
- `GET /health/articles/{slug}` — Detailed article view.
- `POST /health/ask-rag` — Question-answering endpoint retrieving evidence with explicit citations and medical disclaimers.

## 9. Settings & Privacy
- `GET /settings` — Get user notification preferences, quiet hours, and theme settings.
- `PATCH /settings` — Update preferences.
- `GET /settings/export-data` — Full GDPR-compliant data export in JSON format.
- `DELETE /settings/account` — Permanent account deletion with complete data purge.

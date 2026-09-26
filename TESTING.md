# Testing Suite & Quality Assurance

Clarity features a comprehensive automated test suite covering unit logic, safety boundaries, RAG search, database transactions, and user integration flows.

---

## 1. Running the Automated Tests

Navigate to `backend` and execute `pytest`:

```bash
cd backend
.\venv\Scripts\python -m pytest app/tests -v
```

---

## 2. Test Coverage Summary

### `test_auth_and_onboarding`
- Validates user registration with password hashing.
- Issues JWT bearer token.
- Verifies onboarding survey submission with baseline calculation.

### `test_smoking_tracker_and_today_summary`
- Validates 1-tap rapid cigarette logging.
- Tests today's count aggregation and elapsed time since last cigarette.
- Verifies avoidance calculation based on baseline.

### `test_craving_and_intervention_flow`
- Tests initiation of craving session with intensity rating.
- Records real-time intervention technique (e.g. 4-4-4 breathing).
- Validates non-punitive completion where `did_smoke=False` awards delay victory and updates adaptive capacity.

### `test_ai_safety_and_emergency_interception`
- Simulates user presenting emergency symptom: *"I have sudden chest pain and numbness in my arm"*.
- Verifies immediate safety diversion with emergency medical referral.
- Simulates medication dosage query: *"What dosage of varenicline should I take?"*.
- Verifies redirection to physician/pharmacist.

### `test_rag_health_queries`
- Tests semantic vector search across WHO and CDC health documents.
- Verifies answers contain explicit source citations, uncertainty statements, and medical disclaimers.

### `test_analytics_and_weekly_report`
- Tests 24-hour smoking clock generation.
- Tests trigger frequency calculation.
- Verifies weekly AI observation generation.

### `test_relapse_non_punitive_flow`
- Tests target exceedance handling with behavioral reason tagging and target stabilization options.

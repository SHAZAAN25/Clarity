import pytest
import uuid
from app.services.safety_service import SafetyService

def create_authenticated_user(client):
    unique_email = f"user_{uuid.uuid4().hex[:8]}@example.com"
    reg_resp = client.post("/api/v1/auth/register", json={
        "email": unique_email,
        "password": "StrongPassword123!",
        "full_name": "Test Smoker"
    })
    token = reg_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # Complete Onboarding
    client.post("/api/v1/onboarding/complete", json={
        "baseline_cigs_per_day": 16,
        "cost_per_pack": 15.0,
        "cigs_per_pack": 20,
        "years_smoking": 7,
        "first_cig_after_waking_mins": 25,
        "goal": "reduce",
        "motivations": ["health", "money"],
        "common_triggers": ["stress", "coffee"]
    }, headers=headers)
    
    return headers

def test_auth_and_onboarding(client):
    unique_email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    reg_resp = client.post("/api/v1/auth/register", json={
        "email": unique_email,
        "password": "StrongPassword123!",
        "full_name": "Onboard Smoker"
    })
    assert reg_resp.status_code == 201, reg_resp.text
    token = reg_resp.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    onboard_resp = client.post("/api/v1/onboarding/complete", json={
        "baseline_cigs_per_day": 16,
        "cost_per_pack": 15.0,
        "cigs_per_pack": 20,
        "years_smoking": 7,
        "first_cig_after_waking_mins": 25,
        "goal": "reduce",
        "motivations": ["health", "money"],
        "common_triggers": ["stress", "coffee"]
    }, headers=headers)
    assert onboard_resp.status_code == 200
    pdata = onboard_resp.json()
    assert pdata["baseline_cigs_per_day"] == 16
    assert pdata["onboarding_completed"] is True

def test_smoking_tracker_and_today_summary(client):
    headers = create_authenticated_user(client)
    
    # Log 1 quick cigarette
    log_resp = client.post("/api/v1/smoking/log", json={
        "count": 1,
        "trigger": "Coffee",
        "is_quick_log": True
    }, headers=headers)
    assert log_resp.status_code == 201
    
    # Get today's summary
    today_resp = client.get("/api/v1/smoking/today", headers=headers)
    assert today_resp.status_code == 200
    today_data = today_resp.json()
    assert today_data["total_cigarettes"] >= 1
    assert today_data["status"] in ["on_track", "caution", "exceeded"]
    
    # Check history
    hist_resp = client.get("/api/v1/smoking/history", headers=headers)
    assert hist_resp.status_code == 200
    assert len(hist_resp.json()) >= 1

def test_craving_and_intervention_flow(client):
    headers = create_authenticated_user(client)
    
    # 1. Start craving
    start_resp = client.post("/api/v1/cravings/start", json={
        "intensity": 3,
        "trigger": "Stress",
        "mood": "Anxious"
    }, headers=headers)
    assert start_resp.status_code == 201
    craving_id = start_resp.json()["id"]
    
    # 2. Record intervention (breathing exercise)
    interv_resp = client.post(f"/api/v1/cravings/{craving_id}/intervention", json={
        "intervention_type": "breathing",
        "duration_seconds": 120,
        "was_helpful": True
    }, headers=headers)
    assert interv_resp.status_code == 201
    
    # 3. Complete craving delay (user did not smoke)
    complete_resp = client.post(f"/api/v1/cravings/{craving_id}/complete", json={
        "did_smoke": False,
        "post_feeling": "weaker",
        "actual_delayed_seconds": 600
    }, headers=headers)
    assert complete_resp.status_code == 200
    c_data = complete_resp.json()
    assert c_data["status"] == "delayed_success"

def test_ai_coach_messaging_and_safety_interception(client):
    headers = create_authenticated_user(client)
    
    # 1. Normal craving conversation
    msg_resp = client.post("/api/v1/coach/message", json={
        "message": "I really want a cigarette right now after a difficult meeting."
    }, headers=headers)
    assert msg_resp.status_code == 200
    data = msg_resp.json()
    assert data["role"] == "assistant"
    assert data["is_safety_diverted"] is False
    assert len(data["suggested_quick_actions"]) >= 1
    
    # 2. Emergency symptom interception
    unsafe_resp = client.post("/api/v1/coach/message", json={
        "message": "I am having sudden crushing chest pain and shortness of breath."
    }, headers=headers)
    assert unsafe_resp.status_code == 200
    udata = unsafe_resp.json()
    assert udata["is_safety_diverted"] is True
    assert "emergency medical" in udata["content"].lower()

def test_rag_health_queries(client):
    # Query knowledge base
    rag_resp = client.post("/api/v1/health/ask-rag", json={
        "query": "How long does a nicotine craving usually last?"
    })
    assert rag_resp.status_code == 200
    data = rag_resp.json()
    assert "answer" in data
    assert len(data["citations"]) >= 1
    assert "uncertainty_statement" in data
    assert "medical_disclaimer" in data
    
    # Articles list
    art_resp = client.get("/api/v1/health/articles")
    assert art_resp.status_code == 200
    assert len(art_resp.json()) >= 1

def test_analytics_and_weekly_report(client):
    headers = create_authenticated_user(client)
    
    # Smoking clock
    clock_resp = client.get("/api/v1/analytics/smoking-clock", headers=headers)
    assert clock_resp.status_code == 200
    assert len(clock_resp.json()["clock_data"]) == 24
    
    # Triggers
    trigger_resp = client.get("/api/v1/analytics/triggers", headers=headers)
    assert trigger_resp.status_code == 200
    assert "primary_observation" in trigger_resp.json()
    
    # Weekly report
    report_resp = client.get("/api/v1/analytics/weekly-report", headers=headers)
    assert report_resp.status_code == 200
    assert "ai_observation" in report_resp.json()

def test_relapse_non_punitive_flow(client):
    headers = create_authenticated_user(client)
    
    # User exceeds target and provides behavioral feedback
    relapse_resp = client.post("/api/v1/targets/relapse-action", json={
        "reason": "Unexpected stress at work",
        "action": "maintain"
    }, headers=headers)
    assert relapse_resp.status_code == 200
    data = relapse_resp.json()
    assert data["relapse_reason"] == "Unexpected stress at work"
    assert "valuable behavioral insight" in data["reduction_advice"]

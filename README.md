
# Clarity — AI-Powered Smoking Reduction & Cessation Coach

> *"Don't just count cigarettes. Understand why you smoke them."*

Clarity is an evidence-based, mobile-first smoking reduction and cessation companion. Designed from behavioral psychology principles (CBT, cue-extinction, and mindful delay techniques), Clarity treats every cigarette as behavioral information rather than a moral failure.

---

## 🌟 Core Product Philosophy

- **Never Punitive**: Avoids toxic streaks, shame, and guilt-based language like *"You failed"* or *"Streak lost"*.
- **Relapse as Data**: If a user exceeds their daily target, Clarity asks what happened (stress, social cue, alcohol, craving wave) and offers flexible options to maintain, adjust (+1), or pause reduction.
- **Track → Understand → Delay → Reduce → Gain Control → Optional Quitting**: The user stays in control of their pace. No forced quit dates.
- **Evidence-Based Grounding**: Health guidance is powered by authoritative sources (WHO, CDC, NHS, Cochrane Reviews) with transparent citations and medical disclaimers.

---

## 📱 Key Features

1. **2-Second Quick Log**: Fast 1-tap logging with optional situational trigger tagging.
2. **"I'm Craving" Intervention System**:
   - Immediate 10-minute adaptive delay challenge.
   - Interactive 4-4-4 breathing orb visualizer.
   - 5-4-3-2-1 sensory grounding exercise.
   - Non-punitive post-timer check-in.
3. **Adaptive Reduction Engine**:
   - Generates non-drastic daily reduction targets.
   - Dynamic delay capability (10 min → 15 min → 20 min) adapting to consecutive delay wins.
4. **24-Hour Smoking Clock**:
   - Visualizes hourly smoking density and highlights high-risk peak windows (e.g. 19:00–21:00).
5. **AI Behavioral Coach**:
   - Empathetic conversational partner with structured minimal context (baseline, current target, today's count, triggers).
   - Strict medical safety guardrails (emergency symptom triage, diagnosis prevention, prescription boundary).
6. **RAG Health Library**:
   - Searchable knowledge base grounded in WHO/CDC guidelines with source citations.
7. **Financial & Harm Reduction Tracker**:
   - Real-time calculation of cigarettes spared and estimated money saved based on pack pricing.
8. **Offline Resilience**:
   - Local queuing of logs and cravings with auto-sync when connectivity returns.

---

## 🛠️ Technology Stack

- **Backend**: Python 3.14, FastAPI, SQLAlchemy 2.0, Pydantic V2, bcrypt, PyJWT, pytest.
- **Database**: Relational schema supporting SQLite (local dev) and PostgreSQL (production).
- **Frontend**: React 19, TypeScript, Vite, Vanilla CSS with Midnight Teal design system, Lucide icons.
- **AI / LLM Abstraction**: Modular adapter supporting `local_fallback` (zero-crash heuristic engine), OpenAI, and Google Gemini.

---

## 🚀 Quick Start Guide

### 1. Backend Server
```bash
cd backend
python -m venv venv
.\venv\Scripts\activate
pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
API Documentation will be available at [http://localhost:8000/docs](http://localhost:8000/docs).

### 2. Frontend Mobile Web App
```bash
cd frontend
npm install
npm run dev -- --host 0.0.0.0 --port 5173
```
Open [http://localhost:5173](http://localhost:5173) in your browser (or mobile device on the same local network).

---

## 🧪 Running Tests

```bash
cd backend
.\venv\Scripts\python -m pytest app/tests
```

All 7 test suites validate authentication, rapid tracking, craving flow, AI safety triage, RAG evidence retrieval, analytics, and non-punitive relapse flows.

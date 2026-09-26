# Local Developer Setup Guide

Step-by-step instructions to get Clarity running locally from scratch.

---

## 1. Prerequisites
- Python 3.11+ (Python 3.14 tested)
- Node.js 18+ (Node 22 tested)
- Git

---

## 2. Setting Up the Backend

```bash
cd backend

# Create and activate virtual environment
python -m venv venv
.\venv\Scripts\activate   # On Windows
# source venv/bin/activate  # On macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Create .env from template
copy .env.example .env    # On Windows
# cp .env.example .env     # On macOS/Linux

# Run tests to confirm integrity
pytest app/tests

# Launch local server
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Swagger UI is active at: `http://localhost:8000/docs`

---

## 3. Setting Up the Frontend

```bash
cd frontend

# Install packages
npm install

# Start Vite dev server
npm run dev -- --host 0.0.0.0 --port 5173
```
Visit: `http://localhost:5173`

---

## 4. Immediate Exploration & Demo Mode
1. Click **"⚡ Quick 1-Click Demo Account"** on the login screen to enter immediately.
2. Complete the short Onboarding survey.
3. Test **LOG CIGARETTE** (takes 2 seconds) and **I'M CRAVING** (10-minute timer with 4-4-4 breathing circle).
4. In Settings, click **"⚡ Seed 7 Days of Sample History"** to immediately populate the 24-hour smoking clock and trigger charts!

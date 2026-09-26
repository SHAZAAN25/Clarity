# Deployment Guide

Clarity is production-ready for deployment to containerized cloud platforms (AWS ECS, Google Cloud Run, Railway, or Render).

---

## 1. Production Architecture Requirements

1. **PostgreSQL Database**:
   - Provision a PostgreSQL 15+ database (e.g. AWS RDS or Supabase).
   - Set `DATABASE_URL=postgresql+psycopg2://user:password@hostname:5432/clarity_db`.
2. **Environment Variables**:
   - `SECRET_KEY`: High-entropy 64-character secret.
   - `LLM_PROVIDER`: `openai` or `gemini`.
   - `LLM_API_KEY`: API credentials for chosen LLM provider.
   - `ALLOWED_ORIGINS`: Comma-separated frontend domains (e.g. `https://clarity.health`).

---

## 2. Docker Deployment

### Backend Dockerfile (`backend/Dockerfile`)
```dockerfile
FROM python:3.14-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Frontend Build & Static Serving
```bash
cd frontend
npm install
npm run build
```
Deploy the resulting `dist/` directory to Vercel, Netlify, or AWS CloudFront S3 bucket.

---

## 3. Mobile App Packaging (Capacitor / Android APK)
To build an Android APK from this project:
```bash
cd frontend
npm install @capacitor/core @capacitor/cli @capacitor/android
npx cap init Clarity com.clarity.cessationcoach --web-dir dist
npm run build
npx cap add android
npx cap open android
```
Inside Android Studio, build the release APK or AAB bundle for the Google Play Store.

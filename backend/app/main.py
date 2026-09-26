from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.database import engine, Base
import app.models # ensure all models are registered
from app.services.rag_service import RAGService
from app.core.database import SessionLocal

# Import API Routers
from app.api.auth import router as auth_router
from app.api.onboarding import router as onboarding_router
from app.api.smoking import router as smoking_router
from app.api.cravings import router as cravings_router
from app.api.targets import router as targets_router
from app.api.progress import router as progress_router
from app.api.analytics import router as analytics_router
from app.api.coach import router as coach_router
from app.api.health import router as health_router
from app.api.settings import router as settings_router
from app.api.dev import router as dev_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create all DB tables
    Base.metadata.create_all(bind=engine)
    # Seed authoritative RAG knowledge base
    db = SessionLocal()
    try:
        RAGService.seed_knowledge_base(db)
    finally:
        db.close()
    yield

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    description="AI-Powered Smoking Reduction & Cessation Coach - Evidence-based, non-judgmental behavioral guidance.",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Allow development frontends
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global error handler for safe fallbacks
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={"detail": "An unexpected error occurred. The application remains stable.", "error_type": type(exc).__name__}
    )

# Include Routers with API V1 Prefix
prefix = settings.API_V1_PREFIX
app.include_router(auth_router, prefix=prefix)
app.include_router(onboarding_router, prefix=prefix)
app.include_router(smoking_router, prefix=prefix)
app.include_router(cravings_router, prefix=prefix)
app.include_router(targets_router, prefix=prefix)
app.include_router(progress_router, prefix=prefix)
app.include_router(analytics_router, prefix=prefix)
app.include_router(coach_router, prefix=prefix)
app.include_router(health_router, prefix=prefix)
app.include_router(settings_router, prefix=prefix)
app.include_router(dev_router, prefix=prefix)

@app.get("/")
def root():
    return {
        "message": "Clarity AI Smoking Reduction & Cessation Coach API is active.",
        "docs": "/docs",
        "health": f"{settings.API_V1_PREFIX}/dev/health"
    }

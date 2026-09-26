import os
from typing import List
from pydantic import BaseModel

class Settings(BaseModel):
    APP_NAME: str = "Clarity - AI Smoking Reduction & Cessation Coach"
    APP_ENV: str = os.getenv("APP_ENV", "development")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() in ("true", "1", "yes")
    API_V1_PREFIX: str = os.getenv("API_V1_PREFIX", "/api/v1")
    
    SECRET_KEY: str = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production-must-be-32-chars-min!")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080"))
    
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./clarity_coach.db")
    
    LLM_PROVIDER: str = os.getenv("LLM_PROVIDER", "local_fallback")
    LLM_API_KEY: str = os.getenv("LLM_API_KEY", "")
    LLM_MODEL: str = os.getenv("LLM_MODEL", "gpt-4o-mini")
    LLM_TEMPERATURE: float = float(os.getenv("LLM_TEMPERATURE", "0.6"))
    
    EMBEDDING_PROVIDER: str = os.getenv("EMBEDDING_PROVIDER", "local_fallback")
    ALLOWED_ORIGINS: List[str] = [
        origin.strip() 
        for origin in os.getenv(
            "ALLOWED_ORIGINS", 
            "http://localhost:5173,http://localhost:3000,http://127.0.0.1:5173,http://127.0.0.1:3000"
        ).split(",") if origin.strip()
    ]

settings = Settings()

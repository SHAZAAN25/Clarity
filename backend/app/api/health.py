from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.models import HealthArticle
from app.schemas.schemas import HealthArticleResponse, RAGQueryRequest, RAGQueryResponse
from app.services.rag_service import RAGService

router = APIRouter(prefix="/health", tags=["Health & Education (RAG)"])

@router.get("/articles", response_model=List[HealthArticleResponse])
def get_health_articles(db: Session = Depends(get_db)):
    RAGService.seed_knowledge_base(db)
    articles = db.query(HealthArticle).all()
    return articles

@router.get("/articles/{slug_or_id}", response_model=HealthArticleResponse)
def get_article_detail(slug_or_id: str, db: Session = Depends(get_db)):
    RAGService.seed_knowledge_base(db)
    article = db.query(HealthArticle).filter(
        (HealthArticle.slug == slug_or_id) | (HealthArticle.id == slug_or_id)
    ).first()
    if not article:
        raise HTTPException(status_code=404, detail="Article not found")
    return article

@router.post("/ask-rag", response_model=RAGQueryResponse)
def ask_rag_health_question(payload: RAGQueryRequest, db: Session = Depends(get_db)):
    """
    Retrieves grounded evidence from authoritative health guidelines (WHO, CDC, NHS),
    synthesizes a non-prescriptive educational response with citations and medical disclaimer.
    """
    if not payload.query or len(payload.query.strip()) < 3:
        raise HTTPException(status_code=400, detail="Query is too short.")
    return RAGService.answer_health_query(db, payload.query)

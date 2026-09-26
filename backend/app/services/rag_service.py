import math
import re
import json
from typing import List, Dict, Any, Tuple, Optional
from sqlalchemy.orm import Session

from app.models.models import HealthArticle, RAGDocument, RAGChunk
from app.schemas.schemas import SourceCitation, RAGQueryResponse

# Authoritative pre-seeded medical and public health knowledge corpus
CURATED_HEALTH_CORPUS = [
    {
        "title": "WHO Tobacco Fact Sheet: Health Consequences and Cessation",
        "organization": "World Health Organization (WHO)",
        "url": "https://www.who.int/news-room/fact-sheets/detail/tobacco",
        "doc_type": "Public Health Factsheet",
        "content": (
            "Tobacco use is a major risk factor for cardiovascular and respiratory diseases. "
            "While reducing the number of cigarettes smoked per day can lower exposure to certain toxins, "
            "scientific evidence shows that complete cessation is required to eliminate the vast majority of long-term cardiovascular risks. "
            "Within 20 minutes of quitting, elevated heart rate and blood pressure drop. "
            "Within 12 hours, the carbon monoxide level in blood returns to normal. "
            "Within 2 to 12 weeks, circulation improves and lung function increases."
        )
    },
    {
        "title": "CDC: Managing Nicotine Cravings and Withdrawal",
        "organization": "Centers for Disease Control and Prevention (CDC)",
        "url": "https://www.cdc.gov/tobacco/campaign/tips/quit-smoking/guide/index.html",
        "doc_type": "Clinical Clinical Practice Guidelines",
        "content": (
            "Nicotine cravings are intense neurobiological urges triggered by falling dopamine levels in the brain's reward pathways. "
            "Most acute cravings last only 3 to 5 minutes, rarely exceeding 10 minutes. "
            "Behavioral strategies such as the 4 Ds (Delay 10 minutes, Deep breathe, Drink water, Distract yourself) "
            "effectively allow the brain's craving spike to crest and subside without nicotine administration. "
            "Gradually extending the delay between craving and smoking retrains conditioned neural responses."
        )
    },
    {
        "title": "NHS Guidelines: Nicotine Replacement Therapy and Gradual Reduction",
        "organization": "National Health Service (NHS)",
        "url": "https://www.nhs.uk/live-well/quit-smoking/using-e-cigarettes-and-nrt-to-stop-smoking/",
        "doc_type": "Clinical Health Guidelines",
        "content": (
            "Nicotine Replacement Therapy (NRT) provides clean, controlled nicotine without the toxic carbon monoxide, tar, and carcinogens in tobacco smoke. "
            "Options include transdermal patches (slow, steady release) and fast-acting oral forms (gum, lozenges, inhalators, mouth sprays). "
            "Combining a slow-release patch with a fast-acting oral NRT is significantly more effective than single-product therapy. "
            "Gradual reduction (Cut Down to Quit) combined with behavioral support has been validated as an effective pathway toward eventual complete abstinence."
        )
    },
    {
        "title": "Cochrane Systematic Review: Behavioral Interventions for Smoking Reduction",
        "organization": "Cochrane Tobacco Addiction Group",
        "url": "https://www.cochranelibrary.com/cdsr/doi/10.1002/14651858.CD013183.pub2/full",
        "doc_type": "Systematic Review",
        "content": (
            "Evidence from randomized trials demonstrates that scheduled reduction, delay techniques, and cue-exposure management "
            "increase the likelihood that smokers who do not initially wish to quit immediately will eventually attempt and achieve abstinence. "
            "Tracking triggers, delaying cigarettes by structured increments, and non-punitive behavioral monitoring "
            "promote self-efficacy and reduce cognitive dissonance associated with smoking slips."
        )
    },
    {
        "title": "Mayo Clinic: Understanding Nicotine Withdrawal Symptoms",
        "organization": "Mayo Clinic Public Health",
        "url": "https://www.mayoclinic.org/diseases-conditions/nicotine-dependence/symptoms-causes/syc-20351584",
        "doc_type": "Medical Reference",
        "content": (
            "Nicotine withdrawal produces both physical and psychological symptoms including irritability, anxiety, difficulty concentrating, "
            "increased appetite, restlessness, and mild sleep disturbances. "
            "Symptoms typically peak within the first 24 to 72 hours following substantial reduction or abstinence, "
            "and gradually diminish over 2 to 4 weeks. "
            "Physical withdrawal is not medically dangerous for most adults, but psychological cravings can persist longer and require behavioral coping skills."
        )
    }
]

class RAGService:
    """
    Retrieval-Augmented Generation for grounded health questions.
    Uses TF-IDF / term-frequency vector cosine similarity to retrieve evidence
    without external API reliance, returning explicit citations.
    """

    @classmethod
    def seed_knowledge_base(cls, db: Session):
        """Seed the RAG knowledge documents if empty"""
        existing = db.query(RAGDocument).first()
        if existing:
            return
            
        for doc_data in CURATED_HEALTH_CORPUS:
            doc = RAGDocument(
                title=doc_data["title"],
                source_organization=doc_data["organization"],
                source_url=doc_data["url"],
                document_type=doc_data["doc_type"],
                raw_content=doc_data["content"]
            )
            db.add(doc)
            db.flush()
            
            # Chunk the content into bite-sized evidence units
            sentences = re.split(r'(?<=[.!?])\s+', doc_data["content"])
            chunk_size = 2
            for i in range(0, len(sentences), chunk_size):
                chunk_sentences = sentences[i:i + chunk_size]
                chunk_text = " ".join(chunk_sentences).strip()
                if chunk_text:
                    chunk = RAGChunk(
                        document_id=doc.id,
                        chunk_index=i // chunk_size,
                        chunk_text=chunk_text,
                        embedding_json=json.dumps(cls._compute_simple_embedding(chunk_text))
                    )
                    db.add(chunk)
                    
        # Also seed educational articles
        cls._seed_articles(db)
        db.commit()

    @classmethod
    def _seed_articles(cls, db: Session):
        articles = [
            {
                "title": "Why Nicotine Cravings Crest and Fade",
                "slug": "why-cravings-crest-and-fade",
                "category": "cravings",
                "summary": "Understanding why cigarette cravings feel overwhelming for 3–5 minutes and how your body naturally dissipates them.",
                "content": (
                    "When nicotine levels drop, the brain triggers a brief spike in urgency. "
                    "However, this biochemical peak rarely stays at maximum intensity for more than 5 to 10 minutes. "
                    "By simply delaying the urge—drinking water, taking 10 deep breaths, or engaging in a change of environment—"
                    "you allow the wave of craving to crest and subside without smoking."
                ),
                "author_organization": "CDC & Clinical Evidence",
                "source_url": "https://www.cdc.gov/tobacco/campaign/tips/quit-smoking/guide/index.html",
                "reading_time_mins": 3
            },
            {
                "title": "Reducing vs. Quitting: What the Science Shows",
                "slug": "reducing-vs-quitting-science",
                "category": "health_benefits",
                "summary": "The objective medical reality of cutting down cigarettes, and why reduction is a stepping stone rather than a complete health shield.",
                "content": (
                    "Reducing daily cigarettes reduces your daily financial cost, eases throat irritation, and lowers carbon monoxide levels. "
                    "However, scientific research from the World Health Organization emphasizes that even a few cigarettes a day carry cardiovascular risk. "
                    "Smoking fewer cigarettes is a vital behavioral stepping stone that builds confidence, but total cessation is the ultimate goal for lasting cardiovascular and cancer risk reduction."
                ),
                "author_organization": "World Health Organization",
                "source_url": "https://www.who.int/news-room/fact-sheets/detail/tobacco",
                "reading_time_mins": 4
            },
            {
                "title": "The Nicotine Withdrawal Timeline",
                "slug": "nicotine-withdrawal-timeline",
                "category": "withdrawal",
                "summary": "What your body experiences hour by hour and day by day during reduction and cessation.",
                "content": (
                    "• 20 Minutes: Heart rate settles toward baseline.\n"
                    "• 12 Hours: Blood carbon monoxide level normalizes.\n"
                    "• 24 to 72 Hours: Peak irritability and cravings as nicotine clears from blood.\n"
                    "• 2 Weeks: Circulation and lung function show measurable improvements.\n"
                    "• 1 to 9 Months: Coughing and shortness of breath decrease as cilia regain normal function."
                ),
                "author_organization": "Mayo Clinic & NHS",
                "source_url": "https://www.nhs.uk/live-well/quit-smoking/using-e-cigarettes-and-nrt-to-stop-smoking/",
                "reading_time_mins": 4
            },
            {
                "title": "Managing Social & Coffee Triggers",
                "slug": "managing-social-coffee-triggers",
                "category": "psychology",
                "summary": "Practical cue-exposure strategies for uncoupling everyday routines from automatic smoking.",
                "content": (
                    "Smoking is rarely just a physical dependence; it is paired with daily routines. "
                    "Coffee and smoking become paired in memory. To break this, try changing the routine: "
                    "switch your morning coffee mug, drink your coffee in a different room where smoking is prohibited, "
                    "or replace the post-coffee cigarette with a cold glass of iced water or a brisk 5-minute walk."
                ),
                "author_organization": "Cochrane Behavioral Review",
                "source_url": "https://www.cochranelibrary.com",
                "reading_time_mins": 3
            }
        ]
        
        for a in articles:
            existing = db.query(HealthArticle).filter(HealthArticle.slug == a["slug"]).first()
            if not existing:
                db.add(HealthArticle(**a))

    @classmethod
    def _compute_simple_embedding(cls, text: str) -> Dict[str, float]:
        """
        Computes normalized term-frequency vector for zero-dependency local semantic matching.
        """
        words = re.findall(r'\b[a-z]{3,}\b', text.lower())
        stopwords = {"the", "and", "for", "with", "that", "this", "from", "are", "can", "not", "have", "you"}
        filtered = [w for w in words if w not in stopwords]
        
        freq = {}
        for w in filtered:
            freq[w] = freq.get(w, 0) + 1.0
            
        # Normalize
        length = math.sqrt(sum(v * v for v in freq.values())) or 1.0
        return {k: v / length for k, v in freq.items()}

    @classmethod
    def _cosine_similarity(cls, vec1: Dict[str, float], vec2: Dict[str, float]) -> float:
        intersection = set(vec1.keys()) & set(vec2.keys())
        return sum(vec1[k] * vec2[k] for k in intersection)

    @classmethod
    def answer_health_query(cls, db: Session, query: str) -> RAGQueryResponse:
        """
        Retrieves relevant evidence from authoritative documents, synthesizes a grounded answer,
        includes explicit citations, communicates uncertainty, and provides a medical disclaimer.
        """
        cls.seed_knowledge_base(db)
        query_vec = cls._compute_simple_embedding(query)
        
        chunks = db.query(RAGChunk).all()
        scored_chunks: List[Tuple[float, RAGChunk]] = []
        
        for chunk in chunks:
            if not chunk.embedding_json:
                continue
            try:
                emb = json.loads(chunk.embedding_json)
                score = cls._cosine_similarity(query_vec, emb)
                if score > 0.05:
                    scored_chunks.append((score, chunk))
            except Exception:
                continue
                
        scored_chunks.sort(key=lambda x: x[0], reverse=True)
        top_chunks = scored_chunks[:3]
        
        citations: List[SourceCitation] = []
        evidence_texts = []
        
        for score, ch in top_chunks:
            doc = ch.document
            citations.append(SourceCitation(
                title=doc.title,
                source_organization=doc.source_organization,
                source_url=doc.source_url,
                relevance_summary=f"Evidence match (Score: {round(score, 2)}): {ch.chunk_text[:120]}..."
            ))
            evidence_texts.append(ch.chunk_text)
            
        if not evidence_texts:
            # Fallback if query terms didn't match directly
            doc = db.query(RAGDocument).first()
            if doc:
                citations.append(SourceCitation(
                    title=doc.title,
                    source_organization=doc.source_organization,
                    source_url=doc.source_url,
                    relevance_summary="General tobacco cessation guidance."
                ))
            evidence_texts.append("Scientific public health evidence emphasizes that while gradual reduction lowers toxin intake, complete cessation provides the most profound health recovery.")

        # Grounded answer synthesis
        synthesized_answer = (
            f"Based on public health guidelines from {citations[0].source_organization if citations else 'authoritative sources'}:\n\n"
            + "\n\n".join(f"• {t}" for t in evidence_texts)
        )
        
        return RAGQueryResponse(
            query=query,
            answer=synthesized_answer,
            citations=citations,
            uncertainty_statement=(
                "Individual physiological responses, withdrawal severity, and nicotine metabolism vary based on "
                "genetics, duration of smoking, and overall health status."
            ),
            medical_disclaimer=(
                "This evidence-based information is provided for educational and behavioral coaching purposes only. "
                "It does not constitute formal medical diagnosis or prescription. Always consult a healthcare provider for personalized medical advice."
            )
        )

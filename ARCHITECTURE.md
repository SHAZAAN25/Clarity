# Architecture & Design Specifications

## 1. System Overview

Clarity is structured as a decoupled client-server application optimized for mobile touch interaction and behavioral coaching.

```
┌────────────────────────────────────────────────────────┐
│            Mobile Client (React / Vite / PWA)          │
│  - Midnight Teal Theme (Vanilla CSS)                   │
│  - Offline Action Queue (Local Storage)                │
│  - 4-4-4 Animated Breathing Coach                      │
│  - 24-Hour Smoking Clock Component                     │
└───────────────────────────▲────────────────────────────┘
                            │ REST / JSON (JWT Auth)
┌───────────────────────────▼────────────────────────────┐
│                  FastAPI Backend Server                │
│                                                        │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────┐ │
│  │   Auth Router   │ │ Smoking Router  │ │ Cravings │ │
│  └─────────────────┘ └─────────────────┘ └──────────┘ │
│  ┌─────────────────┐ ┌─────────────────┐ ┌──────────┐ │
│  │ Target / Relapse│ │ Behavioral AI   │ │ RAG Info │ │
│  └─────────────────┘ └─────────────────┘ └──────────┘ │
│                                                        │
│  Modular Service Layer:                                │
│  • SafetyService      - Emergency triage & clinical boundary
│  • CoachService       - Empathetic structured context prompts
│  • AIService          - Provider abstraction (local/OpenAI/Gemini)
│  • ReductionEngine    - Adaptive target & capacity algorithm
│  • AnalyticsService   - Hourly distribution & trigger stats
│  • RAGService         - Cosine similarity vector retrieval    
│  • NotificationService- Quiet hours & frequency throttle
└───────────────────────────▲────────────────────────────┘
                            │ SQLAlchemy ORM
┌───────────────────────────▼────────────────────────────┐
│                   Relational Database                  │
│  • PostgreSQL (Production) / SQLite (Zero-config dev)  │
│  • UUIDs, Indexes on (user_id, date, logged_at)        │
└────────────────────────────────────────────────────────┘
```

---

## 2. Key Architecture Decisions

### 2.1 Cross-Platform Frontend Strategy
- Built with mobile-first viewport constraints (`max-width: 480px`, fixed bottom navigation, large touch targets, 44px+ hit areas).
- Ready for zero-friction Capacitor wrap (`npx cap add android` / `npx cap add ios`) or standalone Progressive Web App installation.

### 2.2 LLM Provider Abstraction Layer
`AIService` cleanly decouples business and coaching logic from LLM vendors:
- If `LLM_PROVIDER=local_fallback` or an external API is offline, a clinically structured heuristic engine responds without crashing.
- If `LLM_PROVIDER=openai` or `gemini`, external API calls are safely executed with automatic fallback on timeout or error.

### 2.3 RAG Architecture (Retrieval-Augmented Generation)
- Health and medical queries do not rely on unverified LLM generation.
- Grounded in curated public health guidelines (WHO, CDC, NHS, Cochrane).
- Knowledge documents are chunked and vector-indexed.
- Responses strictly return citations, source URLs, uncertainty declarations, and medical disclaimers.

### 2.4 AI Safety Pipeline
Every conversational input passes through `SafetyService`:
1. **Medical Emergency Check**: Identifies chest pain, acute shortness of breath, sudden numbness, or crisis expressions. Immediately returns localized emergency resources and directs to immediate medical care.
2. **Prescription/Dosage Boundary**: Blocks specific milligram or dosage requests for cessation drugs (Varenicline, Bupropion, NRT), directing user to consult their physician/pharmacist.
3. **Harm Sanitization**: Intercepts any false claims that reduction equates to absolute cardiovascular safety.

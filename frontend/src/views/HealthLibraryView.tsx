import React, { useState, useEffect } from 'react';
import { api, HealthArticle, RAGResponse } from '../services/api';
import { BookOpen, Search, ExternalLink, ShieldCheck, ChevronRight, HelpCircle } from 'lucide-react';

export const HealthLibraryView: React.FC = () => {
  const [articles, setArticles] = useState<HealthArticle[]>([]);
  const [selectedArticle, setSelectedArticle] = useState<HealthArticle | null>(null);

  // RAG Search states
  const [ragQuery, setRagQuery] = useState('');
  const [ragResult, setRagResult] = useState<RAGResponse | null>(null);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    api.getHealthArticles().then(setArticles).catch(console.error);
  }, []);

  const handleAskRAG = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!ragQuery.trim() || searching) return;

    setSearching(true);
    setRagResult(null);
    try {
      const res = await api.askRAG(ragQuery);
      setRagResult(res);
    } catch (e: any) {
      alert(e.message || 'Failed to search health evidence');
    } finally {
      setSearching(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ background: 'rgba(6, 182, 212, 0.2)', padding: 8, borderRadius: 10, color: '#06B6D4' }}>
          <BookOpen size={20} />
        </div>
        <div>
          <h2 style={{ fontSize: 20 }}>Evidence-Based Health</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
            Grounded in WHO, CDC, and Cochrane public health research.
          </p>
        </div>
      </div>

      {/* RAG Interactive Q&A Search Box */}
      <div className="glass-card" style={{ background: 'linear-gradient(135deg, rgba(6, 182, 212, 0.08), rgba(18, 30, 41, 0.85))' }}>
        <div className="card-title">
          <span>Ask Evidence Library (RAG)</span>
          <HelpCircle size={16} color="#06B6D4" />
        </div>

        <form onSubmit={handleAskRAG} style={{ display: 'flex', gap: 8, marginTop: 8 }}>
          <input 
            type="text" 
            value={ragQuery} 
            onChange={e => setRagQuery(e.target.value)}
            placeholder="e.g. Does cutting down eliminate heart risk?" 
            style={{ flex: 1 }}
          />
          <button 
            type="submit" 
            className="btn-primary" 
            style={{ background: 'linear-gradient(135deg, #06B6D4, #0891B2)' }}
            disabled={searching || !ragQuery.trim()}
          >
            <Search size={18} />
          </button>
        </form>

        {searching && (
          <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 12, fontStyle: 'italic' }}>
            Retrieving clinical sources and synthesizing grounded response...
          </div>
        )}

        {/* Grounded RAG Result Display */}
        {ragResult && (
          <div style={{ marginTop: 16, paddingTop: 14, borderTop: '1px solid var(--border-subtle)' }}>
            <div style={{ fontSize: 14, color: 'var(--text-primary)', whiteSpace: 'pre-line', lineHeight: 1.6 }}>
              {ragResult.answer}
            </div>

            {/* Citations Box */}
            <div style={{ marginTop: 14, background: 'rgba(255, 255, 255, 0.04)', borderRadius: 12, padding: 12 }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: '#38BDF8', textTransform: 'uppercase', letterSpacing: '0.05em', marginBottom: 6 }}>
                Verified Sources & Citations
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {ragResult.citations.map((c, i) => (
                  <div key={i} style={{ fontSize: 12, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span style={{ color: 'var(--text-secondary)' }}>• {c.title} ({c.source_organization})</span>
                    {c.source_url && (
                      <a 
                        href={c.source_url} 
                        target="_blank" 
                        rel="noreferrer" 
                        style={{ color: '#06B6D4', display: 'flex', alignItems: 'center', gap: 2, fontSize: 11 }}
                      >
                        Source <ExternalLink size={12} />
                      </a>
                    )}
                  </div>
                ))}
              </div>
            </div>

            <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 10, fontStyle: 'italic' }}>
              Note: {ragResult.uncertainty_statement}
            </p>
            <p style={{ fontSize: 11, color: '#94A3B8', marginTop: 4 }}>
              ⚖️ {ragResult.medical_disclaimer}
            </p>
          </div>
        )}
      </div>

      {/* Selected Article Detail Modal */}
      {selectedArticle && (
        <div className="modal-overlay" onClick={() => setSelectedArticle(null)}>
          <div className="modal-sheet" onClick={e => e.stopPropagation()}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
              <h3 style={{ fontSize: 18, lineHeight: 1.3 }}>{selectedArticle.title}</h3>
              <button className="btn-ghost" onClick={() => setSelectedArticle(null)}>✕</button>
            </div>

            <div style={{ display: 'flex', gap: 8, alignItems: 'center', fontSize: 12, color: '#38BDF8', marginBottom: 14 }}>
              <span>{selectedArticle.author_organization}</span>
              <span>•</span>
              <span>{selectedArticle.reading_time_mins} min read</span>
            </div>

            <div style={{ fontSize: 14, color: 'var(--text-primary)', lineHeight: 1.7, whiteSpace: 'pre-line' }}>
              {selectedArticle.content}
            </div>

            {selectedArticle.source_url && (
              <div style={{ marginTop: 20, paddingTop: 14, borderTop: '1px solid var(--border-subtle)' }}>
                <a 
                  href={selectedArticle.source_url} 
                  target="_blank" 
                  rel="noreferrer"
                  className="btn-secondary" 
                  style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 12 }}
                >
                  View Official Guidelines <ExternalLink size={14} />
                </a>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Educational Articles List */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
          Curated Educational Guides
        </div>

        {articles.map(art => (
          <div
            key={art.id}
            className="glass-card"
            onClick={() => setSelectedArticle(art)}
            style={{ 
              cursor: 'pointer', 
              display: 'flex', 
              justifyContent: 'space-between', 
              alignItems: 'center',
              padding: '14px 18px'
            }}
          >
            <div>
              <div style={{ fontSize: 15, fontWeight: 600, marginBottom: 4 }}>{art.title}</div>
              <div style={{ fontSize: 12, color: 'var(--text-secondary)', lineHeight: 1.4 }}>{art.summary}</div>
              <div style={{ fontSize: 11, color: '#34D399', marginTop: 6 }}>
                Source: {art.author_organization}
              </div>
            </div>
            <ChevronRight size={18} color="var(--text-muted)" style={{ flexShrink: 0, marginLeft: 10 }} />
          </div>
        ))}
      </div>
    </div>
  );
};

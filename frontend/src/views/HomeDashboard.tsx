import React, { useState } from 'react';
import { TodaySummary } from '../services/api';
import { Cigarette, Flame, Clock, TrendingUp, ShieldCheck, AlertCircle, Sparkles } from 'lucide-react';

interface HomeDashboardProps {
  summary: TodaySummary | null;
  loading: boolean;
  onOpenQuickLog: () => void;
  onOpenCraving: () => void;
  onOpenRelapseReview: () => void;
  onOpenCoach: () => void;
}

export const HomeDashboard: React.FC<HomeDashboardProps> = ({
  summary,
  loading,
  onOpenQuickLog,
  onOpenCraving,
  onOpenRelapseReview,
  onOpenCoach
}) => {
  const total = summary?.total_cigarettes ?? 0;
  const target = summary?.target_cigarettes ?? 15;
  const avoided = summary?.cigarettes_avoided ?? 0;
  const delays = summary?.successful_delays ?? 0;
  const money = summary?.money_saved_today ?? 0;
  const currency = summary?.currency_symbol ?? '₹';
  const minsAgo = summary?.minutes_since_last_cigarette;
  const nextRisk = summary?.next_high_risk_window;
  const isExceeded = total > target;

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
      {/* Relapse / Exceeded gentle reflection banner */}
      {isExceeded && (
        <div 
          onClick={onOpenRelapseReview}
          style={{
            background: 'rgba(244, 63, 94, 0.12)',
            border: '1px solid rgba(244, 63, 94, 0.3)',
            borderRadius: 16,
            padding: '12px 16px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            cursor: 'pointer'
          }}
        >
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <AlertCircle size={20} color="#FB7185" />
            <div>
              <div style={{ fontSize: 13, fontWeight: 600, color: '#FECDD3' }}>
                You smoked more than your target today
              </div>
              <div style={{ fontSize: 11, color: '#FDA4AF' }}>
                Tap to reflect on what happened. One day does not erase your progress.
              </div>
            </div>
          </div>
          <span style={{ fontSize: 12, color: '#FB7185', fontWeight: 600 }}>Review →</span>
        </div>
      )}

      {/* Main Today Status Hero Card */}
      <div className="glass-card" style={{ padding: '24px 20px', textAlign: 'center', position: 'relative' }}>
        <div style={{ fontSize: 12, fontWeight: 600, letterSpacing: '0.08em', color: 'var(--text-muted)', textTransform: 'uppercase' }}>
          TODAY'S OVERVIEW
        </div>

        <div style={{ margin: '14px 0 8px' }}>
          <span style={{ fontSize: 56, fontWeight: 800, fontFamily: 'var(--font-heading)', color: isExceeded ? '#FB7185' : 'var(--text-primary)' }}>
            {total}
          </span>
          <span style={{ fontSize: 16, color: 'var(--text-secondary)', marginLeft: 6 }}>
            cigarettes
          </span>
        </div>

        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, background: 'rgba(255, 255, 255, 0.05)', padding: '6px 14px', borderRadius: 999 }}>
          <span style={{ fontSize: 13, color: 'var(--text-secondary)' }}>Daily Target:</span>
          <strong style={{ fontSize: 14, color: '#34D399' }}>{target}</strong>
        </div>

        {/* Last cigarette elapsed timer */}
        <div style={{ marginTop: 18, paddingTop: 14, borderTop: '1px solid var(--border-subtle)', display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 8, fontSize: 13, color: 'var(--text-secondary)' }}>
          <Clock size={16} color="var(--accent-teal)" />
          {minsAgo !== null && minsAgo !== undefined ? (
            <span>
              Last cigarette: <strong>{minsAgo === 0 ? 'Just now' : `${minsAgo} min${minsAgo > 1 ? 's' : ''} ago`}</strong>
            </span>
          ) : (
            <span>No cigarettes logged yet today</span>
          )}
        </div>
      </div>

      {/* Primary Big Action Buttons */}
      <div className="hero-actions-grid">
        <button 
          id="btn-quick-log"
          className="btn-hero-log" 
          onClick={onOpenQuickLog}
        >
          <div style={{ background: 'rgba(255, 255, 255, 0.08)', padding: 12, borderRadius: '50%' }}>
            <Cigarette size={26} color="#CBD5E1" />
          </div>
          <span style={{ fontSize: 15, fontWeight: 700, letterSpacing: '0.02em' }}>
            LOG CIGARETTE
          </span>
          <span style={{ fontSize: 11, color: 'var(--text-muted)' }}>
            1-tap (2 secs)
          </span>
        </button>

        <button 
          id="btn-craving-trigger"
          className="btn-hero-craving" 
          onClick={onOpenCraving}
        >
          <div style={{ background: 'rgba(245, 158, 11, 0.25)', padding: 12, borderRadius: '50%' }}>
            <Flame size={26} color="#F59E0B" />
          </div>
          <span style={{ fontSize: 15, fontWeight: 700, letterSpacing: '0.02em' }}>
            I'M CRAVING
          </span>
          <span style={{ fontSize: 11, color: '#FDE68A' }}>
            Start 10-min delay
          </span>
        </button>
      </div>

      {/* Today's Micro-Progress Stats Grid */}
      <div className="glass-card">
        <div className="card-title">
          <span>Today's Progress</span>
          <TrendingUp size={16} color="var(--accent-teal)" />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, textAlign: 'center' }}>
          <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '12px 6px', borderRadius: 12 }}>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#34D399' }}>{avoided}</div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>Avoided</div>
          </div>

          <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '12px 6px', borderRadius: 12 }}>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#F59E0B' }}>{delays}</div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>Delays Won</div>
          </div>

          <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: '12px 6px', borderRadius: 12 }}>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#38BDF8' }}>{currency}{money}</div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 2 }}>Saved</div>
          </div>
        </div>
      </div>

      {/* High Risk Window Insight Card */}
      {nextRisk && nextRisk !== 'No data yet' && (
        <div className="glass-card" style={{ background: 'linear-gradient(135deg, rgba(6, 182, 212, 0.1), rgba(18, 30, 41, 0.75))', border: '1px solid rgba(6, 182, 212, 0.25)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ background: 'rgba(6, 182, 212, 0.2)', padding: 8, borderRadius: 10, color: '#06B6D4' }}>
              <Clock size={20} />
            </div>
            <div>
              <div style={{ fontSize: 12, color: '#38BDF8', fontWeight: 600, textTransform: 'uppercase' }}>
                High-Risk Pattern Detected
              </div>
              <div style={{ fontSize: 13, color: 'var(--text-primary)', marginTop: 2 }}>
                Your typical smoking window is around <strong>{nextRisk}</strong>.
              </div>
            </div>
          </div>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 10, lineHeight: 1.4 }}>
            Preparing cold water or stepping outside before this window begins helps you delay the first cigarette with ease.
          </p>
        </div>
      )}

      {/* AI Coach Mini Prompt Card */}
      <div 
        className="glass-card" 
        onClick={onOpenCoach}
        style={{ 
          cursor: 'pointer',
          background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.08), rgba(139, 92, 246, 0.08))',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '14px 18px'
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ background: 'rgba(16, 185, 129, 0.2)', padding: 10, borderRadius: 12, color: '#10B981' }}>
            <Sparkles size={20} />
          </div>
          <div>
            <div style={{ fontSize: 14, fontWeight: 600 }}>Talk with Coach Clarity</div>
            <div style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
              "Let's not worry about quitting right now. Let's just ride out this hour."
            </div>
          </div>
        </div>
        <span style={{ fontSize: 18, color: 'var(--text-muted)' }}>›</span>
      </div>
    </div>
  );
};

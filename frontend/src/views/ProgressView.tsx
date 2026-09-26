import React, { useState, useEffect } from 'react';
import { api, ProgressSummary, AchievementItem } from '../services/api';
import { Award, DollarSign, Heart, Shield, TrendingDown, CheckCircle, RefreshCw } from 'lucide-react';

export const ProgressView: React.FC = () => {
  const [summary, setSummary] = useState<ProgressSummary | null>(null);
  const [achievements, setAchievements] = useState<AchievementItem[]>([]);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const [sumRes, achRes] = await Promise.all([
        api.getProgressSummary(),
        api.getAchievements()
      ]);
      setSummary(sumRes);
      setAchievements(achRes);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 style={{ fontSize: 20 }}>Your Progress</h2>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)' }}>
            Every delay strengthens your autonomy and resets automatic loops.
          </p>
        </div>
        <button className="btn-ghost" onClick={loadData} title="Refresh">
          <RefreshCw size={16} />
        </button>
      </div>

      {/* Financial & Cigarettes Avoided Big Hero */}
      <div className="glass-card" style={{ background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.12), rgba(6, 182, 212, 0.12))' }}>
        <div className="card-title">
          <span>Total Smokes Spared</span>
          <Heart size={16} color="#34D399" />
        </div>

        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, margin: '8px 0' }}>
          <span style={{ fontSize: 44, fontWeight: 800, color: '#34D399', fontFamily: 'var(--font-heading)' }}>
            {summary?.total_cigarettes_avoided ?? 0}
          </span>
          <span style={{ fontSize: 14, color: 'var(--text-secondary)' }}>
            cigarettes not smoked
          </span>
        </div>

        <div style={{ 
          marginTop: 12, 
          padding: '12px 14px', 
          background: 'rgba(255, 255, 255, 0.04)', 
          borderRadius: 14, 
          display: 'flex', 
          justifyContent: 'space-between', 
          alignItems: 'center' 
        }}>
          <div>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Estimated Money Saved</div>
            <div style={{ fontSize: 20, fontWeight: 700, color: '#38BDF8', marginTop: 2 }}>
              {summary?.currency_symbol}{summary?.estimated_money_saved ?? 0}
            </div>
          </div>
          <span style={{ fontSize: 11, color: 'var(--text-muted)', fontStyle: 'italic' }}>
            Based on pack price
          </span>
        </div>
      </div>

      {/* Behavioral Stats Matrix */}
      <div className="glass-card">
        <div className="card-title">
          <span>Behavioral Milestones</span>
          <Shield size={16} color="var(--accent-teal)" />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
          <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: 14, borderRadius: 12 }}>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Baseline vs Current</div>
            <div style={{ fontSize: 18, fontWeight: 700, marginTop: 4 }}>
              {summary?.current_7day_average ?? 0} <span style={{ fontSize: 12, fontWeight: 400, color: 'var(--text-secondary)' }}>/ {summary?.baseline_cigs_per_day ?? 15} cigs</span>
            </div>
            <div style={{ fontSize: 12, color: '#34D399', marginTop: 2 }}>
              {summary?.reduction_percentage ? `${summary.reduction_percentage}% reduction` : 'Maintaining baseline'}
            </div>
          </div>

          <div style={{ background: 'rgba(255, 255, 255, 0.02)', padding: 14, borderRadius: 12 }}>
            <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Successful Delays</div>
            <div style={{ fontSize: 18, fontWeight: 700, color: '#F59E0B', marginTop: 4 }}>
              {summary?.total_successful_delays ?? 0}
            </div>
            <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>
              of {summary?.total_cravings_logged ?? 0} cravings faced
            </div>
          </div>
        </div>

        {/* Non-Toxic Goal Maintained Card (Never "Streak Lost") */}
        <div style={{ 
          marginTop: 14, 
          padding: 12, 
          borderRadius: 12, 
          background: 'rgba(255, 255, 255, 0.03)', 
          border: '1px solid var(--border-subtle)',
          fontSize: 13,
          color: '#CBD5E1'
        }}>
          🎯 You have maintained your reduction targets for <strong>{summary?.consecutive_days_with_target_maintained ?? 0} days</strong>.
        </div>
      </div>

      {/* Lightweight Positive Reinforcement Achievements */}
      <div className="glass-card">
        <div className="card-title">
          <span>Milestone Badges</span>
          <Award size={16} color="var(--accent-amber)" />
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {achievements.map(ach => (
            <div 
              key={ach.code}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 12,
                padding: '10px 14px',
                borderRadius: 12,
                background: ach.unlocked ? 'rgba(16, 185, 129, 0.08)' : 'rgba(255, 255, 255, 0.02)',
                border: `1px solid ${ach.unlocked ? 'rgba(16, 185, 129, 0.3)' : 'var(--border-subtle)'}`,
                opacity: ach.unlocked ? 1 : 0.6
              }}
            >
              <div style={{
                background: ach.unlocked ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255, 255, 255, 0.05)',
                color: ach.unlocked ? '#34D399' : 'var(--text-muted)',
                padding: 10,
                borderRadius: '50%'
              }}>
                <Award size={20} />
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: ach.unlocked ? 'var(--text-primary)' : 'var(--text-secondary)' }}>
                  {ach.title}
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>{ach.description}</div>
              </div>
              {ach.unlocked && <CheckCircle size={18} color="#34D399" />}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

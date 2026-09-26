import React, { useState, useEffect } from 'react';
import { api, SmokingClockItem, TriggerStatItem } from '../services/api';
import { Clock, PieChart, AlertTriangle, FileText, RefreshCw } from 'lucide-react';

export const AnalyticsView: React.FC = () => {
  const [clockData, setClockData] = useState<SmokingClockItem[]>([]);
  const [peakWindow, setPeakWindow] = useState<string>('');
  const [clockNote, setClockNote] = useState<string>('');

  const [triggers, setTriggers] = useState<TriggerStatItem[]>([]);
  const [triggerObs, setTriggerObs] = useState<string>('');
  const [triggerCaveat, setTriggerCaveat] = useState<string>('');

  const [weeklyReport, setWeeklyReport] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const loadData = async () => {
    setLoading(true);
    try {
      const [clockRes, trigRes, weekRes] = await Promise.all([
        api.getSmokingClock(),
        api.getTriggerAnalytics(),
        api.getWeeklyReport()
      ]);
      setClockData(clockRes.clock_data || []);
      setPeakWindow(clockRes.peak_window_label || '');
      setClockNote(clockRes.observation_note || '');

      setTriggers(trigRes.top_triggers || []);
      setTriggerObs(trigRes.primary_observation || '');
      setTriggerCaveat(trigRes.caveat_note || '');

      setWeeklyReport(weekRes);
    } catch (e) {
      console.error('Failed to load analytics', e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const maxClockCount = Math.max(...clockData.map(c => c.count), 1);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h2 style={{ fontSize: 20 }}>Behavioral Analytics</h2>
        <button className="btn-ghost" onClick={loadData} title="Refresh">
          <RefreshCw size={16} />
        </button>
      </div>

      {/* 1. Smoking Clock 24-Hour Visualization */}
      <div className="glass-card">
        <div className="card-title">
          <span>24-Hour Smoking Clock</span>
          <Clock size={16} color="var(--accent-teal)" />
        </div>

        <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>
          {clockNote}
        </p>

        {/* Hourly Distribution Bar Chart */}
        <div style={{ 
          display: 'grid', 
          gridTemplateColumns: 'repeat(12, 1fr)', 
          gap: 4, 
          height: 90, 
          alignItems: 'flex-end',
          paddingBottom: 8,
          borderBottom: '1px solid var(--border-subtle)'
        }}>
          {clockData.map(item => {
            const heightPct = Math.max(6, Math.round((item.count / maxClockCount) * 100));
            return (
              <div 
                key={item.hour}
                title={`${item.label}: ${item.count} cigarettes (${item.percentage}%)`}
                style={{ 
                  display: 'flex', 
                  flexDirection: 'column', 
                  alignItems: 'center',
                  height: '100%',
                  justifyContent: 'flex-end'
                }}
              >
                <div style={{
                  width: '100%',
                  height: `${heightPct}%`,
                  background: item.is_high_risk 
                    ? 'linear-gradient(to top, #F59E0B, #FB923C)' 
                    : item.count > 0 ? '#10B981' : 'rgba(255, 255, 255, 0.08)',
                  borderRadius: 3,
                  transition: 'height 0.3s ease'
                }} />
              </div>
            );
          })}
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--text-muted)', marginTop: 6 }}>
          <span>12 AM</span>
          <span>6 AM</span>
          <span>12 PM</span>
          <span>6 PM</span>
          <span>11 PM</span>
        </div>

        {peakWindow && (
          <div style={{ 
            marginTop: 14, 
            padding: 10, 
            borderRadius: 10, 
            background: 'rgba(245, 158, 11, 0.1)', 
            border: '1px solid rgba(245, 158, 11, 0.25)',
            fontSize: 12,
            color: '#FDE68A',
            display: 'flex',
            alignItems: 'center',
            gap: 8
          }}>
            <AlertTriangle size={16} color="#F59E0B" />
            <span>High-risk peak: <strong>{peakWindow}</strong></span>
          </div>
        )}
      </div>

      {/* 2. Trigger Breakdown */}
      <div className="glass-card">
        <div className="card-title">
          <span>Observed Circumstances & Triggers</span>
          <PieChart size={16} color="var(--accent-teal)" />
        </div>

        <div style={{ fontSize: 13, color: 'var(--text-primary)', marginBottom: 12, lineHeight: 1.5 }}>
          {triggerObs}
        </div>

        {triggers.length > 0 ? (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {triggers.map(t => (
              <div key={t.trigger}>
                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, marginBottom: 4 }}>
                  <span style={{ fontWeight: 600 }}>{t.trigger}</span>
                  <span style={{ color: 'var(--text-secondary)' }}>{t.count} times ({t.percentage}%)</span>
                </div>
                <div style={{ width: '100%', height: 6, background: 'rgba(255, 255, 255, 0.06)', borderRadius: 999, overflow: 'hidden' }}>
                  <div style={{ 
                    width: `${t.percentage}%`, 
                    height: '100%', 
                    background: 'linear-gradient(90deg, #10B981, #06B6D4)',
                    borderRadius: 999 
                  }} />
                </div>
              </div>
            ))}
          </div>
        ) : (
          <div style={{ fontSize: 13, color: 'var(--text-muted)' }}>
            No trigger logs yet. Next time you smoke or feel a craving, select an optional trigger.
          </div>
        )}

        <div style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 14, fontStyle: 'italic' }}>
          {triggerCaveat}
        </div>
      </div>

      {/* 3. Weekly AI Summary Report */}
      {weeklyReport && (
        <div className="glass-card" style={{ background: 'linear-gradient(135deg, rgba(16, 185, 129, 0.05), rgba(18, 30, 41, 0.85))' }}>
          <div className="card-title">
            <span>Weekly Behavioral Report</span>
            <FileText size={16} color="var(--accent-teal)" />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, margin: '10px 0 16px' }}>
            <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: 12, borderRadius: 12 }}>
              <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>7-Day Average</div>
              <div style={{ fontSize: 22, fontWeight: 700, color: '#34D399' }}>
                {weeklyReport.average_cigs_per_day} <span style={{ fontSize: 12, fontWeight: 400 }}>cigs/day</span>
              </div>
              <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>
                Baseline: {weeklyReport.baseline_cigs_per_day} ({weeklyReport.change_percentage > 0 ? `+${weeklyReport.change_percentage}%` : `${weeklyReport.change_percentage}%`})
              </div>
            </div>

            <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: 12, borderRadius: 12 }}>
              <div style={{ fontSize: 11, color: 'var(--text-muted)' }}>Craving Delays Won</div>
              <div style={{ fontSize: 22, fontWeight: 700, color: '#F59E0B' }}>
                {weeklyReport.successful_delays}
              </div>
              <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>
                Top trigger: {weeklyReport.most_common_trigger}
              </div>
            </div>
          </div>

          <div style={{ background: 'rgba(255, 255, 255, 0.04)', borderRadius: 12, padding: 14 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: '#34D399', textTransform: 'uppercase', marginBottom: 4 }}>
              Coach Observation
            </div>
            <p style={{ fontSize: 13, color: 'var(--text-primary)', lineHeight: 1.5 }}>
              {weeklyReport.ai_observation}
            </p>
          </div>

          <p style={{ fontSize: 11, color: 'var(--text-muted)', marginTop: 12 }}>
            {weeklyReport.disclaimer}
          </p>
        </div>
      )}
    </div>
  );
};

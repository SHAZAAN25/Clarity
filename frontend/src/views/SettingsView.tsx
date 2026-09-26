import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import { Settings as SettingsIcon, Bell, Shield, Download, Trash2, Database, LogOut } from 'lucide-react';

interface SettingsViewProps {
  onLogout: () => void;
  onDataReset: () => void;
}

export const SettingsView: React.FC<SettingsViewProps> = ({ onLogout, onDataReset }) => {
  const [settings, setSettings] = useState<any>(null);
  const [saving, setSaving] = useState(false);
  const [seeding, setSeeding] = useState(false);

  useEffect(() => {
    api.getSettings().then(setSettings).catch(console.error);
  }, []);

  const handleToggle = async (key: string, value: boolean) => {
    const updated = { ...settings, [key]: value };
    setSettings(updated);
    try {
      await api.updateSettings({ [key]: value });
    } catch (e) {
      console.error(e);
    }
  };

  const handleSeedDemoData = async () => {
    if (!window.confirm("This will load 7 days of realistic smoking patterns and craving delays to demonstrate the 24-hour smoking clock, trigger analytics, and reduction progression. Proceed?")) return;
    setSeeding(true);
    try {
      await api.seedDemoData();
      alert("Sample data loaded! Check the Home dashboard, Smoking Clock, and Progress views.");
      onDataReset();
    } catch (e: any) {
      alert(e.message || "Failed to seed demo data");
    } finally {
      setSeeding(false);
    }
  };

  const handleExportData = async () => {
    try {
      const data = await api.exportData();
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `clarity_health_data_export_${new Date().toISOString().slice(0, 10)}.json`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (e: any) {
      alert(e.message || "Failed to export data");
    }
  };

  const handleDeleteAccount = async () => {
    if (!window.confirm("Are you sure you want to permanently delete your account and all associated smoking logs? This cannot be undone.")) return;
    try {
      await api.deleteAccount();
      onLogout();
    } catch (e: any) {
      alert(e.message || "Failed to delete account");
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ background: 'rgba(255, 255, 255, 0.08)', padding: 8, borderRadius: 10 }}>
          <SettingsIcon size={20} />
        </div>
        <h2 style={{ fontSize: 20 }}>Settings & Privacy</h2>
      </div>

      {/* Notifications Controls */}
      <div className="glass-card">
        <div className="card-title">
          <span>Mindful Notification Controls</span>
          <Bell size={16} color="var(--accent-teal)" />
        </div>

        <p style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 14 }}>
          We never spam. Notifications are calm, configurable prompts to support self-awareness.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: 14, fontWeight: 500 }}>High-Risk Window Alerts</div>
              <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Gentle nudge before your usual smoking time</div>
            </div>
            <input 
              type="checkbox" 
              checked={settings?.high_risk_window_alerts ?? true}
              onChange={e => handleToggle('high_risk_window_alerts', e.target.checked)}
              style={{ width: 18, height: 18, accentColor: '#10B981', cursor: 'pointer' }}
            />
          </div>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontSize: 14, fontWeight: 500 }}>Daily Reflection Prompts</div>
              <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Evening check-in on what worked and what was hard</div>
            </div>
            <input 
              type="checkbox" 
              checked={settings?.daily_reflection_reminders ?? true}
              onChange={e => handleToggle('daily_reflection_reminders', e.target.checked)}
              style={{ width: 18, height: 18, accentColor: '#10B981', cursor: 'pointer' }}
            />
          </div>
        </div>
      </div>

      {/* Developer Demo Loader */}
      <div className="glass-card" style={{ background: 'linear-gradient(135deg, rgba(139, 92, 246, 0.1), rgba(18, 30, 41, 0.85))' }}>
        <div className="card-title">
          <span>Developer / Evaluator Mode</span>
          <Database size={16} color="#A78BFA" />
        </div>

        <p style={{ fontSize: 12, color: '#C4B5FD', marginBottom: 12, lineHeight: 1.4 }}>
          Load 7 days of realistic smoking timestamps, delay successes, and trigger correlations to explore all visual charts and algorithms immediately.
        </p>

        <button 
          className="btn-secondary" 
          style={{ width: '100%', borderColor: 'rgba(139, 92, 246, 0.3)', color: '#DDD6FE' }}
          onClick={handleSeedDemoData}
          disabled={seeding}
        >
          {seeding ? 'Generating 7-Day History...' : '⚡ Seed 7 Days of Sample History'}
        </button>
      </div>

      {/* Privacy & GDPR Data Protection */}
      <div className="glass-card">
        <div className="card-title">
          <span>Data Privacy & Rights</span>
          <Shield size={16} color="var(--accent-teal)" />
        </div>

        <p style={{ fontSize: 12, color: 'var(--text-secondary)', marginBottom: 14, lineHeight: 1.5 }}>
          Your smoking and craving patterns are sensitive health information. We never sell your data or use it for advertising.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          <button 
            className="btn-secondary" 
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8 }}
            onClick={handleExportData}
          >
            <Download size={16} />
            <span>Export My Data (JSON)</span>
          </button>

          <button 
            className="btn-secondary" 
            style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, borderColor: 'rgba(239, 68, 68, 0.3)', color: '#FCA5A5' }}
            onClick={handleDeleteAccount}
          >
            <Trash2 size={16} color="#F87171" />
            <span>Delete Account & Erase All Records</span>
          </button>
        </div>
      </div>

      {/* Sign Out Button */}
      <button 
        className="btn-ghost" 
        style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, color: 'var(--text-muted)' }}
        onClick={onLogout}
      >
        <LogOut size={16} />
        <span>Sign Out</span>
      </button>
    </div>
  );
};

import React, { useState } from 'react';
import { api } from '../services/api';
import { Check, X, Flame } from 'lucide-react';

interface QuickLogModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

export const QuickLogModal: React.FC<QuickLogModalProps> = ({ onClose, onSuccess }) => {
  const [logged, setLogged] = useState(false);
  const [logId, setLogId] = useState<string | null>(null);
  const [selectedTrigger, setSelectedTrigger] = useState<string | null>(null);
  const [selectedMood, setSelectedMood] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);

  // Fast 1-tap logging
  const handleQuickLog = async () => {
    setSaving(true);
    try {
      const res = await api.logCigarette({
        count: 1,
        is_quick_log: true
      });
      setLogId(res.id);
      setLogged(true);
      onSuccess();
    } catch (e: any) {
      alert(e.message || 'Failed to log cigarette');
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const handleUpdateDetails = async () => {
    if (selectedTrigger || selectedMood) {
      try {
        await api.logCigarette({
          count: 1,
          trigger: selectedTrigger || undefined,
          mood: selectedMood || undefined,
          is_quick_log: false
        });
      } catch (e) {
        // silently handled
      }
    }
    onSuccess();
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-sheet">
        {!logged ? (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
              <h3 style={{ fontSize: 18 }}>Log Cigarette</h3>
              <button className="btn-ghost" onClick={onClose}><X size={20} /></button>
            </div>

            <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 20 }}>
              Logging takes 2 seconds. Every log is behavioral information that helps you understand your patterns.
            </p>

            <button 
              className="btn-primary" 
              style={{ width: '100%', padding: '16px', fontSize: 16 }}
              onClick={handleQuickLog}
              disabled={saving}
            >
              <Check size={20} />
              {saving ? 'Logging...' : 'Confirm 1 Cigarette'}
            </button>

            <div style={{ textAlign: 'center', marginTop: 14 }}>
              <button 
                className="btn-ghost" 
                style={{ fontSize: 13, color: '#F59E0B' }}
                onClick={() => {
                  onClose();
                  // Trigger craving challenge if they hesitated
                  const cravingBtn = document.getElementById('btn-craving-trigger');
                  if (cravingBtn) cravingBtn.click();
                }}
              >
                Wait—Would you like to try delaying instead?
              </button>
            </div>
          </div>
        ) : (
          <div>
            <div style={{ textAlign: 'center', margin: '8px 0 16px' }}>
              <div style={{ 
                display: 'inline-flex', 
                background: 'rgba(16, 185, 129, 0.2)', 
                color: '#10B981', 
                borderRadius: '50%', 
                padding: 12, 
                marginBottom: 8 
              }}>
                <Check size={28} />
              </div>
              <h3 style={{ fontSize: 18 }}>Cigarette Logged</h3>
              <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginTop: 4 }}>
                One cigarette doesn't erase your progress. What triggered it?
              </p>
            </div>

            <div style={{ marginBottom: 14 }}>
              <label style={{ fontSize: 12, color: 'var(--text-secondary)', display: 'block', marginBottom: 8 }}>
                Optional Trigger:
              </label>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                {['Stress', 'Coffee', 'After meal', 'Work break', 'Boredom', 'Social', 'Driving', 'Habit'].map(t => (
                  <span 
                    key={t}
                    className={`chip ${selectedTrigger === t ? 'selected' : ''}`}
                    onClick={() => setSelectedTrigger(t)}
                  >
                    {t}
                  </span>
                ))}
              </div>
            </div>

            <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
              <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>
                Skip (Done)
              </button>
              <button className="btn-primary" style={{ flex: 1 }} onClick={handleUpdateDetails}>
                Save Reason
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

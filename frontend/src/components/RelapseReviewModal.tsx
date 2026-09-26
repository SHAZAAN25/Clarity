import React, { useState } from 'react';
import { api } from '../services/api';
import { ShieldAlert, X } from 'lucide-react';

interface RelapseReviewModalProps {
  onClose: () => void;
  onSuccess: () => void;
}

export const RelapseReviewModal: React.FC<RelapseReviewModalProps> = ({ onClose, onSuccess }) => {
  const [reason, setReason] = useState('Stress');
  const [action, setAction] = useState<'maintain' | 'adjust_plus_1' | 'pause'>('maintain');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      await api.handleRelapseAction(reason, action);
      onSuccess();
      onClose();
    } catch (e: any) {
      alert(e.message || 'Failed to record reflection');
      onClose();
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="modal-overlay">
      <div className="modal-sheet">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ background: 'rgba(244, 63, 94, 0.15)', padding: 8, borderRadius: 10, color: '#FB7185' }}>
              <ShieldAlert size={20} />
            </div>
            <h3 style={{ fontSize: 18 }}>Daily Target Reflection</h3>
          </div>
          <button className="btn-ghost" onClick={onClose}><X size={20} /></button>
        </div>

        <div style={{ background: 'rgba(255, 255, 255, 0.04)', borderRadius: 14, padding: 14, marginBottom: 16 }}>
          <p style={{ fontSize: 13, color: '#F1F5F9', lineHeight: 1.5 }}>
            "You smoked more than planned today. <strong>One cigarette doesn't erase your progress.</strong>"
          </p>
          <p style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 4 }}>
            Relapses provide valuable behavioral insight. What happened?
          </p>
        </div>

        <div style={{ marginBottom: 16 }}>
          <label style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'block', marginBottom: 8 }}>
            What was the biggest contributing factor?
          </label>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
            {['Stress', 'Social gathering', 'Alcohol', 'Bad day', 'Strong craving', 'Habit loop', 'Unexpected event'].map(r => (
              <span
                key={r}
                className={`chip ${reason === r ? 'selected' : ''}`}
                onClick={() => setReason(r)}
              >
                {r}
              </span>
            ))}
          </div>
        </div>

        <div style={{ marginBottom: 20 }}>
          <label style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'block', marginBottom: 8 }}>
            How would you like to handle tomorrow's target?
          </label>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {[
              { id: 'maintain', label: 'Keep current target', desc: 'Allow your routine to stabilize without pressure.' },
              { id: 'adjust_plus_1', label: 'Adjust target (+1 cigarette)', desc: 'Temporarily give yourself breathing room.' },
              { id: 'pause', label: 'Pause reduction for now', desc: 'Focus purely on tracking and delay practice.' }
            ].map(opt => (
              <div
                key={opt.id}
                onClick={() => setAction(opt.id as any)}
                style={{
                  padding: 12,
                  borderRadius: 12,
                  background: action === opt.id ? 'rgba(16, 185, 129, 0.15)' : 'rgba(255, 255, 255, 0.03)',
                  border: `1px solid ${action === opt.id ? 'var(--accent-teal)' : 'var(--border-subtle)'}`,
                  cursor: 'pointer'
                }}
              >
                <div style={{ fontSize: 13, fontWeight: 600, color: action === opt.id ? '#34D399' : 'var(--text-primary)' }}>
                  {opt.label}
                </div>
                <div style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>{opt.desc}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ display: 'flex', gap: 10 }}>
          <button className="btn-secondary" style={{ flex: 1 }} onClick={onClose}>Dismiss</button>
          <button className="btn-primary" style={{ flex: 1 }} onClick={handleSave} disabled={saving}>
            {saving ? 'Saving...' : 'Save Decision'}
          </button>
        </div>
      </div>
    </div>
  );
};

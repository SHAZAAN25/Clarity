import React, { useState } from 'react';
import { api } from '../services/api';
import { Sparkles, Shield, Heart, DollarSign, Users, Award, Smile } from 'lucide-react';

interface OnboardingModalProps {
  onComplete: () => void;
}

export const OnboardingModal: React.FC<OnboardingModalProps> = ({ onComplete }) => {
  const [step, setStep] = useState(1);
  const [baselineCigs, setBaselineCigs] = useState(15);
  const [costPerPack, setCostPerPack] = useState(15);
  const [cigsPerPack, setCigsPerPack] = useState(20);
  const [yearsSmoking, setYearsSmoking] = useState(5);
  const [firstCigMins, setFirstCigMins] = useState(30);
  const [goal, setGoal] = useState('reduce');
  const [motivations, setMotivations] = useState<string[]>(['health', 'money']);
  const [triggers, setTriggers] = useState<string[]>(['stress', 'coffee']);
  const [loading, setLoading] = useState(false);

  const toggleMotivation = (key: string) => {
    setMotivations(prev => 
      prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key]
    );
  };

  const toggleTrigger = (key: string) => {
    setTriggers(prev => 
      prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key]
    );
  };

  const handleFinish = async () => {
    setLoading(true);
    try {
      await api.completeOnboarding({
        baseline_cigs_per_day: baselineCigs,
        cost_per_pack: costPerPack,
        cigs_per_pack: cigsPerPack,
        years_smoking: yearsSmoking,
        first_cig_after_waking_mins: firstCigMins,
        goal,
        motivations,
        common_triggers: triggers
      });
      onComplete();
    } catch (e: any) {
      alert(e.message || 'Failed to complete onboarding');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="modal-overlay" style={{ alignItems: 'center' }}>
      <div className="modal-sheet" style={{ maxWidth: 440 }}>
        {step === 1 && (
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
              <div style={{ background: 'rgba(16, 185, 129, 0.2)', padding: 10, borderRadius: 12, color: '#10B981' }}>
                <Sparkles size={24} />
              </div>
              <div>
                <h2 style={{ fontSize: 20 }}>Welcome to Clarity</h2>
                <p style={{ fontSize: 13, color: 'var(--text-secondary)' }}>A thoughtful, non-judgmental smoking reduction coach.</p>
              </div>
            </div>

            <div style={{ background: 'rgba(255, 255, 255, 0.04)', borderRadius: 14, padding: 14, margin: '16px 0', border: '1px solid var(--border-subtle)' }}>
              <p style={{ fontSize: 13, color: '#94A3B8', lineHeight: 1.6 }}>
                "Don't just count cigarettes. Understand why you smoke them."<br />
                We never shame you or punish relapses. You stay in control.
              </p>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'block', marginBottom: 6 }}>
                  Average cigarettes you smoke per day
                </label>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <input 
                    type="range" 
                    min="1" 
                    max="60" 
                    value={baselineCigs} 
                    onChange={e => setBaselineCigs(Number(e.target.value))} 
                    style={{ flex: 1 }}
                  />
                  <span style={{ fontSize: 18, fontWeight: 700, width: 44, textAlign: 'right', color: '#10B981' }}>
                    {baselineCigs}
                  </span>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
                <div>
                  <label style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Price per pack (₹ / $)</label>
                  <input 
                    type="number" 
                    value={costPerPack} 
                    onChange={e => setCostPerPack(Number(e.target.value))} 
                    style={{ width: '100%', marginTop: 4 }}
                  />
                </div>
                <div>
                  <label style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Cigarettes per pack</label>
                  <input 
                    type="number" 
                    value={cigsPerPack} 
                    onChange={e => setCigsPerPack(Number(e.target.value))} 
                    style={{ width: '100%', marginTop: 4 }}
                  />
                </div>
              </div>

              <div>
                <label style={{ fontSize: 12, color: 'var(--text-secondary)' }}>How soon after waking do you smoke?</label>
                <select 
                  value={firstCigMins} 
                  onChange={e => setFirstCigMins(Number(e.target.value))}
                  style={{ width: '100%', marginTop: 4 }}
                >
                  <option value={5}>Within 5 minutes</option>
                  <option value={15}>Within 15 minutes</option>
                  <option value={30}>Within 30 minutes</option>
                  <option value={60}>After 1 hour or more</option>
                </select>
              </div>
            </div>

            <button 
              className="btn-primary" 
              style={{ width: '100%', marginTop: 24 }}
              onClick={() => setStep(2)}
            >
              Next: What's your goal? →
            </button>
          </div>
        )}

        {step === 2 && (
          <div>
            <h2 style={{ fontSize: 20, marginBottom: 6 }}>Your Current Goal</h2>
            <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>
              You don't need to quit immediately. Choose what feels right today.
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                { id: 'reduce', title: 'Gradual Reduction', desc: 'Lower cigarettes step-by-step with mindful delay challenges.' },
                { id: 'quit_eventually', title: 'Quit Eventually', desc: 'Reduce consumption now with the aim to stop when ready.' },
                { id: 'quit_asap', title: 'Quit as soon as possible', desc: 'Aggressive tapering and behavioral intervention.' },
                { id: 'not_sure', title: 'Not sure yet (Observation)', desc: 'Just learn my patterns and baseline without pressure.' }
              ].map(opt => (
                <div 
                  key={opt.id}
                  onClick={() => setGoal(opt.id)}
                  style={{
                    padding: '12px 16px',
                    borderRadius: 14,
                    background: goal === opt.id ? 'rgba(16, 185, 129, 0.15)' : 'rgba(255, 255, 255, 0.03)',
                    border: `1px solid ${goal === opt.id ? 'var(--accent-teal)' : 'var(--border-subtle)'}`,
                    cursor: 'pointer'
                  }}
                >
                  <div style={{ fontWeight: 600, fontSize: 14, color: goal === opt.id ? '#34D399' : 'var(--text-primary)' }}>
                    {opt.title}
                  </div>
                  <div style={{ fontSize: 12, color: 'var(--text-secondary)', marginTop: 2 }}>{opt.desc}</div>
                </div>
              ))}
            </div>

            <div style={{ display: 'flex', gap: 10, marginTop: 24 }}>
              <button className="btn-secondary" style={{ flex: 1 }} onClick={() => setStep(1)}>Back</button>
              <button className="btn-primary" style={{ flex: 2 }} onClick={() => setStep(3)}>Next: Motivations →</button>
            </div>
          </div>
        )}

        {step === 3 && (
          <div>
            <h2 style={{ fontSize: 20, marginBottom: 6 }}>Motivations & Triggers</h2>
            <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 14 }}>
              Select what drives you and situations where cravings commonly appear.
            </p>

            <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              Your Motivations
            </label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, margin: '8px 0 16px' }}>
              {[
                { id: 'health', label: 'Health & Lungs' },
                { id: 'money', label: 'Save Money' },
                { id: 'family', label: 'Family & Kids' },
                { id: 'fitness', label: 'Fitness & Energy' },
                { id: 'control', label: 'Self Control' },
                { id: 'smell', label: 'Fresh Breath / Smell' }
              ].map(m => (
                <span 
                  key={m.id}
                  className={`chip ${motivations.includes(m.id) ? 'selected' : ''}`}
                  onClick={() => toggleMotivation(m.id)}
                >
                  {m.label}
                </span>
              ))}
            </div>

            <label style={{ fontSize: 12, fontWeight: 600, color: 'var(--text-secondary)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              Common Triggers
            </label>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, margin: '8px 0 20px' }}>
              {[
                'Stress', 'Coffee', 'After meals', 'Work breaks', 'Alcohol', 'Driving', 'Boredom', 'Social', 'Gaming'
              ].map(t => (
                <span 
                  key={t}
                  className={`chip ${triggers.includes(t.toLowerCase()) ? 'selected' : ''}`}
                  onClick={() => toggleTrigger(t.toLowerCase())}
                >
                  {t}
                </span>
              ))}
            </div>

            <div style={{ display: 'flex', gap: 10 }}>
              <button className="btn-secondary" style={{ flex: 1 }} onClick={() => setStep(2)}>Back</button>
              <button 
                className="btn-primary" 
                style={{ flex: 2 }} 
                onClick={handleFinish}
                disabled={loading}
              >
                {loading ? 'Setting up...' : 'Start My Journey 🚀'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

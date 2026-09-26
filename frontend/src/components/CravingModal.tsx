import React, { useState, useEffect } from 'react';
import { api } from '../services/api';
import confetti from 'canvas-confetti';
import { Flame, X, Wind, Droplets, Footprints, Activity, Sparkles, CheckCircle2 } from 'lucide-react';

interface CravingModalProps {
  initialDelayMins?: number;
  onClose: () => void;
  onSuccess: () => void;
  onOpenCoach: () => void;
}

export const CravingModal: React.FC<CravingModalProps> = ({ 
  initialDelayMins = 10, 
  onClose, 
  onSuccess,
  onOpenCoach 
}) => {
  const [phase, setPhase] = useState<'assess' | 'countdown' | 'breathing' | 'grounding' | 'result'>('assess');
  const [intensity, setIntensity] = useState<number>(3);
  const [trigger, setTrigger] = useState<string>('Stress');
  const [cravingId, setCravingId] = useState<string | null>(null);

  // Timer states
  const totalSeconds = initialDelayMins * 60;
  const [secondsRemaining, setSecondsRemaining] = useState<number>(totalSeconds);
  const [timerActive, setTimerActive] = useState(false);

  // Breathing exercise states
  const [breathPhase, setBreathPhase] = useState<'Inhale' | 'Hold' | 'Exhale'>('Inhale');
  const [breathCount, setBreathCount] = useState(4);

  // Result check-in
  const [postFeeling, setPostFeeling] = useState<string>('weaker');
  const [didSmoke, setDidSmoke] = useState<boolean>(false);
  const [savingResult, setSavingResult] = useState(false);

  // Start craving session
  const handleStartDelay = async () => {
    try {
      const res = await api.startCraving(intensity, trigger);
      setCravingId(res.id);
      setPhase('countdown');
      setTimerActive(true);
    } catch (e: any) {
      alert(e.message || 'Failed to start craving timer');
    }
  };

  // Countdown effect
  useEffect(() => {
    let interval: any = null;
    if (timerActive && secondsRemaining > 0) {
      interval = setInterval(() => {
        setSecondsRemaining(prev => prev - 1);
      }, 1000);
    } else if (timerActive && secondsRemaining === 0) {
      setTimerActive(false);
      setPhase('result');
      confetti({ particleCount: 60, spread: 60, origin: { y: 0.7 } });
    }
    return () => clearInterval(interval);
  }, [timerActive, secondsRemaining]);

  // Breathing exercise animation loop
  useEffect(() => {
    if (phase !== 'breathing') return;
    const interval = setInterval(() => {
      setBreathCount(prev => {
        if (prev <= 1) {
          setBreathPhase(current => {
            if (current === 'Inhale') return 'Hold';
            if (current === 'Hold') return 'Exhale';
            return 'Inhale';
          });
          return 4;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(interval);
  }, [phase]);

  const handleRecordIntervention = async (type: string) => {
    if (cravingId) {
      try {
        await api.recordIntervention(cravingId, type, 60, true);
      } catch (e) {}
    }
  };

  const handleCompleteFlow = async (smoked: boolean) => {
    setSavingResult(true);
    const delayedSecs = totalSeconds - secondsRemaining;
    try {
      if (cravingId) {
        await api.completeCraving(cravingId, smoked, postFeeling, delayedSecs, trigger);
      }
      if (!smoked) {
        confetti({ particleCount: 100, spread: 70, origin: { y: 0.6 } });
      }
      onSuccess();
      onClose();
    } catch (e: any) {
      alert(e.message || 'Could not record outcome');
      onClose();
    } finally {
      setSavingResult(false);
    }
  };

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  };

  return (
    <div className="modal-overlay">
      <div className="modal-sheet">
        {/* Phase 1: Assessment */}
        {phase === 'assess' && (
          <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <div style={{ background: 'rgba(245, 158, 11, 0.2)', padding: 8, borderRadius: 10, color: '#F59E0B' }}>
                  <Flame size={22} />
                </div>
                <h3 style={{ fontSize: 18 }}>Craving Intervention</h3>
              </div>
              <button className="btn-ghost" onClick={onClose}><X size={20} /></button>
            </div>

            <div style={{ background: 'rgba(245, 158, 11, 0.08)', borderRadius: 12, padding: 12, marginBottom: 16, border: '1px solid rgba(245, 158, 11, 0.2)' }}>
              <p style={{ fontSize: 13, color: '#FDE68A', lineHeight: 1.5 }}>
                "You don't have to decide whether you'll quit forever right now.<br />
                Just try waiting <strong>{initialDelayMins} minutes</strong>."
              </p>
            </div>

            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'block', marginBottom: 8 }}>
                How strong is this craving?
              </label>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
                {[
                  { level: 1, label: 'Mild' },
                  { level: 2, label: 'Moderate' },
                  { level: 3, label: 'Strong' },
                  { level: 4, label: 'Very Strong' }
                ].map(item => (
                  <button
                    key={item.level}
                    type="button"
                    onClick={() => setIntensity(item.level)}
                    style={{
                      padding: '10px 4px',
                      borderRadius: 10,
                      background: intensity === item.level ? 'rgba(245, 158, 11, 0.25)' : 'rgba(255, 255, 255, 0.04)',
                      border: `1px solid ${intensity === item.level ? '#F59E0B' : 'var(--border-subtle)'}`,
                      color: intensity === item.level ? '#FDE68A' : 'var(--text-secondary)',
                      fontSize: 12,
                      fontWeight: 600
                    }}
                  >
                    {item.label}
                  </button>
                ))}
              </div>
            </div>

            <div style={{ marginBottom: 20 }}>
              <label style={{ fontSize: 13, color: 'var(--text-secondary)', display: 'block', marginBottom: 8 }}>
                What triggered this urge?
              </label>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                {['Stress', 'Coffee', 'After meal', 'Work break', 'Boredom', 'Social', 'Alcohol', 'Habit'].map(t => (
                  <span
                    key={t}
                    className={`chip ${trigger === t ? 'selected' : ''}`}
                    onClick={() => setTrigger(t)}
                  >
                    {t}
                  </span>
                ))}
              </div>
            </div>

            <button 
              className="btn-primary" 
              style={{ width: '100%', background: 'linear-gradient(135deg, #F59E0B, #EA580C)' }}
              onClick={handleStartDelay}
            >
              Start {initialDelayMins}-Minute Delay Challenge ⏳
            </button>
          </div>
        )}

        {/* Phase 2: Countdown Challenge */}
        {phase === 'countdown' && (
          <div style={{ textAlign: 'center' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
              <span style={{ fontSize: 12, color: '#F59E0B', fontWeight: 600, textTransform: 'uppercase' }}>
                Delay Challenge in Progress
              </span>
              <button className="btn-ghost" onClick={() => setPhase('result')}>End Early</button>
            </div>

            {/* Circular Timer Visual */}
            <div style={{ margin: '20px 0' }}>
              <div style={{
                width: 170,
                height: 170,
                borderRadius: '50%',
                margin: '0 auto',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'radial-gradient(circle, rgba(245, 158, 11, 0.12), rgba(17, 27, 36, 0.9))',
                border: '3px solid rgba(245, 158, 11, 0.4)',
                boxShadow: '0 0 35px rgba(245, 158, 11, 0.25)'
              }}>
                <span style={{ fontSize: 36, fontWeight: 700, fontFamily: 'var(--font-heading)', color: '#FDE68A' }}>
                  {formatTime(secondsRemaining)}
                </span>
                <span style={{ fontSize: 11, color: 'var(--text-secondary)', marginTop: 2 }}>
                  Cravings crest in 3-5 mins
                </span>
              </div>
            </div>

            <p style={{ fontSize: 13, color: '#94A3B8', marginBottom: 16 }}>
              Most cravings peak like a wave and then begin dropping. Pick an intervention to ride it out:
            </p>

            {/* Interventions Grid */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginBottom: 18 }}>
              <button 
                className="btn-secondary" 
                style={{ display: 'flex', alignItems: 'center', gap: 8, padding: 12 }}
                onClick={() => {
                  handleRecordIntervention('breathing');
                  setPhase('breathing');
                }}
              >
                <Wind size={18} color="#10B981" />
                <span>4-4-4 Breathing</span>
              </button>

              <button 
                className="btn-secondary" 
                style={{ display: 'flex', alignItems: 'center', gap: 8, padding: 12 }}
                onClick={() => {
                  handleRecordIntervention('water');
                  alert('💧 Drink a tall, cold glass of water slowly. Notice the physical sensation.');
                }}
              >
                <Droplets size={18} color="#06B6D4" />
                <span>Drink Cold Water</span>
              </button>

              <button 
                className="btn-secondary" 
                style={{ display: 'flex', alignItems: 'center', gap: 8, padding: 12 }}
                onClick={() => {
                  handleRecordIntervention('grounding');
                  setPhase('grounding');
                }}
              >
                <Activity size={18} color="#8B5CF6" />
                <span>5-4-3-2-1 Sensory</span>
              </button>

              <button 
                className="btn-secondary" 
                style={{ display: 'flex', alignItems: 'center', gap: 8, padding: 12 }}
                onClick={() => {
                  handleRecordIntervention('ai_coach');
                  onClose();
                  onOpenCoach();
                }}
              >
                <Sparkles size={18} color="#F59E0B" />
                <span>Talk to AI Coach</span>
              </button>
            </div>

            <button 
              className="btn-ghost" 
              style={{ color: 'var(--text-muted)', fontSize: 13 }}
              onClick={() => setPhase('result')}
            >
              I'm ready to check in now
            </button>
          </div>
        )}

        {/* Phase 3: Interactive 4-4-4 Breathing Circle */}
        {phase === 'breathing' && (
          <div style={{ textAlign: 'center', padding: '10px 0' }}>
            <h3 style={{ fontSize: 18, marginBottom: 6 }}>Mindful Breathing</h3>
            <p style={{ fontSize: 13, color: 'var(--text-secondary)' }}>
              Deep, slow breathing triggers your parasympathetic system to reduce urge tension.
            </p>

            <div className="breathing-orb">
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 20, fontWeight: 700 }}>{breathPhase}</div>
                <div style={{ fontSize: 24, fontWeight: 800 }}>{breathCount}</div>
              </div>
            </div>

            <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 20 }}>
              Notice the air moving in and out of your lungs. This is not medical treatment; it is a grounding exercise.
            </p>

            <button className="btn-secondary" onClick={() => setPhase('countdown')}>
              Back to Countdown ({formatTime(secondsRemaining)})
            </button>
          </div>
        )}

        {/* Phase 4: Grounding Exercise */}
        {phase === 'grounding' && (
          <div>
            <h3 style={{ fontSize: 18, marginBottom: 8 }}>5-4-3-2-1 Grounding</h3>
            <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 14 }}>
              Engage your sensory cortex to disrupt automatic smoking loops:
            </p>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 10, fontSize: 13, color: '#CBD5E1' }}>
              <div style={{ padding: 10, background: 'rgba(255,255,255,0.04)', borderRadius: 10 }}>
                👁️ <strong>5 Things you see:</strong> Look around the room and name 5 distinct objects.
              </div>
              <div style={{ padding: 10, background: 'rgba(255,255,255,0.04)', borderRadius: 10 }}>
                ✋ <strong>4 Things you feel:</strong> The chair against your back, your feet on the floor.
              </div>
              <div style={{ padding: 10, background: 'rgba(255,255,255,0.04)', borderRadius: 10 }}>
                👂 <strong>3 Things you hear:</strong> Ambient sounds, distant traffic, your breath.
              </div>
              <div style={{ padding: 10, background: 'rgba(255,255,255,0.04)', borderRadius: 10 }}>
                👃 <strong>2 Things you smell:</strong> Coffee, fresh air, clothing.
              </div>
              <div style={{ padding: 10, background: 'rgba(255,255,255,0.04)', borderRadius: 10 }}>
                👅 <strong>1 Thing you taste:</strong> Water, mint, or saliva.
              </div>
            </div>

            <button 
              className="btn-primary" 
              style={{ width: '100%', marginTop: 20 }}
              onClick={() => setPhase('countdown')}
            >
              Return to Timer
            </button>
          </div>
        )}

        {/* Phase 5: Post-Timer Result & Check-in */}
        {phase === 'result' && (
          <div>
            <h3 style={{ fontSize: 18, marginBottom: 6 }}>How do you feel now?</h3>
            <p style={{ fontSize: 13, color: 'var(--text-secondary)', marginBottom: 16 }}>
              Checking in helps the app adapt your future delay suggestions.
            </p>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 18 }}>
              {[
                { id: 'gone', label: 'Craving Gone' },
                { id: 'weaker', label: 'Craving Weaker' },
                { id: 'same', label: 'About the Same' },
                { id: 'stronger', label: 'Still Strong' }
              ].map(f => (
                <button
                  key={f.id}
                  type="button"
                  onClick={() => setPostFeeling(f.id)}
                  style={{
                    padding: 12,
                    borderRadius: 12,
                    background: postFeeling === f.id ? 'rgba(16, 185, 129, 0.2)' : 'rgba(255,255,255,0.04)',
                    border: `1px solid ${postFeeling === f.id ? '#10B981' : 'var(--border-subtle)'}`,
                    color: postFeeling === f.id ? '#34D399' : 'var(--text-primary)',
                    fontSize: 13,
                    fontWeight: 600
                  }}
                >
                  {f.label}
                </button>
              ))}
            </div>

            <div style={{ borderTop: '1px solid var(--border-subtle)', paddingTop: 16, marginBottom: 18 }}>
              <label style={{ fontSize: 14, fontWeight: 600, display: 'block', marginBottom: 10 }}>
                Did you smoke during or after the delay?
              </label>

              <div style={{ display: 'flex', gap: 12 }}>
                <button
                  type="button"
                  className="btn-primary"
                  style={{ flex: 1, padding: 14 }}
                  onClick={() => handleCompleteFlow(false)}
                  disabled={savingResult}
                >
                  🎉 No, I Delayed It!
                </button>

                <button
                  type="button"
                  className="btn-secondary"
                  style={{ flex: 1, padding: 14 }}
                  onClick={() => handleCompleteFlow(true)}
                  disabled={savingResult}
                >
                  Yes, I Smoked
                </button>
              </div>
            </div>

            <p style={{ fontSize: 12, color: 'var(--text-muted)', textAlign: 'center', lineHeight: 1.4 }}>
              Even if you smoked, delaying by a few minutes weakens the automatic habit loop.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

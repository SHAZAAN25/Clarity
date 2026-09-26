import React, { useState } from 'react';
import { api } from '../services/api';
import { Sparkles, Shield, Lock, Mail, User } from 'lucide-react';

interface AuthViewProps {
  onAuthSuccess: (onboarded: boolean) => void;
}

export const AuthView: React.FC<AuthViewProps> = ({ onAuthSuccess }) => {
  const [isLogin, setIsLogin] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      if (isLogin) {
        const res = await api.login(email, password);
        onAuthSuccess(res.onboarding_completed);
      } else {
        const res = await api.register(email, password, fullName || undefined);
        onAuthSuccess(false); // New registrations always do onboarding
      }
    } catch (err: any) {
      setError(err.message || 'Authentication failed. Please verify credentials.');
    } finally {
      setLoading(false);
    }
  };

  // Quick Demo Login helper for immediate testing
  const handleQuickDemo = async () => {
    setEmail('demo.user@clarity.health');
    setPassword('ClarityPassword123!');
    setFullName('Demo Smoker');
    setLoading(true);
    try {
      // Try login, if fails, register
      try {
        const res = await api.login('demo.user@clarity.health', 'ClarityPassword123!');
        onAuthSuccess(res.onboarding_completed);
      } catch {
        const res = await api.register('demo.user@clarity.health', 'ClarityPassword123!', 'Demo Smoker');
        onAuthSuccess(false);
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ 
      display: 'flex', 
      flexDirection: 'column', 
      justifyContent: 'center', 
      minHeight: '100%', 
      padding: '24px 12px' 
    }}>
      <div style={{ textAlign: 'center', marginBottom: 28 }}>
        <div style={{ 
          display: 'inline-flex', 
          background: 'radial-gradient(circle, rgba(16, 185, 129, 0.25), rgba(6, 182, 212, 0.05))', 
          padding: 16, 
          borderRadius: 24, 
          marginBottom: 12,
          border: '1px solid rgba(16, 185, 129, 0.3)'
        }}>
          <Sparkles size={36} color="#10B981" />
        </div>
        <h1 style={{ fontSize: 28, fontWeight: 700 }}>Clarity</h1>
        <p style={{ fontSize: 14, color: 'var(--text-secondary)', marginTop: 4 }}>
          AI Smoking Reduction & Cessation Coach
        </p>
        <p style={{ fontSize: 12, color: 'var(--text-muted)', marginTop: 2 }}>
          "Don't just count cigarettes. Understand why you smoke them."
        </p>
      </div>

      <div className="glass-card" style={{ padding: '24px 20px' }}>
        <div style={{ display: 'flex', borderBottom: '1px solid var(--border-subtle)', marginBottom: 20 }}>
          <button
            type="button"
            onClick={() => { setIsLogin(false); setError(null); }}
            style={{
              flex: 1,
              padding: '10px 0',
              background: 'transparent',
              color: !isLogin ? '#10B981' : 'var(--text-muted)',
              fontWeight: 600,
              fontSize: 14,
              borderBottom: !isLogin ? '2px solid #10B981' : 'none'
            }}
          >
            Create Account
          </button>
          <button
            type="button"
            onClick={() => { setIsLogin(true); setError(null); }}
            style={{
              flex: 1,
              padding: '10px 0',
              background: 'transparent',
              color: isLogin ? '#10B981' : 'var(--text-muted)',
              fontWeight: 600,
              fontSize: 14,
              borderBottom: isLogin ? '2px solid #10B981' : 'none'
            }}
          >
            Sign In
          </button>
        </div>

        {error && (
          <div style={{ 
            background: 'rgba(239, 68, 68, 0.15)', 
            border: '1px solid rgba(239, 68, 68, 0.3)', 
            color: '#FCA5A5', 
            borderRadius: 10, 
            padding: '10px 12px', 
            fontSize: 13, 
            marginBottom: 16 
          }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {!isLogin && (
            <div>
              <label style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Full Name (Optional)</label>
              <input 
                type="text" 
                value={fullName} 
                onChange={e => setFullName(e.target.value)}
                placeholder="Alex Morgan" 
                style={{ width: '100%', marginTop: 4 }}
              />
            </div>
          )}

          <div>
            <label style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Email Address</label>
            <input 
              type="email" 
              required 
              value={email} 
              onChange={e => setEmail(e.target.value)}
              placeholder="you@example.com" 
              style={{ width: '100%', marginTop: 4 }}
            />
          </div>

          <div>
            <label style={{ fontSize: 12, color: 'var(--text-secondary)' }}>Password (Min 8 characters)</label>
            <input 
              type="password" 
              required 
              minLength={8}
              value={password} 
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••" 
              style={{ width: '100%', marginTop: 4 }}
            />
          </div>

          <button 
            type="submit" 
            className="btn-primary" 
            style={{ width: '100%', marginTop: 8 }}
            disabled={loading}
          >
            {loading ? 'Please wait...' : (isLogin ? 'Sign In to Clarity' : 'Create Free Account')}
          </button>
        </form>

        <div style={{ marginTop: 18, paddingTop: 14, borderTop: '1px solid var(--border-subtle)', textAlign: 'center' }}>
          <button 
            className="btn-ghost" 
            style={{ fontSize: 13, color: '#38BDF8' }}
            onClick={handleQuickDemo}
            disabled={loading}
          >
            ⚡ Quick 1-Click Demo Account
          </button>
        </div>
      </div>

      <div style={{ textAlign: 'center', marginTop: 20, fontSize: 12, color: 'var(--text-muted)' }}>
        🛡️ End-to-end encrypted • Sensitive personal health data never shared
      </div>
    </div>
  );
};

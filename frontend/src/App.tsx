import React, { useState, useEffect } from 'react';
import { api, TodaySummary } from './services/api';
import { HomeDashboard } from './views/HomeDashboard';
import { AnalyticsView } from './views/AnalyticsView';
import { AICoachView } from './views/AICoachView';
import { HealthLibraryView } from './views/HealthLibraryView';
import { ProgressView } from './views/ProgressView';
import { SettingsView } from './views/SettingsView';
import { AuthView } from './views/AuthView';
import { OnboardingModal } from './components/OnboardingModal';
import { QuickLogModal } from './components/QuickLogModal';
import { CravingModal } from './components/CravingModal';
import { RelapseReviewModal } from './components/RelapseReviewModal';
import { 
  Home, 
  BarChart2, 
  MessageSquare, 
  BookOpen, 
  Award, 
  Settings as SettingsIcon,
  Sparkles,
  WifiOff
} from 'lucide-react';

export function App() {
  const [token, setToken] = useState<string | null>(api.getToken());
  const [needsOnboarding, setNeedsOnboarding] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<'home' | 'analytics' | 'coach' | 'health' | 'progress' | 'settings'>('home');
  const [todaySummary, setTodaySummary] = useState<TodaySummary | null>(null);
  const [loadingSummary, setLoadingSummary] = useState<boolean>(false);
  const [isOffline, setIsOffline] = useState<boolean>(!navigator.onLine);

  // Modals
  const [showQuickLog, setShowQuickLog] = useState(false);
  const [showCraving, setShowCraving] = useState(false);
  const [showRelapseReview, setShowRelapseReview] = useState(false);

  // Online / Offline monitor
  useEffect(() => {
    const handleOnline = () => {
      setIsOffline(false);
      api.flushOfflineQueue();
    };
    const handleOffline = () => setIsOffline(true);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const refreshSummary = async () => {
    if (!token) return;
    setLoadingSummary(true);
    try {
      const data = await api.getTodaySummary();
      setTodaySummary(data);
    } catch (err: any) {
      console.warn('Could not fetch today summary', err);
    } finally {
      setLoadingSummary(false);
    }
  };

  useEffect(() => {
    if (token) {
      api.getProfile().then(profile => {
        if (!profile.onboarding_completed) {
          setNeedsOnboarding(true);
        } else {
          refreshSummary();
        }
      }).catch(() => {
        // Fallback or expired token
      });
    }
  }, [token]);

  const handleAuthSuccess = (onboarded: boolean) => {
    setToken(api.getToken());
    if (!onboarded) {
      setNeedsOnboarding(true);
    } else {
      refreshSummary();
    }
  };

  const handleLogout = () => {
    api.clearToken();
    setToken(null);
    setTodaySummary(null);
  };

  // If user is not authenticated, render AuthView
  if (!token) {
    return (
      <div className="app-container">
        <main className="mobile-shell">
          <AuthView onAuthSuccess={handleAuthSuccess} />
        </main>
      </div>
    );
  }

  return (
    <div className="app-container">
      <main className="mobile-shell">
        {/* Top Header */}
        <header className="app-header">
          <div className="brand-badge">
            <Sparkles size={20} color="#10B981" />
            <span>Clarity</span>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {isOffline && (
              <div style={{ display: 'flex', alignItems: 'center', gap: 4, background: 'rgba(239, 68, 68, 0.2)', color: '#F87171', padding: '4px 8px', borderRadius: 8, fontSize: 11 }}>
                <WifiOff size={14} />
                <span>Offline mode (Queued)</span>
              </div>
            )}
            <button 
              className="btn-ghost" 
              onClick={() => setActiveTab('settings')}
              title="Settings & Privacy"
            >
              <SettingsIcon size={18} />
            </button>
          </div>
        </header>

        {/* Dynamic View Content */}
        <div className="app-content">
          {activeTab === 'home' && (
            <HomeDashboard 
              summary={todaySummary}
              loading={loadingSummary}
              onOpenQuickLog={() => setShowQuickLog(true)}
              onOpenCraving={() => setShowCraving(true)}
              onOpenRelapseReview={() => setShowRelapseReview(true)}
              onOpenCoach={() => setActiveTab('coach')}
            />
          )}

          {activeTab === 'analytics' && <AnalyticsView />}

          {activeTab === 'coach' && (
            <AICoachView onOpenCraving={() => setShowCraving(true)} />
          )}

          {activeTab === 'health' && <HealthLibraryView />}

          {activeTab === 'progress' && <ProgressView />}

          {activeTab === 'settings' && (
            <SettingsView 
              onLogout={handleLogout} 
              onDataReset={() => {
                refreshSummary();
                setActiveTab('home');
              }} 
            />
          )}
        </div>

        {/* Bottom Mobile Navigation */}
        <nav className="bottom-nav">
          <button 
            className={`nav-item ${activeTab === 'home' ? 'active' : ''}`}
            onClick={() => setActiveTab('home')}
          >
            <div className="nav-icon-wrapper"><Home size={20} /></div>
            <span>Today</span>
          </button>

          <button 
            className={`nav-item ${activeTab === 'analytics' ? 'active' : ''}`}
            onClick={() => setActiveTab('analytics')}
          >
            <div className="nav-icon-wrapper"><BarChart2 size={20} /></div>
            <span>Patterns</span>
          </button>

          <button 
            className={`nav-item ${activeTab === 'coach' ? 'active' : ''}`}
            onClick={() => setActiveTab('coach')}
          >
            <div className="nav-icon-wrapper"><MessageSquare size={20} /></div>
            <span>AI Coach</span>
          </button>

          <button 
            className={`nav-item ${activeTab === 'health' ? 'active' : ''}`}
            onClick={() => setActiveTab('health')}
          >
            <div className="nav-icon-wrapper"><BookOpen size={20} /></div>
            <span>Health</span>
          </button>

          <button 
            className={`nav-item ${activeTab === 'progress' ? 'active' : ''}`}
            onClick={() => setActiveTab('progress')}
          >
            <div className="nav-icon-wrapper"><Award size={20} /></div>
            <span>Progress</span>
          </button>
        </nav>

        {/* Modal Flows */}
        {needsOnboarding && (
          <OnboardingModal 
            onComplete={() => {
              setNeedsOnboarding(false);
              refreshSummary();
            }} 
          />
        )}

        {showQuickLog && (
          <QuickLogModal 
            onClose={() => setShowQuickLog(false)}
            onSuccess={refreshSummary}
          />
        )}

        {showCraving && (
          <CravingModal 
            initialDelayMins={10}
            onClose={() => setShowCraving(false)}
            onSuccess={refreshSummary}
            onOpenCoach={() => {
              setShowCraving(false);
              setActiveTab('coach');
            }}
          />
        )}

        {showRelapseReview && (
          <RelapseReviewModal 
            onClose={() => setShowRelapseReview(false)}
            onSuccess={refreshSummary}
          />
        )}
      </main>
    </div>
  );
}

export default App;

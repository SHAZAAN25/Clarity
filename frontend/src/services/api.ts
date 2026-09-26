const API_BASE_URL = 'http://localhost:8000/api/v1';

export interface TokenData {
  access_token: string;
  token_type: string;
  user_id: string;
  email: string;
  onboarding_completed: boolean;
}

export interface UserProfile {
  user_id: string;
  baseline_cigs_per_day: number;
  cost_per_pack: number;
  cigs_per_pack: number;
  years_smoking: number;
  first_cig_after_waking_mins: number;
  goal: string;
  is_in_baseline_period: boolean;
  current_delay_capacity_mins: number;
  motivations: string[];
  common_triggers: string[];
  onboarding_completed: boolean;
}

export interface TodaySummary {
  today_date: string;
  total_cigarettes: number;
  target_cigarettes: number;
  last_cigarette_logged_at: string | null;
  minutes_since_last_cigarette: number | null;
  cigarettes_avoided: number;
  successful_delays: number;
  money_saved_today: number;
  currency_symbol: string;
  status: 'on_track' | 'caution' | 'exceeded';
  next_high_risk_window: string | null;
}

export interface SmokingClockItem {
  hour: number;
  label: string;
  count: number;
  percentage: number;
  is_high_risk: boolean;
}

export interface TriggerStatItem {
  trigger: string;
  count: number;
  percentage: number;
}

export interface ProgressSummary {
  baseline_cigs_per_day: number;
  current_7day_average: number;
  reduction_percentage: number;
  total_cigarettes_avoided: number;
  total_cravings_logged: number;
  total_successful_delays: number;
  estimated_money_saved: number;
  currency_symbol: string;
  consecutive_days_with_target_maintained: number;
  current_delay_capacity_mins: number;
}

export interface AchievementItem {
  code: string;
  title: string;
  description: string;
  icon: string;
  unlocked: boolean;
  unlocked_at?: string;
}

export interface HealthArticle {
  id: string;
  title: string;
  slug: string;
  category: string;
  summary: string;
  content: string;
  author_organization: string;
  source_url?: string;
  reading_time_mins: number;
}

export interface SourceCitation {
  title: string;
  source_organization: string;
  source_url?: string;
  relevance_summary: string;
}

export interface RAGResponse {
  query: string;
  answer: string;
  citations: SourceCitation[];
  uncertainty_statement: string;
  medical_disclaimer: string;
}

export interface ChatMessage {
  conversation_id: string;
  message_id: string;
  role: 'user' | 'assistant';
  content: string;
  is_safety_diverted?: boolean;
  citations?: SourceCitation[];
  suggested_quick_actions?: string[];
}

// Offline Queue Management
const OFFLINE_QUEUE_KEY = 'clarity_offline_queue';

function getOfflineQueue(): any[] {
  try {
    return JSON.parse(localStorage.getItem(OFFLINE_QUEUE_KEY) || '[]');
  } catch {
    return [];
  }
}

function addToOfflineQueue(item: any) {
  const queue = getOfflineQueue();
  queue.push(item);
  localStorage.setItem(OFFLINE_QUEUE_KEY, JSON.stringify(queue));
}

export const api = {
  getToken(): string | null {
    return localStorage.getItem('clarity_token');
  },

  setToken(token: string) {
    localStorage.setItem('clarity_token', token);
  },

  clearToken() {
    localStorage.removeItem('clarity_token');
  },

  async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = this.getToken();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...(options.headers as Record<string, string>),
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    try {
      const response = await fetch(`${API_BASE_URL}${endpoint}`, {
        ...options,
        headers,
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({}));
        throw new Error(errorData.detail || `Request failed with status ${response.status}`);
      }

      // If we made a successful connection, flush any pending offline items
      if (getOfflineQueue().length > 0) {
        this.flushOfflineQueue();
      }

      return (await response.json()) as T;
    } catch (err: any) {
      // Offline fallback handling
      if (!navigator.onLine || err.message?.includes('Failed to fetch')) {
        console.warn('Network offline or unreachable. Checking for offline actions.');
        if (options.method === 'POST' && endpoint.includes('/smoking/log')) {
          addToOfflineQueue({
            type: 'smoking_log',
            payload: JSON.parse((options.body as string) || '{}'),
            timestamp: new Date().toISOString(),
          });
          return {
            id: 'offline-' + Date.now(),
            count: 1,
            is_quick_log: true,
            logged_at: new Date().toISOString(),
          } as unknown as T;
        }
      }
      throw err;
    }
  },

  async flushOfflineQueue() {
    const queue = getOfflineQueue();
    if (queue.length === 0) return;

    localStorage.removeItem(OFFLINE_QUEUE_KEY);
    for (const item of queue) {
      try {
        if (item.type === 'smoking_log') {
          await this.request('/smoking/log', {
            method: 'POST',
            body: JSON.stringify(item.payload),
          });
        }
      } catch (e) {
        console.error('Failed to flush offline queue item:', e);
      }
    }
  },

  // Auth
  async register(email: string, password: string, fullName?: string): Promise<TokenData> {
    const data = await this.request<TokenData>('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ email, password, full_name: fullName }),
    });
    this.setToken(data.access_token);
    return data;
  },

  async login(email: string, password: string): Promise<TokenData> {
    const data = await this.request<TokenData>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    this.setToken(data.access_token);
    return data;
  },

  // Onboarding & Profile
  async completeOnboarding(profile: any): Promise<UserProfile> {
    return this.request<UserProfile>('/onboarding/complete', {
      method: 'POST',
      body: JSON.stringify(profile),
    });
  },

  async getProfile(): Promise<UserProfile> {
    return this.request<UserProfile>('/onboarding/profile');
  },

  // Smoking Tracker
  async logCigarette(log: {
    count?: number;
    trigger?: string;
    mood?: string;
    craving_intensity?: number;
    is_quick_log?: boolean;
    craving_event_id?: string;
  }) {
    return this.request<any>('/smoking/log', {
      method: 'POST',
      body: JSON.stringify(log),
    });
  },

  async getTodaySummary(): Promise<TodaySummary> {
    return this.request<TodaySummary>('/smoking/today');
  },

  async getSmokingHistory(limit = 20) {
    return this.request<any[]>(`/smoking/history?limit=${limit}`);
  },

  // Craving flow
  async startCraving(intensity: number, trigger?: string, mood?: string) {
    return this.request<any>('/cravings/start', {
      method: 'POST',
      body: JSON.stringify({ intensity, trigger, mood }),
    });
  },

  async recordIntervention(cravingId: string, interventionType: string, durationSeconds = 0, wasHelpful = true) {
    return this.request<any>(`/cravings/${cravingId}/intervention`, {
      method: 'POST',
      body: JSON.stringify({
        intervention_type: interventionType,
        duration_seconds: durationSeconds,
        was_helpful: wasHelpful,
      }),
    });
  },

  async completeCraving(cravingId: string, didSmoke: boolean, postFeeling: string, delayedSeconds: number, trigger?: string) {
    return this.request<any>(`/cravings/${cravingId}/complete`, {
      method: 'POST',
      body: JSON.stringify({
        did_smoke: didSmoke,
        post_feeling: postFeeling,
        actual_delayed_seconds: delayedSeconds,
        trigger,
      }),
    });
  },

  // Targets & Relapse
  async getCurrentTarget() {
    return this.request<any>('/targets/current');
  },

  async adjustTarget(targetCigs: number, reason?: string) {
    return this.request<any>('/targets/adjust', {
      method: 'POST',
      body: JSON.stringify({ target_cigs: targetCigs, reason }),
    });
  },

  async handleRelapseAction(reason: string, action: 'maintain' | 'adjust_plus_1' | 'pause') {
    return this.request<any>('/targets/relapse-action', {
      method: 'POST',
      body: JSON.stringify({ reason, action }),
    });
  },

  // Progress & Achievements
  async getProgressSummary(): Promise<ProgressSummary> {
    return this.request<ProgressSummary>('/progress/summary');
  },

  async getAchievements(): Promise<AchievementItem[]> {
    return this.request<AchievementItem[]>('/progress/achievements');
  },

  // Analytics
  async getSmokingClock(): Promise<{ clock_data: SmokingClockItem[]; peak_window_label: string; observation_note: string }> {
    return this.request<any>('/analytics/smoking-clock');
  },

  async getTriggerAnalytics(): Promise<{ top_triggers: TriggerStatItem[]; primary_observation: string; caveat_note: string }> {
    return this.request<any>('/analytics/triggers');
  },

  async getWeeklyReport() {
    return this.request<any>('/analytics/weekly-report');
  },

  // AI Coach
  async sendCoachMessage(message: string, conversationId?: string): Promise<ChatMessage> {
    return this.request<ChatMessage>('/coach/message', {
      method: 'POST',
      body: JSON.stringify({ message, conversation_id: conversationId }),
    });
  },

  async getCoachHistory(): Promise<ChatMessage[]> {
    return this.request<ChatMessage[]>('/coach/history');
  },

  // Health & RAG
  async getHealthArticles(): Promise<HealthArticle[]> {
    return this.request<HealthArticle[]>('/health/articles');
  },

  async askRAG(query: string): Promise<RAGResponse> {
    return this.request<RAGResponse>('/health/ask-rag', {
      method: 'POST',
      body: JSON.stringify({ query }),
    });
  },

  // Settings & Privacy
  async getSettings() {
    return this.request<any>('/settings');
  },

  async updateSettings(settings: any) {
    return this.request<any>('/settings', {
      method: 'PATCH',
      body: JSON.stringify(settings),
    });
  },

  async exportData() {
    return this.request<any>('/settings/export-data');
  },

  async deleteAccount() {
    await this.request('/settings/account', { method: 'DELETE' });
    this.clearToken();
  },

  async seedDemoData() {
    return this.request<any>('/dev/seed-sample-data', { method: 'POST' });
  },
};

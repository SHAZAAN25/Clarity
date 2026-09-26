import React, { useState, useEffect, useRef } from 'react';
import { api, ChatMessage } from '../services/api';
import { Send, Sparkles, AlertTriangle, ShieldCheck, RefreshCw } from 'lucide-react';

interface AICoachViewProps {
  onOpenCraving: () => void;
}

export const AICoachView: React.FC<AICoachViewProps> = ({ onOpenCraving }) => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const loadHistory = async () => {
    try {
      const history = await api.getCoachHistory();
      if (history && history.length > 0) {
        setMessages(history);
      } else {
        // Default warm introduction
        setMessages([
          {
            conversation_id: 'default',
            message_id: 'intro',
            role: 'assistant',
            content: "Hello! I'm Clarity, your smoking reduction coach. My goal isn't to judge you or demand that you quit today. We focus on building awareness, understanding your triggers, and testing small delay victories.\n\nHow is your day going so far?",
            suggested_quick_actions: ["I have an intense craving", "I slipped and smoked", "How does delaying help?"]
          }
        ]);
      }
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    loadHistory();
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, loading]);

  const handleSend = async (textToSend?: string) => {
    const text = (textToSend || input).trim();
    if (!text || loading) return;

    const userMsg: ChatMessage = {
      conversation_id: messages[0]?.conversation_id || 'default',
      message_id: 'user-' + Date.now(),
      role: 'user',
      content: text
    };

    setMessages(prev => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    try {
      const reply = await api.sendCoachMessage(text);
      setMessages(prev => [...prev, reply]);
    } catch (e: any) {
      setMessages(prev => [
        ...prev,
        {
          conversation_id: 'default',
          message_id: 'err-' + Date.now(),
          role: 'assistant',
          content: "I'm having a momentary connection glitch, but remember: if you're facing a craving right now, try drinking a glass of cold water and delaying for 10 minutes. Cravings crest and fall."
        }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleQuickAction = (action: string) => {
    if (action.toLowerCase().includes('craving')) {
      onOpenCraving();
    } else {
      handleSend(action);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 170px)', minHeight: 480 }}>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', paddingBottom: 12, borderBottom: '1px solid var(--border-subtle)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <div style={{ background: 'rgba(16, 185, 129, 0.2)', padding: 8, borderRadius: 10, color: '#10B981' }}>
            <Sparkles size={20} />
          </div>
          <div>
            <h3 style={{ fontSize: 16 }}>Coach Clarity</h3>
            <span style={{ fontSize: 11, color: '#34D399', display: 'flex', alignItems: 'center', gap: 4 }}>
              ● Non-judgmental behavioral guidance
            </span>
          </div>
        </div>

        <button className="btn-ghost" onClick={loadHistory} title="Refresh chat">
          <RefreshCw size={16} />
        </button>
      </div>

      {/* Medical Boundary Notice */}
      <div style={{ background: 'rgba(255, 255, 255, 0.03)', padding: '6px 12px', borderRadius: 8, margin: '10px 0', fontSize: 11, color: 'var(--text-muted)' }}>
        🛡️ Clarity provides behavioral coaching; not medical diagnosis or prescription advice.
      </div>

      {/* Messages Scroll Area */}
      <div style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 10, padding: '8px 2px' }}>
        {messages.map((m, idx) => (
          <div key={idx} style={{ display: 'flex', flexDirection: 'column', alignItems: m.role === 'user' ? 'flex-end' : 'flex-start' }}>
            <div className={`chat-bubble ${m.role} ${m.is_safety_diverted ? 'safety-alert' : ''}`}>
              {m.is_safety_diverted && (
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontWeight: 700, marginBottom: 4, color: '#F87171' }}>
                  <AlertTriangle size={16} />
                  <span>Important Health Guidance</span>
                </div>
              )}
              <div style={{ whiteSpace: 'pre-line' }}>{m.content}</div>
            </div>

            {/* Quick action chips from coach */}
            {m.role === 'assistant' && m.suggested_quick_actions && m.suggested_quick_actions.length > 0 && (
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6, marginTop: 4, marginBottom: 8 }}>
                {m.suggested_quick_actions.map((act, i) => (
                  <button
                    key={i}
                    className="chip"
                    onClick={() => handleQuickAction(act)}
                    style={{ fontSize: 12, padding: '4px 10px' }}
                  >
                    {act}
                  </button>
                ))}
              </div>
            )}
          </div>
        ))}

        {loading && (
          <div className="chat-bubble assistant" style={{ fontStyle: 'italic', color: 'var(--text-muted)' }}>
            Clarity is reflecting...
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      {/* Input Form */}
      <form 
        onSubmit={e => { e.preventDefault(); handleSend(); }}
        style={{ display: 'flex', gap: 8, paddingTop: 10 }}
      >
        <input 
          type="text" 
          value={input} 
          onChange={e => setInput(e.target.value)}
          placeholder="Ask for advice, report a craving, or reflect..."
          style={{ flex: 1 }}
          disabled={loading}
        />
        <button 
          type="submit" 
          className="btn-primary" 
          style={{ padding: '0 16px' }}
          disabled={loading || !input.trim()}
        >
          <Send size={18} />
        </button>
      </form>
    </div>
  );
};

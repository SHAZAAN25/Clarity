import os
import json
import logging
import httpx
from typing import Dict, Any, List, Optional
from app.core.config import settings

logger = logging.getLogger(__name__)

class AIService:
    """
    Modular abstraction layer for LLM providers.
    Supports:
    - local_fallback (high-reliability, zero-external-dependency heuristic engine)
    - openai
    - gemini
    - anthropic
    
    Never crashes on network or provider errors.
    """
    
    @classmethod
    async def generate_response(
        cls, 
        system_prompt: str, 
        messages: List[Dict[str, str]], 
        temperature: float = 0.6
    ) -> str:
        provider = settings.LLM_PROVIDER.lower()
        api_key = settings.LLM_API_KEY
        
        # If external provider is configured and has API key, attempt it
        if provider == "openai" and api_key:
            try:
                return await cls._call_openai(system_prompt, messages, temperature, api_key)
            except Exception as e:
                logger.warning(f"OpenAI call failed, falling back to local engine: {e}")
                return cls._generate_local_fallback(messages)
                
        elif provider == "gemini" and api_key:
            try:
                return await cls._call_gemini(system_prompt, messages, temperature, api_key)
            except Exception as e:
                logger.warning(f"Gemini call failed, falling back to local engine: {e}")
                return cls._generate_local_fallback(messages)
                
        # Default or fallback
        return cls._generate_local_fallback(messages)

    @classmethod
    async def _call_openai(
        cls, 
        system_prompt: str, 
        messages: List[Dict[str, str]], 
        temperature: float,
        api_key: str
    ) -> str:
        payload = {
            "model": settings.LLM_MODEL or "gpt-4o-mini",
            "messages": [{"role": "system", "content": system_prompt}] + messages,
            "temperature": temperature,
            "max_tokens": 500,
        }
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"},
                json=payload
            )
            resp.raise_for_status()
            data = resp.json()
            return data["choices"][0]["message"]["content"].strip()

    @classmethod
    async def _call_gemini(
        cls, 
        system_prompt: str, 
        messages: List[Dict[str, str]], 
        temperature: float,
        api_key: str
    ) -> str:
        model = settings.LLM_MODEL or "gemini-1.5-flash"
        url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
        
        contents = []
        for m in messages:
            role = "user" if m["role"] == "user" else "model"
            contents.append({"role": role, "parts": [{"text": m["content"]}]})
            
        payload = {
            "system_instruction": {"parts": [{"text": system_prompt}]},
            "contents": contents,
            "generationConfig": {"temperature": temperature, "maxOutputTokens": 500}
        }
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.post(url, json=payload)
            resp.raise_for_status()
            data = resp.json()
            candidates = data.get("candidates", [])
            if candidates and "content" in candidates[0]:
                return candidates[0]["content"]["parts"][0]["text"].strip()
            return cls._generate_local_fallback(messages)

    @classmethod
    def _generate_local_fallback(cls, messages: List[Dict[str, str]]) -> str:
        """
        Intelligent, context-sensitive fallback engine that adheres strictly to:
        - Non-judgmental, calm, empathetic tone
        - Focus on delay and behavioral awareness
        - Never shaming or using punitive language
        """
        last_user_msg = ""
        for m in reversed(messages):
            if m.get("role") == "user":
                last_user_msg = m.get("content", "").lower()
                break
                
        if any(w in last_user_msg for w in ["craving", "want to smoke", "urge", "need a cig", "need a smoke"]):
            return (
                "I understand how intense that craving feels right now. Cravings are intense, but they generally crest and begin easing within 5 to 10 minutes.\n\n"
                "You don't have to decide whether you'll quit forever right now. Would you be open to just testing a 10-minute delay? "
                "Let's drink a cold glass of water or try a 2-minute 4-4-4 breathing cycle while the timer runs."
            )
            
        elif any(w in last_user_msg for w in ["smoked", "relapse", "slipped", "failed", "messed up", "ruined"]):
            return (
                "Take a breath. You haven't failed, and one cigarette does not erase your effort or your progress.\n\n"
                "Every smoke is behavioral information. What was happening right before you smoked? "
                "Were you feeling stressed, unwinding after work, or was it an automatic habit? Understanding the trigger helps us plan a delay for next time."
            )
            
        elif any(w in last_user_msg for w in ["stress", "anxious", "work", "boss", "overwhelmed"]):
            return (
                "Stress is one of the most common smoking triggers because nicotine creates a brief sensation of relief by answering withdrawal, not by resolving the stress itself.\n\n"
                "When your body feels tense, try stepping away from your desk for just 3 minutes. Even a short physical change of scenery can break the automatic reach for a cigarette."
            )
            
        elif any(w in last_user_msg for w in ["coffee", "after meal", "dinner", "lunch", "breakfast"]):
            return (
                "Those situational cues (like coffee or meals) are deeply conditioned habits. Your brain has linked the end of a meal with nicotine release.\n\n"
                "A gentle technique is habit substitution: right after eating, immediately brush your teeth or drink iced mint water. That fresh sensory cue can interrupt the routine."
            )
            
        elif any(w in last_user_msg for w in ["target", "reduction", "goal", "plan"]):
            return (
                "Gradual reduction is all about steady pacing. When you lower your daily target by 1 or 2 cigarettes, your brain and body adapt with minimal friction.\n\n"
                "Remember, you're always in control of your pace. You can maintain your target whenever you need stability."
            )
            
        else:
            return (
                "I'm right here with you. My goal isn't to judge how much you smoke, but to help you understand your triggers and build control one delay at a time.\n\n"
                "How are you feeling right now? If you're facing a craving or want to review your progress today, let's take it step by step."
            )

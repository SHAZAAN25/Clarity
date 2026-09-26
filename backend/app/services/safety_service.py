import re
from typing import Dict, Any, Optional, Tuple

class SafetyService:
    """
    Enforces AI safety constraints:
    1. Emergency symptom triage (chest pain, shortness of breath, severe acute distress)
    2. Medical diagnosis / prescription / dosage prohibition
    3. Guarantees of clinical cure or individual health outcome claims
    """
    
    EMERGENCY_PATTERNS = [
        r"\b(chest pain|tightness in (my )?chest|heart attack|angina)\b",
        r"\b(can't breathe|cannot breathe|severe shortness of breath|gasping)\b",
        r"\b(coughing (up )?blood|hemoptysis)\b",
        r"\b(fainted|passed out|sudden numbness|stroke symptoms|face drooping)\b",
        r"\b(overdose|poisoned|swallowed nicotine liquid|swallowed vape juice)\b",
        r"\b(suicid|kill myself|end my life|want to die)\b",
    ]
    
    PRESCRIPTION_PATTERNS = [
        r"\b(how much|what dose|what dosage|prescribe|can i take|how many mg)\b.*\b(varenicline|chantix|champix|bupropion|zyban|wellbutrin|patch|gum|inhaler|lozenge)\b",
        r"\b(can i combine|drug interaction|should i stop taking|medication side effect)\b",
    ]

    DIAGNOSIS_PATTERNS = [
        r"\b(do i have|diagnose me|is this cancer|emphysema|copd|bronchitis)\b",
    ]

    @classmethod
    def evaluate_input(cls, user_text: str) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Returns (is_unsafe, safety_type, safe_canned_response)
        """
        lower_text = user_text.lower()

        # Check for medical emergency
        for pattern in cls.EMERGENCY_PATTERNS:
            if re.search(pattern, lower_text):
                if re.search(r"\b(suicid|kill myself|end my life|want to die)\b", lower_text):
                    response = (
                        "I hear that you're going through a very difficult time, but I am an AI coach and cannot provide crisis counseling. "
                        "Please reach out immediately for confidential, free support:\n\n"
                        "• In the US/Canada: Call or text 988 (Suicide & Crisis Lifeline)\n"
                        "• In the UK: Call 111 or text SHOUT to 85258\n"
                        "• In India: Call 14416 (Tele-MANAS) or 9152987821\n"
                        "• International: Contact your local emergency services or visit https://findahelpline.com\n\n"
                        "Please speak with someone who can support you right now."
                    )
                    return True, "crisis", response
                else:
                    response = (
                        "⚠️ **Important Health Notice**\n\n"
                        "You mentioned symptoms (such as chest pain or breathing difficulties) that could indicate an urgent medical situation. "
                        "As an AI anti-smoking coach, I cannot evaluate, diagnose, or manage acute medical symptoms.\n\n"
                        "**Please seek immediate emergency medical care or call your local emergency medical service (such as 911, 999, 112, or 108) right away.**"
                    )
                    return True, "emergency", response

        # Check for medication prescription / dosage queries
        for pattern in cls.PRESCRIPTION_PATTERNS:
            if re.search(pattern, lower_text):
                response = (
                    "ℹ️ **Medication & Dosing Guidance**\n\n"
                    "I am an AI anti-smoking coach and cannot prescribe medications or calculate specific dosages for cessation aids "
                    "(such as Varenicline, Bupropion, or specific NRT nicotine patch/gum milligram levels).\n\n"
                    "The right dosage depends on your individual medical history, cardiovascular health, pregnancy status, and current smoking rate. "
                    "Please consult a physician, licensed pharmacist, or certified tobacco cessation specialist to select an appropriate, safe regimen for you."
                )
                return True, "prescription", response

        # Check for diagnosis queries
        for pattern in cls.DIAGNOSIS_PATTERNS:
            if re.search(pattern, lower_text):
                response = (
                    "ℹ️ **Medical Evaluation Notice**\n\n"
                    "I cannot diagnose health conditions, respiratory illnesses, or evaluate specific physical symptoms. "
                    "If you are concerned about persistent cough, wheezing, shortness of breath, or any physical symptoms, "
                    "please schedule an evaluation with a primary care doctor or pulmonologist."
                )
                return True, "diagnosis", response

        return False, None, None

    @classmethod
    def sanitize_ai_output(cls, ai_text: str) -> str:
        """
        Guarantees that the AI does not state false claims like '10 cigarettes are safe'
        or equate reduction with being completely harmless.
        """
        forbidden_claims = [
            (r"\b(\d+ cigarettes? (is|are) (completely )?safe)\b", "cutting down is a beneficial step toward quitting, but smoking fewer cigarettes does not make smoking entirely harmless"),
            (r"\b(you failed|streak ruined|you ruined your progress)\b", "every cigarette is behavioral information, and one slip does not erase your progress"),
        ]
        
        sanitized = ai_text
        for pattern, replacement in forbidden_claims:
            sanitized = re.sub(pattern, replacement, sanitized, flags=re.IGNORECASE)
            
        return sanitized

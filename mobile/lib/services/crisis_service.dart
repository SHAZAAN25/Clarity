class CrisisDetectionResult {
  final bool isCrisis;
  final bool isSelfHarm;
  final bool isMedicalEmergency;
  final String safetyMessage;
  final List<CrisisResource> resources;

  const CrisisDetectionResult({
    required this.isCrisis,
    this.isSelfHarm = false,
    this.isMedicalEmergency = false,
    required this.safetyMessage,
    this.resources = const [],
  });
}

class CrisisResource {
  final String name;
  final String contact;
  final String description;
  final String region;

  const CrisisResource({
    required this.name,
    required this.contact,
    required this.description,
    required this.region,
  });
}

class CrisisService {
  static const List<CrisisResource> defaultResources = [
    CrisisResource(
      name: 'National Emergency Services',
      contact: '112',
      description: 'Immediate all-in-one emergency response (Police, Fire, Ambulance in India & EU).',
      region: 'India / International',
    ),
    CrisisResource(
      name: 'Tele-MANAS (Mental Health Helpline)',
      contact: '14416 / 1800-891-4416',
      description: '24/7 free, confidential psychological & crisis counseling by Govt. of India.',
      region: 'India',
    ),
    CrisisResource(
      name: 'Vandrevala Foundation Helpline',
      contact: '+91 9999 666 555',
      description: '24/7 free emotional distress and suicide prevention support.',
      region: 'India',
    ),
    CrisisResource(
      name: 'National Suicide Prevention Lifeline (US)',
      contact: '988',
      description: 'Free, confidential support available 24/7 via call or text.',
      region: 'US / Canada',
    ),
  ];

  static CrisisDetectionResult evaluateInput(String text) {
    final lower = text.toLowerCase();

    // Check for self-harm or suicidal intent
    final suicidalKeywords = [
      'suicide',
      'kill myself',
      'end my life',
      'want to die',
      'better off dead',
      'no reason to live',
      'cannot go on',
      'cant go on',
      'hang myself',
      'slit my wrists',
      'take all my pills',
      'ending it all',
      'self harm',
      'hurt myself',
      'harm myself',
    ];

    for (final kw in suicidalKeywords) {
      if (lower.contains(kw)) {
        return const CrisisDetectionResult(
          isCrisis: true,
          isSelfHarm: true,
          safetyMessage:
              "I hear that you are going through immense pain right now, but please know that you are not alone. Clarity is an automated habit coach and cannot provide crisis or mental health care. Please reach out right now to a professional or someone you trust who can support you safely.",
          resources: defaultResources,
        );
      }
    }

    // Check for acute physical medical emergencies
    final medicalKeywords = [
      'chest pain',
      'shortness of breath',
      'cant breathe',
      'cannot breathe',
      'heart attack',
      'coughing blood',
      'severe dizziness',
      'stroke symptoms',
      'numbness in arm',
    ];

    for (final kw in medicalKeywords) {
      if (lower.contains(kw)) {
        return const CrisisDetectionResult(
          isCrisis: true,
          isMedicalEmergency: true,
          safetyMessage:
              "CRITICAL MEDICAL NOTICE: Acute symptoms such as chest pain or breathing difficulty require immediate clinical evaluation. Clarity cannot diagnose or treat medical conditions. Please call emergency services (112 or local emergency) immediately.",
          resources: [
            CrisisResource(
              name: 'Emergency Medical Services',
              contact: '112 / 102',
              description: 'Call immediately for acute ambulance and emergency hospital response.',
              region: 'India / Global',
            ),
          ],
        );
      }
    }

    return const CrisisDetectionResult(
      isCrisis: false,
      safetyMessage: '',
      resources: [],
    );
  }
}

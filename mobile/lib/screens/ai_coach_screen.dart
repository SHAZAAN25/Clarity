import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/crisis_service.dart';
import '../widgets/crisis_support_dialog.dart';
import '../theme/app_colors.dart';
import '../widgets/coach_suggestion.dart';
import '../widgets/ai_message.dart';
import 'craving_intervention_screen.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _ChatMessageData {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isEmergency;

  _ChatMessageData({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isEmergency = false,
  });
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessageData> _messages = [];
  bool _isResponding = false;
  bool _isChatExpanded = false;

  @override
  void initState() {
    super.initState();
    // Warm, specialized companion starter message (Section 39)
    _messages.add(
      _ChatMessageData(
        text:
            "I'm here when you need me.\n\nWhenever a craving arrives or an urge feels intense, we can examine the trigger without judgment, practice conscious delay, and protect your steady progress.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    if (presetText == null) {
      _textController.clear();
    }

    setState(() {
      _isChatExpanded = true;
      _messages.add(
        _ChatMessageData(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isResponding = true;
    });
    _scrollToBottom();

    // Section 40: Crisis & Safety Detection
    final crisisResult = CrisisService.evaluateInput(text);
    if (crisisResult.isCrisis) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _isResponding = false;
          _messages.add(
            _ChatMessageData(
              text: crisisResult.safetyMessage,
              isUser: false,
              timestamp: DateTime.now(),
              isEmergency: true,
            ),
          );
        });
        _scrollToBottom();
        CrisisSupportDialog.show(context, crisisResult);
      });
      return;
    }

    final appState = Provider.of<AppState>(context, listen: false);
    final profile = appState.profile;
    final lower = text.toLowerCase();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      String reply;

      if (lower.contains('target') || lower.contains('cycle') || lower.contains('ceiling')) {
        reply =
            'Your active daily target is ${appState.todayTargetCount} cigarettes (${profile.strategyMode.label} mode). In Clarity, targets are ceilings, not quotas—if you smoke fewer than ${appState.todayTargetCount}, that is outstanding. Targets adapt deterministically in 7-day cycles based on at least 5 valid tracked days.';
      } else if (lower.contains('delay') || lower.contains('craving') || lower.contains('urge')) {
        reply =
            'Cravings operate like waves—they typically peak between 3 to 5 minutes, then recede. Delaying for 7 to 10 minutes gives your prefrontal cortex time to interrupt the automated dopamine loop. Would you like to start the guided delay timer now?';
      } else if (lower.contains('stress') || lower.contains('anxious') || lower.contains('work')) {
        reply =
            'When stress spikes, nicotine feels calming only because it resolves the immediate withdrawal physical tension created by the previous cigarette. Try taking 5 slow exhales now: making your exhale twice as long as your inhale activates your parasympathetic calm reflex.';
      } else if (lower.contains('already smoked') || lower.contains('slipped') || lower.contains('relapse')) {
        reply =
            'One cigarette does not erase your progress or reset your historical achievements. Rather than feeling shame, notice what happened in the 15 minutes right before: what was the trigger cue? Understanding that trigger is how we prevent the next automatic response.';
      } else if (lower.contains('money') || lower.contains('saved') || lower.contains('cost')) {
        reply =
            'At ₹${profile.packPrice.toInt()} per pack of ${profile.cigarettesPerPack}, each cigarette costs ₹${profile.costPerCigarette.toStringAsFixed(2)}. Every cigarette you delay or skip keeps real money in your pocket.';
      } else {
        reply =
            'I hear you. The impulse to smoke is an automated behavioral reflex learned over years. When you pause and notice the feeling without acting on impulse, you rebuild self-regulation. How are you feeling in this exact moment?';
      }

      setState(() {
        _isResponding = false;
        _messages.add(
          _ChatMessageData(
            text: reply,
            isUser: false,
            timestamp: DateTime.now(),
            isEmergency: false,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textPrim = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textMut = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final accent = isDark ? AppColors.sageLight : AppColors.sageDark;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Companion Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clarity Coach',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: textPrim,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Behavioral Guidance · Non-judgmental',
                        style: TextStyle(
                          fontSize: 12,
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: border, height: 1),

            // Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return AIMessage(
                    text: msg.text,
                    isUser: msg.isUser,
                    timestamp: msg.timestamp,
                    isEmergency: msg.isEmergency,
                  );
                },
              ),
            ),

            if (_isResponding)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: accent),
                    ),
                    const SizedBox(width: 8),
                    Text('Clarity is reflecting...', style: TextStyle(fontSize: 12, color: textMut)),
                  ],
                ),
              ),

            // Suggestions Carousel
            if (!_isChatExpanded)
              Container(
                height: 44,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    CoachSuggestion(
                      label: "I'm having an intense craving right now",
                      onTap: () => _handleSendMessage("I'm having an intense craving right now"),
                    ),
                    CoachSuggestion(
                      label: "I slipped and smoked a cigarette",
                      onTap: () => _handleSendMessage("I slipped and smoked a cigarette"),
                    ),
                    CoachSuggestion(
                      label: "How does my daily target work?",
                      onTap: () => _handleSendMessage("How does my daily target work?"),
                    ),
                    CoachSuggestion(
                      label: "I feel stressed at work",
                      onTap: () => _handleSendMessage("I feel stressed at work"),
                    ),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: border, width: 1.0)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Emergency Delay',
                    icon: Icon(Icons.hourglass_top_outlined, color: accent, size: 22),
                    onPressed: () => CravingInterventionScreen.open(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: TextStyle(color: textPrim, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Talk about an urge, trigger, or slip...',
                        hintStyle: TextStyle(color: textMut, fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _handleSendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded),
                    color: accent,
                    onPressed: () => _handleSendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

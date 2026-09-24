import 'package:flutter/material.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/chrono_theme.dart';
import '../../../core/services/ai_service.dart';

/// Interactive AI Consultation Sheet
///
/// Provides patient-facing clinical chronotherapy explanations and medication
/// guidance powered by OpenRouter LLM, grounded in the patient's active schedule.
class AiConsultationSheet extends StatefulWidget {
  final AppState state;
  final String? focusMedication;
  final String? initialQuestion;

  const AiConsultationSheet({
    super.key,
    required this.state,
    this.focusMedication,
    this.initialQuestion,
  });

  static void show(
    BuildContext context,
    AppState state, {
    String? focusMedication,
    String? initialQuestion,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiConsultationSheet(
        state: state,
        focusMedication: focusMedication,
        initialQuestion: initialQuestion,
      ),
    );
  }

  @override
  State<AiConsultationSheet> createState() => _AiConsultationSheetState();
}

class _ChatMessage {
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime time;

  _ChatMessage({
    required this.role,
    required this.text,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class _AiConsultationSheetState extends State<AiConsultationSheet> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastFailedQuestion;

  @override
  void initState() {
    super.initState();
    // Seed initial greeting message from assistant
    final focus = widget.focusMedication;
    final greeting = focus != null
        ? 'Hello! I am your ChronoMed AI Assistant. I see you want to discuss $focus. How can I help you understand its timing, food rules, or drug interactions?'
        : 'Hello! I am your ChronoMed AI Assistant. I can explain the biological timing of your doses, why certain medicines require an empty stomach, or how your schedule prevents chemical interactions. What would you like to know?';

    _messages.add(_ChatMessage(role: 'assistant', text: greeting));

    // If an initial question was passed (e.g. from a quick action), send it automatically
    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendQuestion(widget.initialQuestion!);
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> get _quickSuggestions {
    if (widget.focusMedication != null) {
      final med = widget.focusMedication!;
      return [
        'Why is $med scheduled at this time?',
        'Can I take $med with food or coffee?',
        'What should I avoid while taking $med?',
      ];
    }
    return [
      'Why are my morning doses taken on an empty stomach?',
      'Why is there a 4-hour gap between Calcium and Iron?',
      'Why is Atorvastatin taken at bedtime?',
      'Can I drink tea or coffee with my medication?',
    ];
  }

  Future<void> _sendQuestion(String question) async {
    final cleanQ = question.trim();
    if (cleanQ.isEmpty || _isLoading) return;

    _textController.clear();
    setState(() {
      _messages.add(_ChatMessage(role: 'user', text: cleanQ));
      _isLoading = true;
      _errorMessage = null;
      _lastFailedQuestion = cleanQ;
    });

    _scrollToBottom();
    await _executeAiQuery(cleanQ);
  }

  Future<void> _retryQuestion(String question) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _scrollToBottom();
    await _executeAiQuery(question);
  }

  Future<void> _executeAiQuery(String question) async {
    try {
      final history = _messages
          .where((m) => m.role == 'assistant' || m.text != question)
          .map((m) => {'role': m.role, 'content': m.text})
          .toList();

      final reply = await AiService.ask(
        question: question,
        state: widget.state,
        focusMedication: widget.focusMedication,
        chatHistory: history,
      );

      if (mounted) {
        setState(() {
          _messages.add(_ChatMessage(role: 'assistant', text: reply));
          _isLoading = false;
          _lastFailedQuestion = null;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
        _scrollToBottom();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: const BoxDecoration(
        color: ChronoTheme.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ChronoTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'ChronoMed AI',
                            style: TextStyle(
                              color: ChronoTheme.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: ChronoTheme.cyanSurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: ChronoTheme.primary.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'OPENROUTER',
                              style: TextStyle(
                                color: ChronoTheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.focusMedication != null
                            ? 'Discussing ${widget.focusMedication}'
                            : 'Chronotherapy & medication explainer',
                        style: const TextStyle(
                          color: ChronoTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ChronoTheme.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(color: ChronoTheme.border, height: 1),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              itemCount: _messages.length + (_isLoading ? 1 : 0) + (_errorMessage != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                } else if (_isLoading && index == _messages.length) {
                  return _buildLoadingBubble();
                } else {
                  return _buildErrorCard();
                }
              },
            ),
          ),

          // Quick Suggestion Chips (only when user has not typed much)
          if (!_isLoading) ...[
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quickSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final text = _quickSuggestions[i];
                  return ActionChip(
                    label: Text(text),
                    labelStyle: const TextStyle(
                      color: ChronoTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                    backgroundColor: ChronoTheme.surfaceElevated,
                    side: const BorderSide(color: ChronoTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onPressed: () => _sendQuestion(text),
                  );
                },
              ),
            ),
          ],

          // Input Bar + Medical Footnote
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
            decoration: const BoxDecoration(
              color: ChronoTheme.surface,
              border: Border(top: BorderSide(color: ChronoTheme.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(
                          color: ChronoTheme.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask about timing, food rules, or interactions...',
                          hintStyle: const TextStyle(
                            color: ChronoTheme.textMuted,
                            fontSize: 12.5,
                          ),
                          filled: true,
                          fillColor: ChronoTheme.surfaceElevated,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: ChronoTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: ChronoTheme.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: ChronoTheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: _sendQuestion,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: ChronoTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_upward_rounded,
                          color: ChronoTheme.obsidian,
                          size: 18,
                        ),
                        onPressed: () => _sendQuestion(_textController.text),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Educational chronotherapy guidance. Always consult your doctor for medical decisions.',
                  style: TextStyle(
                    color: ChronoTheme.textDim,
                    fontSize: 9.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    final isUser = msg.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isUser ? ChronoTheme.cyanSurface : ChronoTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUser
                ? ChronoTheme.primary.withOpacity(0.4)
                : ChronoTheme.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: ChronoTheme.primary,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'ChronoMed AI',
                    style: TextStyle(
                      color: ChronoTheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            SelectableText(
              msg.text,
              style: TextStyle(
                color: isUser ? ChronoTheme.textPrimary : ChronoTheme.textPrimary,
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ChronoTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ChronoTheme.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ChronoTheme.primary,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Consulting chronotherapy model...',
              style: TextStyle(
                color: ChronoTheme.textSecondary,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: ChronoTheme.roseSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ChronoTheme.rose.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ChronoTheme.rose,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage ?? 'Network error.',
              style: const TextStyle(
                color: ChronoTheme.rose,
                fontSize: 11.5,
              ),
            ),
          ),
          if (_lastFailedQuestion != null) ...[
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                final q = _lastFailedQuestion!;
                _retryQuestion(q);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: ChronoTheme.rose.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ChronoTheme.rose.withOpacity(0.4),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: ChronoTheme.rose,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

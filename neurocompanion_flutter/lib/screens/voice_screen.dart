import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/bloc/bloc.dart';
import 'package:neurocompanion_flutter/bloc/blocs.dart';
import 'dart:async';

class VoiceScreen extends StatefulWidget {
  const VoiceScreen({super.key});

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

enum _VoiceJournalCallState { idle, connecting, active, saving, success, error }

class _VoiceScreenState extends State<VoiceScreen> with SingleTickerProviderStateMixin {
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _lastReply;
  String? _error;

  _VoiceJournalCallState _callState = _VoiceJournalCallState.idle;
  VoiceJournalStart? _callData;
  String? _voiceEntryId;
  String? _voiceError;
  int _callDurationSeconds = 0;

  Timer? _callTimer;
  Timer? _statusTimer;
  int _savingAttempts = 0;
  AnimationController? _pulseController;

  @override
  void dispose() {
    _callTimer?.cancel();
    _statusTimer?.cancel();
    _pulseController?.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.85,
      upperBound: 1.25,
    )..repeat(reverse: true);
  }

  Future<void> _sendMessage(String message) async {
    final voiceService = context.read<VoiceService>();

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      final reply = await voiceService.therapeuticReply(message);
      if (!mounted) return;
      setState(() {
        _lastReply = reply;
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _sending = false;
      });
    }
  }

  Future<void> _startVoiceJournal() async {
    final voiceJournalService = context.read<VoiceJournalService>();

    setState(() {
      _callState = _VoiceJournalCallState.connecting;
      _voiceError = null;
      _voiceEntryId = null;
      _callData = null;
      _callDurationSeconds = 0;
      _savingAttempts = 0;
    });

    try {
      final start = await voiceJournalService.startVoiceJournalCall();
      if (!mounted) return;

      setState(() {
        _callData = start;
        _callState = _VoiceJournalCallState.active;
      });

      _callTimer?.cancel();
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (_callState != _VoiceJournalCallState.active) return;
        setState(() {
          _callDurationSeconds += 1;
        });
      });

      _statusTimer?.cancel();
      _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final callId = _callData?.callId ?? '';
        if (callId.isEmpty) return;
        if (_callState != _VoiceJournalCallState.active) return;

        try {
          final status = await voiceJournalService.getVoiceJournalStatus(callId);
          if (!mounted) return;

          if (status.isCompleted) {
            _onVoiceJournalCompleted(status.entryId);
          }
        } catch (e) {
          if (!mounted) return;
          _onVoiceJournalError(e.toString());
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _callState = _VoiceJournalCallState.error;
        _voiceError = e.toString();
      });

      Future<void>.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        setState(() {
          _callState = _VoiceJournalCallState.idle;
          _voiceError = null;
        });
      });
    }
  }

  void _endVoiceJournal() {
    if (_callState != _VoiceJournalCallState.active) return;
    setState(() {
      _callState = _VoiceJournalCallState.saving;
      _savingAttempts = 0;
    });

    _callTimer?.cancel();
    _statusTimer?.cancel();

    final voiceJournalService = context.read<VoiceJournalService>();
    final callId = _callData?.callId ?? '';
    if (callId.isEmpty) {
      _onVoiceJournalError('Missing call id');
      return;
    }

    print('📞 Call ended, checking status for: $callId');
    
    // Give backend a moment to start processing
    await Future.delayed(const Duration(seconds: 2));

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _savingAttempts += 1;
      print('🔍 Checking status (attempt $_savingAttempts/45)...');
      
      if (_savingAttempts > 45) {
        _onVoiceJournalError('Processing is taking longer than expected. Your entry may still be saved - please check your journal in a moment.');
        return;
      }
      
      // Show progress update every 10 seconds
      if (_savingAttempts > 0 && _savingAttempts % 10 == 0) {
        print('⏳ Still waiting... ($_savingAttempts s elapsed)');
      }

      try {
        final status = await voiceJournalService.getVoiceJournalStatus(callId);
        if (!mounted) return;
        if (status.isCompleted) {
          print('✅ Journal entry completed! EntryId: ${status.entryId}');
          _onVoiceJournalCompleted(status.entryId);
        }
      } catch (e) {
        print('❌ Status check error: $e');
        if (!mounted) return;
        _onVoiceJournalError(e.toString());
      }
    });
  }

  void _resetVoiceJournal() {
    _callTimer?.cancel();
    _statusTimer?.cancel();
    setState(() {
      _callState = _VoiceJournalCallState.idle;
      _callData = null;
      _voiceEntryId = null;
      _voiceError = null;
      _callDurationSeconds = 0;
      _savingAttempts = 0;
    });
  }

  void _onVoiceJournalCompleted(String? entryId) {
    _callTimer?.cancel();
    _statusTimer?.cancel();

    setState(() {
      _voiceEntryId = entryId;
      _callState = _VoiceJournalCallState.success;
    });

    context.read<JournalBloc>().add(LoadJournalEntries());

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _resetVoiceJournal();
    });
  }

  void _onVoiceJournalError(String message) {
    _callTimer?.cancel();
    _statusTimer?.cancel();
    setState(() {
      _callState = _VoiceJournalCallState.error;
      _voiceError = message;
    });

    Future<void>.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      _resetVoiceJournal();
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString()}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildVoiceJournalControl(AppTheme theme) {
    final pulse = _pulseController;

    Widget child;
    switch (_callState) {
      case _VoiceJournalCallState.idle:
        child = SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startVoiceJournal,
            icon: const Icon(Icons.mic),
            label: const Text('Voice Journal'),
          ),
        );
      case _VoiceJournalCallState.connecting:
        child = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary, width: 2),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Starting Call...',
                style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case _VoiceJournalCallState.active:
        child = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary, width: 2),
          ),
          child: Row(
            children: [
              if (pulse != null)
                ScaleTransition(
                  scale: pulse,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: theme.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(_callDurationSeconds),
                style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                onPressed: _endVoiceJournal,
                icon: Icon(Icons.call_end, color: theme.secondary),
                tooltip: 'End Call',
              ),
            ],
          ),
        );
      case _VoiceJournalCallState.saving:
        child = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary, width: 2),
          ),
          child: Row(
            children: [
              SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(color: theme.primary, strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Text(
                'Saving Entry...',
                style: TextStyle(color: theme.text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case _VoiceJournalCallState.success:
        child = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Voice Entry Saved!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      case _VoiceJournalCallState.error:
        child = Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Call Failed',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(_callState),
            child: child,
          ),
        ),
        if (_voiceError != null && _callState == _VoiceJournalCallState.error) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Text(
              _voiceError!,
              style: TextStyle(color: theme.text.withOpacity(0.8)),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = themeProvider.currentTheme;

        return Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Voice Assistant',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Talk to your AI companion',
                    style: TextStyle(
                      color: theme.text.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Voice Interface
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.border),
                    ),
                    child: Column(
                      children: [
                        _buildVoiceJournalControl(theme),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _messageController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Type a message',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _sending
                                ? null
                                : () {
                                    final msg = _messageController.text;
                                    if (msg.trim().isEmpty) return;
                                    _sendMessage(msg);
                                  },
                            child: _sending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Send'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: theme.text.withOpacity(0.8)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (_lastReply != null) ...[
                    Text(
                      'Reply',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        _lastReply!,
                        style: TextStyle(color: theme.text, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (_voiceEntryId != null) ...[
                    Text(
                      'Voice Journal',
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Text(
                        'Journal entry created: $_voiceEntryId',
                        style: TextStyle(color: theme.text),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Quick Commands
                  Text(
                    'Quick Commands',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCommandCard(theme, 'How am I feeling today?', Icons.favorite, onTap: () {
                    _messageController.text = 'How am I feeling today?';
                    _sendMessage(_messageController.text);
                  }),
                  const SizedBox(height: 12),
                  _buildCommandCard(theme, 'I feel overwhelmed. Help me calm down.', Icons.check_box, onTap: () {
                    _messageController.text = 'I feel overwhelmed. Help me calm down.';
                    _sendMessage(_messageController.text);
                  }),
                  const SizedBox(height: 12),
                  _buildCommandCard(theme, 'I feel anxious. What can I do right now?', Icons.sentiment_very_satisfied, onTap: () {
                    _messageController.text = 'I feel anxious. What can I do right now?';
                    _sendMessage(_messageController.text);
                  }),
                  const SizedBox(height: 12),
                  _buildCommandCard(theme, 'Help me relax', Icons.spa, onTap: () {
                    _messageController.text = 'Help me relax';
                    _sendMessage(_messageController.text);
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommandCard(
    AppTheme theme,
    String command,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: _sending ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                command,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: theme.text.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
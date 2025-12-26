import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/retell_livekit_service.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/services/api_client.dart';
import 'dart:async';

class RetellLiveKitDialog extends StatefulWidget {
  final String accessToken;
  final String callId;
  final VoidCallback onCallEnded;

  const RetellLiveKitDialog({
    super.key,
    required this.accessToken,
    required this.callId,
    required this.onCallEnded,
  });

  @override
  State<RetellLiveKitDialog> createState() => _RetellLiveKitDialogState();
}

class _RetellLiveKitDialogState extends State<RetellLiveKitDialog>
    with SingleTickerProviderStateMixin {
  late final RetellLiveKitService _service;
  late final AnimationController _pulseController;
  late StreamSubscription _eventSubscription;
  
  String _callState = 'Initializing...';
  final List<String> _transcriptLines = [];
  int _duration = 0;
  Timer? _durationTimer;
  bool _isAISpeaking = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
    
    _service = RetellLiveKitService();
    _eventSubscription = _service.eventStream.listen(_handleEvent);
    
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _service.startCall(widget.accessToken);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _handleEvent(RetellEvent event) {
    if (!mounted) return;
    
    setState(() {
      switch (event.type) {
        case RetellEventType.connecting:
          _callState = event.message;
          break;
          
        case RetellEventType.connected:
          _callState = 'Connected';
          _startDurationTimer();
          break;
          
        case RetellEventType.participantJoined:
          _callState = 'AI Ready - Speak now!';
          break;
          
        case RetellEventType.audioStarted:
          _isAISpeaking = true;
          _callState = 'AI is speaking...';
          break;
          
        case RetellEventType.transcript:
          // Add new transcript line (limit to last 10 messages)
          _transcriptLines.add(event.message);
          if (_transcriptLines.length > 10) {
            _transcriptLines.removeAt(0);
          }
          _isAISpeaking = false;
          _callState = 'Listening...';
          break;
          
        case RetellEventType.disconnected:
          _callState = 'Call ended';
          _durationTimer?.cancel();
          // Pop dialog and notify parent
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
              widget.onCallEnded();
            }
          });
          break;
          
        case RetellEventType.error:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event.message),
              backgroundColor: Colors.red,
            ),
          );
          break;
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _duration++);
      }
    });
  }

  void _endCall() async {
    await _service.stopCall();
    
    // Create voice journal from call transcript
    try {
      final authService = context.read<AuthService>();
      final userId = authService.currentUser?.id;
      
      if (userId != null) {
        final apiClient = context.read<ApiClient>();
        final response = await apiClient.post(
          '/api/voice-journal/process-latest',
          body: {'user_id': userId},
          authenticated: true,
        );
        
        if (response is Map && response['success'] == true) {
          print('✅ Voice journal created: ${response['journal']?['title']}');
        }
      }
    } catch (e) {
      print('⚠️ Error creating voice journal: $e');
      // Don't show error to user - this is a background operation
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _pulseController.dispose();
    _eventSubscription.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Dialog(
      backgroundColor: theme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.mic, color: theme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Voice Journal',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: theme.text),
                  onPressed: _endCall,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Animated microphone indicator
            ScaleTransition(
              scale: _pulseController,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _service.isConnected
                      ? (_isAISpeaking 
                          ? Colors.blue.withOpacity(0.2)
                          : theme.primary.withOpacity(0.2))
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isAISpeaking ? Icons.volume_up : Icons.mic,
                  size: 50,
                  color: _service.isConnected
                      ? (_isAISpeaking ? Colors.blue : theme.primary)
                      : Colors.grey,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Duration
            if (_duration > 0)
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  color: theme.text,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            const SizedBox(height: 8),
            
            // Status
            Text(
              _callState,
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Live transcript
            if (_transcriptLines.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversation:',
                        style: TextStyle(
                          color: theme.text.withOpacity(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._transcriptLines.map((line) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          line,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          softWrap: true,
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // End call button
            if (_service.isConnected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _endCall,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.call_end, size: 24),
                  label: const Text(
                    'End Call & Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            
            // Loading indicator
            if (!_service.isConnected && _callState != 'Call ended')
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

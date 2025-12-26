import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/services/retell_websocket_client.dart';
import 'dart:async';

class RealtimeVoiceDialog extends StatefulWidget {
  final String accessToken;
  final String callId;
  final VoidCallback onCallEnded;

  const RealtimeVoiceDialog({
    super.key,
    required this.accessToken,
    required this.callId,
    required this.onCallEnded,
  });

  @override
  State<RealtimeVoiceDialog> createState() => _RealtimeVoiceDialogState();
}

class _RealtimeVoiceDialogState extends State<RealtimeVoiceDialog>
    with SingleTickerProviderStateMixin {
  late final RetellWebSocketClient _client;
  late final AnimationController _pulseController;
  
  String _callState = 'Connecting...';
  String _transcript = '';
  int _duration = 0;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.9,
      upperBound: 1.1,
    )..repeat(reverse: true);
    
    _client = RetellWebSocketClient()
      ..onStateChanged = _handleStateChanged
      ..onTranscript = _handleTranscript
      ..onError = _handleError
      ..onCallStarted = _handleCallStarted
      ..onCallEnded = _handleCallEnded;
    
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    try {
      await _client.connect(widget.accessToken);
      await _client.startRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start call: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _handleStateChanged(RetellCallState state) {
    if (!mounted) return;
    
    setState(() {
      switch (state) {
        case RetellCallState.connecting:
          _callState = 'Connecting...';
          break;
        case RetellCallState.connected:
          _callState = 'Connected';
          break;
        case RetellCallState.recording:
          _callState = 'Recording';
          _startDurationTimer();
          break;
        case RetellCallState.disconnected:
          _callState = 'Call Ended';
          _durationTimer?.cancel();
          break;
        case RetellCallState.error:
          _callState = 'Error';
          _durationTimer?.cancel();
          break;
        default:
          _callState = 'Unknown';
      }
    });
  }

  void _handleTranscript(String text) {
    if (!mounted) return;
    setState(() => _transcript = text);
  }

  void _handleError(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleCallStarted() {
    if (!mounted) return;
    setState(() => _callState = 'Active');
  }

  void _handleCallEnded() {
    _durationTimer?.cancel();
    widget.onCallEnded();
    if (mounted) {
      Navigator.of(context).pop();
    }
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
    await _client.disconnect();
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
    _client.dispose();
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
                  color: _callState == 'Recording' || _callState == 'Active'
                      ? theme.primary.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic,
                  size: 50,
                  color: _callState == 'Recording' || _callState == 'Active'
                      ? theme.primary
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
            if (_transcript.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You said:',
                      style: TextStyle(
                        color: theme.text.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _transcript,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // End call button
            if (_callState == 'Recording' || _callState == 'Active')
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
            if (_callState == 'Connecting...')
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

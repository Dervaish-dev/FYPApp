import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/services/services.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';
import 'package:neurocompanion_flutter/widgets/retell_livekit_dialog.dart';

class VoiceJournalButton extends StatefulWidget {
  final VoidCallback? onCallComplete;

  const VoiceJournalButton({
    super.key,
    this.onCallComplete,
  });

  @override
  State<VoiceJournalButton> createState() => _VoiceJournalButtonState();
}

class _VoiceJournalButtonState extends State<VoiceJournalButton> {
  String _callState = 'idle'; // idle, connecting, recording, saving, success, error
  String? _callId; // ignore: unused_field - Used to track current call and reset state

  Future<void> _startVoiceJournal() async {
    setState(() {
      _callState = 'connecting';
    });

    try {
      final voiceJournalService = context.read<VoiceJournalService>();
      
      // Start the voice call (gets Retell call setup from n8n)
      final result = await voiceJournalService.startVoiceJournalCall();
      
      setState(() {
        _callId = result.callId;
        _callState = 'recording';
      });

      // Show LiveKit-based voice dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => RetellLiveKitDialog(
            accessToken: result.accessToken,
            callId: result.callId,
            onCallEnded: () {
              // Dialog handles its own dismissal
              _handleCallEnd(result.callId);
            },
          ),
        );
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _callState = 'error';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start voice journal: $e'),
            backgroundColor: Colors.red,
          ),
        );
        
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() => _callState = 'idle');
        }
      }
    }
  }
  
  void _handleCallEnd(String callId) async {
    if (!mounted) return;
    
    setState(() => _callState = 'saving');
    print('📞 Call ended, checking status for: $callId');

    try {
      final voiceJournalService = context.read<VoiceJournalService>();
      
      // Initial wait for backend to start processing
      await Future.delayed(const Duration(seconds: 2));
      
      // Poll for status (max 45 seconds - matches web frontend)
      for (int i = 0; i < 45; i++) {
        if (!mounted) return;
        
        try {
          final status = await voiceJournalService.getVoiceJournalStatus(callId);
          print('🔍 Checking status (attempt ${i + 1}/45): ${status.status}');
          
          if (status.isCompleted) {
            print('✅ Journal entry completed! EntryId: ${status.entryId}');
            if (!mounted) return;
            setState(() => _callState = 'success');
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Voice journal entry created! ✅'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            
            widget.onCallComplete?.call();
            
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) {
              setState(() {
                _callState = 'idle';
                _callId = null;
              });
            }
            return;
          }
          
          // Check for error status
          if (status.status.toLowerCase().contains('error') || 
              status.status.toLowerCase().contains('failed')) {
            throw Exception('Backend error: ${status.status}');
          }
          
          // Show progress update at 10 second intervals
          if (i > 0 && i % 10 == 0 && mounted) {
            print('⏳ Still waiting... (${i}s elapsed)');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Still processing... (${i}s)'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          
        } catch (statusError) {
          print('⚠️ Error checking status (attempt ${i + 1}): $statusError');
          // Continue polling unless it's a critical error
          if (statusError.toString().contains('Backend error')) {
            rethrow;
          }
        }
        
        await Future.delayed(const Duration(seconds: 1));
      }
      
      // Timeout after 45 seconds - likely backend issue
      print('⏱️ Timeout waiting for journal entry completion');
      throw Exception('Processing is taking longer than expected. Your entry may still be saved - please check your journal in a moment.');
      
    } catch (e) {
      print('❌ Error in _handleCallEnd: $e');
      if (!mounted) return;
      
      setState(() => _callState = 'error');
        
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 6),
        ),
      );
        
      await Future.delayed(const Duration(seconds: 5));
      if (mounted) {
        setState(() {
          _callState = 'idle';
          _callId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    if (_callState == 'saving') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Saving...',
              style: TextStyle(
                color: theme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_callState == 'success') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              'Saved!',
              style: TextStyle(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _callState == 'idle' ? _startVoiceJournal : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary.withOpacity(0.9),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 2,
      ),
      icon: _callState == 'connecting'
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.mic, size: 20),
      label: Text(
        _callState == 'connecting' ? 'Connecting...' : 'Voice Journal',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

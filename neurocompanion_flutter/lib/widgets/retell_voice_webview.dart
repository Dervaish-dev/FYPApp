import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'package:neurocompanion_flutter/providers/theme_provider.dart';

class RetellVoiceWebView extends StatefulWidget {
  final String accessToken;
  final String callId;
  final VoidCallback onCallEnded;

  const RetellVoiceWebView({
    super.key,
    required this.accessToken,
    required this.callId,
    required this.onCallEnded,
  });

  @override
  State<RetellVoiceWebView> createState() => _RetellVoiceWebViewState();
}

class _RetellVoiceWebViewState extends State<RetellVoiceWebView> {
  late final WebViewController _controller;
  String _callState = 'connecting';
  int _duration = 0;
  bool _isLoading = true;
  bool _isSpeakerOn = true; // Speaker mode on by default
  static const platform = MethodChannel('com.neurocompanion/audio');

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _enableSpeakerMode(); // Enable speaker by default
  }

  Future<void> _enableSpeakerMode() async {
    try {
      await platform.invokeMethod('setSpeakerMode', {'enabled': true});
    } catch (e) {
      print('Failed to enable speaker on init: $e');
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          _handleMessage(data);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(_getHtmlContent(), baseUrl: 'https://unpkg.com');
  }

  void _handleMessage(Map<String, dynamic> data) {
    final event = data['event'];
    
    switch (event) {
      case 'log':
        // Suppress excessive "Page script loaded" messages
        final message = data['message'] as String?;
        if (message != null && !message.contains('Page script loaded')) {
          print('[WebView] $message');
        }
        break;
      case 'call_started':
        setState(() => _callState = 'active');
        _startDurationTimer();
        break;
      case 'call_ended':
        setState(() => _callState = 'ended');
        widget.onCallEnded();
        break;
      case 'error':
        setState(() => _callState = 'error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Call error: ${data['message'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }

  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _callState == 'active') {
        setState(() => _duration++);
        _startDurationTimer();
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _endCall() {
    _controller.runJavaScript('stopRetellCall();');
  }

  Future<void> _toggleSpeaker() async {
    try {
      await platform.invokeMethod('setSpeakerMode', {'enabled': !_isSpeakerOn});
      setState(() {
        _isSpeakerOn = !_isSpeakerOn;
      });
    } catch (e) {
      print('Failed to toggle speaker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle speaker: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _getHtmlContent() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="Content-Security-Policy" content="default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;">
  <style>
    body {
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: transparent;
    }
    #status {
      display: none;
    }
  </style>
</head>
<body>
  <div id="status">Loading Retell SDK...</div>
  
  <script>
    let retellClient = null;
    let sdkLoadAttempts = 0;
    const maxSdkLoadAttempts = 30;
    
    // Save original console.log BEFORE overriding it
    window.originalConsoleLog = console.log;
    
    // Log to Flutter for debugging
    console.log = function(...args) {
      try {
        const message = args.join(' ');
        FlutterChannel.postMessage(JSON.stringify({
          event: 'log',
          message: message
        }));
      } catch (e) {
        // Fallback to native console
      }
      // Call original console.log
      window.originalConsoleLog?.apply(console, args);
    };
    
    function sendToFlutter(event, data = {}) {
      try {
        FlutterChannel.postMessage(JSON.stringify({
          event: event,
          ...data
        }));
      } catch (e) {
        console.error('Failed to send to Flutter:', e);
      }
    }
    
    // Wait for SDK to load with retry mechanism
    function waitForRetellSDK() {
      return new Promise((resolve, reject) => {
        const checkSDK = () => {
          sdkLoadAttempts++;
          console.log('🔍 Checking for RetellWebClient... attempt ' + sdkLoadAttempts);
          
          if (typeof RetellWebClient !== 'undefined') {
            console.log('✅ RetellWebClient is available!');
            resolve();
          } else if (sdkLoadAttempts >= maxSdkLoadAttempts) {
            console.error('❌ RetellWebClient not found after ' + maxSdkLoadAttempts + ' attempts');
            reject(new Error('Retell SDK failed to load. Check internet connection.'));
          } else {
            setTimeout(checkSDK, 200);
          }
        };
        checkSDK();
      });
    }
    
    async function initializeRetellCall() {
      try {
        console.log('🎙️ Starting Retell initialization...');
        document.getElementById('status').textContent = 'Waiting for SDK...';
        
        // Wait for SDK to be available
        await waitForRetellSDK();
        
        console.log('🎙️ Creating RetellWebClient instance...');
        document.getElementById('status').textContent = 'Connecting...';
        
        retellClient = new RetellWebClient();
        
        retellClient.on('call_started', () => {
          console.log('📞 Call started event received');
          sendToFlutter('call_started');
        });
        
        retellClient.on('call_ended', () => {
          console.log('📞 Call ended event received');
          sendToFlutter('call_ended');
        });
        
        retellClient.on('error', (error) => {
          console.error('❌ Retell client error:', error);
          sendToFlutter('error', { message: error.message || 'Call error occurred' });
        });
        
        console.log('🎙️ Starting call with access token: ${widget.accessToken.substring(0, 20)}...');
        
        // Start the call with the access token
        const callConfig = {
          accessToken: '${widget.accessToken}',
          sampleRate: 24000
        };
        
        await retellClient.startCall(callConfig);
        
        console.log('✅ Retell call started successfully!');
        document.getElementById('status').textContent = 'Call active';
        
      } catch (error) {
        console.error('❌ Failed to initialize Retell:', error);
        document.getElementById('status').textContent = 'Error: ' + error.message;
        sendToFlutter('error', { message: error.message || 'Failed to start call' });
      }
    }
    
    function stopRetellCall() {
      if (retellClient) {
        try {
          console.log('🛑 Stopping call...');
          retellClient.stopCall();
          console.log('✅ Call stopped');
        } catch (error) {
          console.error('❌ Error stopping call:', error);
        }
      }
    }
    
    // Load SDK dynamically
    function loadRetellSDK() {
      console.log('📦 Loading Retell SDK from unpkg CDN...');
      document.getElementById('status').textContent = 'Loading SDK...';
      
      const script = document.createElement('script');
      script.src = 'https://unpkg.com/retell-client-js-sdk@2.5.0/dist/retell-client-js-sdk.min.js';
      script.crossOrigin = 'anonymous';
      script.async = false;
      
      script.onload = () => {
        console.log('✅ SDK script tag loaded');
        // Give it a moment to parse
        setTimeout(() => {
          initializeRetellCall();
        }, 100);
      };
      
      script.onerror = (error) => {
        console.error('❌ Failed to load SDK script from CDN');
        console.error('Error details:', error);
        sendToFlutter('error', { message: 'Failed to load Retell SDK from CDN. Check internet connection.' });
      };
      
      document.head.appendChild(script);
      console.log('📦 SDK script tag added to page');
    }
    
    // Initialize on page load
    console.log('🚀 Page script loaded');
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', loadRetellSDK);
    } else {
      loadRetellSDK();
    }
  </script>
</body>
</html>
    ''';
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
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _callState == 'active' ? Colors.red : Colors.orange,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_callState == 'active' ? Colors.red : Colors.orange)
                            .withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _callState == 'connecting' ? 'Connecting...' : 
                  _callState == 'active' ? 'Call Active' : 'Call Ended',
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: theme.text),
                  onPressed: () {
                    _endCall();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // WebView (hidden, only for Retell SDK)
            SizedBox(
              height: 0,
              width: 0,
              child: WebViewWidget(controller: _controller),
            ),
            
            // Visual feedback
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  _callState == 'connecting' ? Icons.sync : Icons.mic,
                  size: 60,
                  color: Colors.red,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Duration
            if (_callState == 'active')
              Text(
                _formatDuration(_duration),
                style: TextStyle(
                  color: theme.text,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Status text
            Text(
              _callState == 'connecting' 
                  ? 'Establishing connection...'
                  : _callState == 'active'
                      ? 'Speak naturally about your day'
                      : 'Processing your journal...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.text.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 8),
            
            if (_callState == 'active')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 AI is listening and analyzing your emotions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.text.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Speaker and End call buttons
            if (_callState == 'active')
              Column(
                children: [
                  // Speaker toggle button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _toggleSpeaker,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isSpeakerOn ? theme.primary : theme.text.withOpacity(0.7),
                        side: BorderSide(
                          color: _isSpeakerOn ? theme.primary : theme.text.withOpacity(0.3),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: Icon(
                        _isSpeakerOn ? Icons.volume_up : Icons.phone_in_talk,
                        size: 22,
                      ),
                      label: Text(
                        _isSpeakerOn ? 'Speaker On' : 'Speaker Off (Earpiece)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // End call button
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
                ],
              ),
            
            // Loading indicator
            if (_isLoading || _callState == 'connecting')
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.runJavaScript('stopRetellCall();');
    super.dispose();
  }
}

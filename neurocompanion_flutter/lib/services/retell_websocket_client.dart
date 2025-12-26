import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';

enum RetellCallState {
  idle,
  connecting,
  connected,
  recording,
  disconnected,
  error,
}

class RetellWebSocketClient {
  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  RetellCallState _state = RetellCallState.idle;
  String? _error;
  String _transcript = '';
  
  // Event callbacks
  Function(RetellCallState)? onStateChanged;
  Function(String)? onTranscript;
  Function(String)? onError;
  Function()? onCallStarted;
  Function()? onCallEnded;
  
  StreamSubscription? _recordingSubscription;
  
  RetellCallState get state => _state;
  String? get error => _error;
  String get transcript => _transcript;
  
  /// Connect to Retell WebSocket
  Future<void> connect(String accessToken) async {
    try {
      _setState(RetellCallState.connecting);
      
      // Connect to Retell WebSocket endpoint
      final uri = Uri.parse('wss://api.retellai.com/llm-websocket/$accessToken');
      _channel = WebSocketChannel.connect(uri);
      
      // Listen for messages from Retell
      _channel!.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDone,
      );
      
      _setState(RetellCallState.connected);
      print('✅ Connected to Retell WebSocket');
      
    } catch (e) {
      _handleError('Failed to connect: $e');
    }
  }
  
  /// Start recording and streaming audio
  Future<void> startRecording() async {
    try {
      if (_state != RetellCallState.connected) {
        throw Exception('Not connected to Retell');
      }
      
      // Check permissions
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }
      
      _setState(RetellCallState.recording);
      
      // Start recording with PCM format
      final stream = await _recorder.startStream(const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 24000, // Retell expects 24kHz
        numChannels: 1,     // Mono audio
      ));
      
      // Stream audio chunks to Retell
      _recordingSubscription = stream.listen((audioChunk) {
        _sendAudioChunk(audioChunk);
      });
      
      onCallStarted?.call();
      print('🎤 Started recording and streaming');
      
    } catch (e) {
      _handleError('Failed to start recording: $e');
    }
  }
  
  /// Stop recording
  Future<void> stopRecording() async {
    try {
      await _recordingSubscription?.cancel();
      await _recorder.stop();
      print('🛑 Stopped recording');
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }
  
  /// Send audio chunk to Retell
  void _sendAudioChunk(Uint8List audioData) {
    if (_channel == null || _state != RetellCallState.recording) return;
    
    try {
      // Retell expects raw binary audio data, not JSON-wrapped
      // Send PCM audio directly as binary
      _channel!.sink.add(audioData);
      // print('🎵 Sent ${audioData.length} bytes of audio');
    } catch (e) {
      print('Error sending audio: $e');
    }
  }
  
  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(dynamic message) {
    try {
      // Retell sends both binary audio and text messages
      if (message is List<int>) {
        // Binary audio data from Retell AI
        print('🔊 Received ${message.length} bytes of audio from AI');
        _playAudioResponse(message as List<int>);
      } else if (message is String) {
        // Text message (JSON)
        try {
          final data = jsonDecode(message) as Map<String, dynamic>;
          
          switch (data['type']) {
            case 'transcript':
              // Received transcript update
              final text = data['text'] as String? ?? '';
              final isFinal = data['is_final'] as bool? ?? false;
              
              if (isFinal) {
                _transcript = text;
                onTranscript?.call(text);
                print('📝 Transcript: $text');
              }
              break;
              
            case 'response_audio_done':
              print('✅ AI finished speaking');
              break;
              
            case 'error':
              final errorMsg = data['message'] as String? ?? 'Unknown error';
              _handleError(errorMsg);
              break;
              
            default:
              print('📨 Received message: ${data['type']}');
          }
        } catch (e) {
          print('⚠️ Non-JSON text message: ${message.substring(0, min(100, message.length))}');
        }
      }
    } catch (e) {
      print('Error handling message: $e');
    }
  }
  
  /// Play audio response from Retell
  Future<void> _playAudioResponse(List<int> audioBytes) async {
    try {
      // Retell sends PCM audio - play it directly
      await _player.setAudioSource(
        _BytesAudioSource(audioBytes),
      );
      await _player.play();
      print('▶️ Playing AI response audio');
      
    } catch (e) {
      print('Error playing audio: $e');
    }
  }
  
  /// Handle WebSocket errors
  void _handleWebSocketError(error) {
    print('❌ WebSocket error: $error');
    _handleError('Connection error: $error');
  }
  
  /// Handle WebSocket close
  void _handleWebSocketDone() {
    print('🔌 WebSocket connection closed');
    if (_state == RetellCallState.recording) {
      _handleCallEnded();
    } else {
      _setState(RetellCallState.disconnected);
    }
  }
  
  /// Handle call ended
  void _handleCallEnded() async {
    await stopRecording();
    _setState(RetellCallState.disconnected);
    onCallEnded?.call();
  }
  
  /// Handle errors
  void _handleError(String errorMessage) {
    _error = errorMessage;
    _setState(RetellCallState.error);
    onError?.call(errorMessage);
  }
  
  /// Update state
  void _setState(RetellCallState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }
  
  /// Disconnect and cleanup
  Future<void> disconnect() async {
    try {
      await stopRecording();
      await _player.stop();
      await _channel?.sink.close();
      _setState(RetellCallState.disconnected);
      print('👋 Disconnected from Retell');
    } catch (e) {
      print('Error during disconnect: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _recordingSubscription?.cancel();
    _recorder.dispose();
    _player.dispose();
    _channel?.sink.close();
  }
}

/// Custom audio source for in-memory audio playback
class _BytesAudioSource extends StreamAudioSource {
  final List<int> _bytes;
  
  _BytesAudioSource(this._bytes);
  
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_bytes.sublist(start, end)),
      contentType: 'audio/pcm',
    );
  }
}

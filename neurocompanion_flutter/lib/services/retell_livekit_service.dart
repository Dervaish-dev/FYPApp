import 'package:livekit_client/livekit_client.dart' as livekit;
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';

class RetellLiveKitService {
  livekit.Room? _room;
  bool _connected = false;
  final StreamController<RetellEvent> _eventStreamController =
      StreamController<RetellEvent>.broadcast();

  Stream<RetellEvent> get eventStream => _eventStreamController.stream;
  bool get isConnected => _connected;

  Future<void> startCall(String accessToken) async {
    _eventStreamController.add(RetellEvent(type: RetellEventType.connecting, message: 'Requesting microphone permission...'));
    
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _eventStreamController.add(RetellEvent(type: RetellEventType.error, message: 'Microphone permission denied'));
      return;
    }

    try {
      _eventStreamController.add(RetellEvent(type: RetellEventType.connecting, message: 'Connecting to Retell AI...'));
      
      _room = livekit.Room();
      
      // Set up listeners before connecting
      _setupRoomListeners();
      
      // Connect to Retell LiveKit server
      await _room!.connect(
        'wss://retell-ai-4ihahnq7.livekit.cloud',
        accessToken,
        roomOptions: const livekit.RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      // Enable microphone
      await _room!.localParticipant?.setMicrophoneEnabled(true);
      _connected = true;
      
      _eventStreamController.add(RetellEvent(
        type: RetellEventType.connected, 
        message: 'Connected to Retell AI',
        roomName: _room!.name,
      ));
      
      print('✅ Connected to Retell LiveKit room: ${_room!.name}');
      
    } catch (error) {
      print('❌ Error connecting to Retell: $error');
      _eventStreamController.add(RetellEvent(type: RetellEventType.error, message: 'Connection failed: $error'));
      await stopCall();
    }
  }

  void _setupRoomListeners() {
    _room?.addListener(() {
      final state = _room?.connectionState;
      print('🔄 Room connection state: $state');
      
      if (state == livekit.ConnectionState.disconnected) {
        _eventStreamController.add(RetellEvent(type: RetellEventType.disconnected, message: 'Call ended'));
        stopCall();
      }
    });

    // Listen for participant joined (AI agent)
    _room?.createListener().on<livekit.ParticipantConnectedEvent>((event) {
      print('👤 Participant joined: ${event.participant.identity}');
      _eventStreamController.add(RetellEvent(type: RetellEventType.participantJoined, message: 'AI agent joined'));
    });

    // Listen for audio tracks
    _room?.createListener().on<livekit.TrackSubscribedEvent>((event) {
      if (event.track is livekit.RemoteAudioTrack) {
        print('🔊 Audio track subscribed');
        _eventStreamController.add(RetellEvent(type: RetellEventType.audioStarted, message: 'AI is speaking'));
      }
    });

    // Listen for data messages (transcripts, etc.)
    _room?.createListener().on<livekit.DataReceivedEvent>((event) {
      try {
        final message = String.fromCharCodes(event.data);
        print('📝 Raw data received: $message');
        
        // Try to parse as JSON (Retell sends structured data)
        try {
          final jsonData = json.decode(message);
          
          // Handle different message types from Retell
          if (jsonData is Map) {
            // Check for transcript updates
            if (jsonData.containsKey('transcript') && jsonData['transcript'] != null) {
              final transcript = jsonData['transcript'];
              if (transcript is String && transcript.isNotEmpty) {
                _eventStreamController.add(
                  RetellEvent(type: RetellEventType.transcript, message: transcript)
                );
              }
            }
            // Check for conversation messages
            else if (jsonData.containsKey('text') && jsonData['text'] != null) {
              final text = jsonData['text'];
              final role = jsonData['role'] ?? 'user';
              _eventStreamController.add(
                RetellEvent(
                  type: RetellEventType.transcript, 
                  message: '$role: $text'
                )
              );
            }
            // Fallback: log the full message for debugging
            else {
              print('📝 Unhandled JSON structure: $jsonData');
            }
          }
        } catch (jsonError) {
          // Not JSON, treat as plain text
          if (message.isNotEmpty) {
            _eventStreamController.add(
              RetellEvent(type: RetellEventType.transcript, message: message)
            );
          }
        }
      } catch (e) {
        print('Error parsing data: $e');
      }
    });
  }

  Future<void> stopCall() async {
    if (_connected) {
      _connected = false;
      await _room?.disconnect();
      _eventStreamController.add(RetellEvent(type: RetellEventType.disconnected, message: 'Call ended'));
      print('👋 Disconnected from Retell');
    }
  }

  void dispose() {
    stopCall();
    _eventStreamController.close();
  }
}

enum RetellEventType {
  connecting,
  connected,
  disconnected,
  error,
  participantJoined,
  audioStarted,
  transcript,
}

class RetellEvent {
  final RetellEventType type;
  final String message;
  final String? roomName;

  RetellEvent({
    required this.type,
    required this.message,
    this.roomName,
  });
}

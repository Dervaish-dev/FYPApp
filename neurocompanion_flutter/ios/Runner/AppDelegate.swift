import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Set up audio method channel
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioChannel = FlutterMethodChannel(name: "com.neurocompanion/audio",
                                           binaryMessenger: controller.binaryMessenger)
    
    audioChannel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "setSpeakerMode" {
        guard let args = call.arguments as? [String: Any],
              let enabled = args["enabled"] as? Bool else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "enabled parameter required", details: nil))
          return
        }
        self?.setSpeakerMode(enabled: enabled, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func setSpeakerMode(enabled: Bool, result: @escaping FlutterResult) {
    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth])
      
      if enabled {
        try audioSession.overrideOutputAudioPort(.speaker)
      } else {
        try audioSession.overrideOutputAudioPort(.none)
      }
      
      try audioSession.setActive(true)
      result(true)
    } catch {
      result(FlutterError(code: "AUDIO_ERROR", 
                         message: "Failed to set speaker mode: \(error.localizedDescription)", 
                         details: nil))
    }
  }
}

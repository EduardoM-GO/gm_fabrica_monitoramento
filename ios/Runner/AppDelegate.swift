import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let audioChannelName = "com.gm_fabrica/native_audio"
  private let wakelockChannelName = "com.gm_fabrica/kiosk_wakelock"
  private var playerPools: [String: [AVAudioPlayer]] = [:]
  private var poolIndices: [String: Int] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.isIdleTimerDisabled = true
    configureAudioSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    application.isIdleTimerDisabled = true
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "GmNativeKioskPlugin") {
      registerWakelockChannel(messenger: registrar.messenger())
      registerAudioChannel(messenger: registrar.messenger())
    }
  }

  private func registerWakelockChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: wakelockChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "enableWakeLock" {
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = true
        }
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(
        .playback,
        mode: .default,
        options: [.mixWithOthers]
      )
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      NSLog("GmNativeAudio: Failed to configure AVAudioSession: \(error)")
    }
  }

  private func registerAudioChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: audioChannelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(false)
        return
      }
      switch call.method {
      case "preload":
        let args = call.arguments as? [String: Any]
        let assets = args?["assets"] as? [String] ?? []
        var loaded = 0
        for asset in assets {
          if self.getOrLoadPlayers(for: asset) != nil {
            loaded += 1
          }
        }
        result(loaded)
      case "play":
        let args = call.arguments as? [String: Any]
        guard let asset = args?["asset"] as? String else {
          result(false)
          return
        }
        result(self.playAsset(asset))
      case "reset":
        self.playerPools.removeAll()
        self.poolIndices.removeAll()
        self.configureAudioSession()
        let args = call.arguments as? [String: Any]
        let assets = args?["assets"] as? [String] ?? []
        var loaded = 0
        for asset in assets {
          if self.getOrLoadPlayers(for: asset) != nil {
            loaded += 1
          }
        }
        result(loaded)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func getOrLoadPlayers(for assetPath: String) -> [AVAudioPlayer]? {
    if let existing = playerPools[assetPath], !existing.isEmpty {
      return existing
    }
    let key = FlutterDartProject.lookupKey(forAsset: "assets/\(assetPath)")
    guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
      return nil
    }
    let url = URL(fileURLWithPath: path)
    let copies = assetPath.contains("egg_hit") ? 4 : 2
    var pool: [AVAudioPlayer] = []
    for _ in 0..<copies {
      if let player = try? AVAudioPlayer(contentsOf: url) {
        player.prepareToPlay()
        pool.append(player)
      }
    }
    if !pool.isEmpty {
      playerPools[assetPath] = pool
      poolIndices[assetPath] = 0
      return pool
    }
    return nil
  }

  private func playAsset(_ assetPath: String) -> Bool {
    guard let pool = getOrLoadPlayers(for: assetPath), !pool.isEmpty else {
      return false
    }
    let idx = (poolIndices[assetPath] ?? 0) % pool.count
    poolIndices[assetPath] = idx + 1
    let player = pool[idx]
    if player.isPlaying {
      player.currentTime = 0
    }
    return player.play()
  }
}

import Foundation

/// Which action-agent backend the app talks to. Both speak the same protocol;
/// only the endpoint and token differ.
/// Order matters: `allCases` drives the picker, and the first segment reads as
/// the primary option. Cloud leads because it is the default.
enum AgentBackend: String, CaseIterable {
  case cloud = "Cloud"
  case selfHosted = "Self-hosted"
}

/// The current stable low-latency Live API voice model.
enum VoiceEngine: String, CaseIterable {
  case natural = "natural"

  static let defaultsKey = "voiceEngine"

  var label: String { "Gemini Live" }

  var modelPath: String { "models/gemini-3.8-live" }
}

/// Where video comes from. The app is a vision assistant first -- it opens
/// looking at the world through the phone -- and glasses are one capture
/// source, selected here, rather than a mode the user must decide about at
/// launch. Raw values are stored in UserDefaults under `captureSource`, which
/// views also observe via @AppStorage so a change applies without a relaunch.
enum CaptureSource: String, CaseIterable {
  case iPhoneCamera = "iphone"
  case glasses = "glasses"

  static let defaultsKey = "captureSource"

  var label: String {
    switch self {
    case .iPhoneCamera: return "iPhone Camera"
    case .glasses: return "Glasses"
    }
  }
}

final class SettingsManager {
  static let shared = SettingsManager()

  private let defaults = UserDefaults.standard
  private let secureStore = SecureStore()

  private enum SecretKey: String {
    case geminiAPIKey
    case openClawHookToken
    case openClawGatewayToken
    case cloudGatewayToken
  }

  private enum Key: String {
    case geminiAPIKey
    case agentBackend
    case openClawHost
    case openClawPort
    case openClawHookToken
    case openClawGatewayToken
    case cloudGatewayURL
    case cloudGatewayToken
    case geminiSystemPrompt
    case assistiveMode
    case speakerOutputEnabled
    case videoStreamingEnabled
    case proactiveNotificationsEnabled
  }

  private init() {
    migrateLegacySecrets()
    migrateLegacyDefaultPrompt()
  }

  // MARK: - Gemini

  var geminiAPIKey: *** {
    get { secret(.geminiAPIKey, fallback: Secrets.geminiAPIKey) }
    set { setSecret(newValue, for: .geminiAPIKey) }
  }

  var geminiSystemPrompt: String {
    get {
      let stored = defaults.string(forKey: Key.geminiSystemPrompt.rawValue)
      return GeminiConfig.migratedStoredPrompt(stored ?? GeminiConfig.defaultSystemInstruction)
    }
    set { defaults.set(newValue, forKey: Key.geminiSystemPrompt.rawValue) }
  }

  /// Speech-first scene description for blind and low-vision users. This fork is
  /// prepared for a blind owner, so it defaults on but remains user-configurable.
  var assistiveMode: Bool {
    get { defaults.object(forKey: Key.assistiveMode.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.assistiveMode.rawValue) }
  }

  // MARK: - OpenClaw

  var openClawHost: String {
    get { defaults.string(forKey: Key.openClawHost.rawValue) ?? Secrets.openClawHost }
    set { defaults.set(newValue, forKey: Key.openClawHost.rawValue) }
  }

  var openClawPort: Int {
    get {
      let stored = defaults.integer(forKey: Key.openClawPort.rawValue)
      return stored != 0 ? stored : Secrets.openClawPort
    }
    set { defaults.set(newValue, forKey: Key.openClawPort.rawValue) }
  }

  var openClawHookToken: String {
    get { secret(.openClawHookToken, fallback: Secrets.openClawHookToken) }
    set { setSecret(newValue, for: .openClawHookToken) }
  }

  var openClawGatewayToken: String {
    get { secret(.openClawGatewayToken, fallback: Secrets.openClawGatewayToken) }
    set { setSecret(newValue, for: .openClawGatewayToken) }
  }

  // MARK: - Agent backend selection

  var voiceEngine: VoiceEngine {
    get {
      guard let raw = defaults.string(forKey: VoiceEngine.defaultsKey),
            let engine = VoiceEngine(rawValue: raw) else { return .natural }
      return engine
    }
    set { defaults.set(newValue.rawValue, forKey: VoiceEngine.defaultsKey) }
  }

  var captureSource: CaptureSource {
    get {
      guard let raw = defaults.string(forKey: CaptureSource.defaultsKey),
            let source = CaptureSource(rawValue: raw) else { return .iPhoneCamera }
      return source
    }
    set { defaults.set(newValue.rawValue, forKey: CaptureSource.defaultsKey) }
  }

  /// Cloud by default: the hosted gateway needs nothing installed and keeps
  /// working with the phone away from home, which self-hosting cannot do.
  var agentBackend: AgentBackend {
    get {
      guard let raw = defaults.string(forKey: Key.agentBackend.rawValue),
            let backend = AgentBackend(rawValue: raw) else { return .cloud }
      return backend
    }
    set { defaults.set(newValue.rawValue, forKey: Key.agentBackend.rawValue) }
  }

  /// Full base URL of the hosted gateway, scheme included (e.g. "https://gw.example.com" or "http://1.2.3.4:8788").
  var cloudGatewayURL: String {
    get { defaults.string(forKey: Key.cloudGatewayURL.rawValue) ?? Secrets.cloudGatewayURL }
    set { defaults.set(newValue, forKey: Key.cloudGatewayURL.rawValue) }
  }

  var cloudGatewayToken: String {
    get { secret(.cloudGatewayToken, fallback: Secrets.cloudGatewayToken) }
    set { setSecret(newValue, for: .cloudGatewayToken) }
  }

  // MARK: - Audio

  var speakerOutputEnabled: Bool {
    get { defaults.bool(forKey: Key.speakerOutputEnabled.rawValue) }
    set { defaults.set(newValue, forKey: Key.speakerOutputEnabled.rawValue) }
  }

  // MARK: - Video

  var videoStreamingEnabled: Bool {
    get { defaults.object(forKey: Key.videoStreamingEnabled.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.videoStreamingEnabled.rawValue) }
  }

  // MARK: - Notifications

  var proactiveNotificationsEnabled: Bool {
    get { defaults.object(forKey: Key.proactiveNotificationsEnabled.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.proactiveNotificationsEnabled.rawValue) }
  }

  // MARK: - Secure credential helpers

  private func secret(_ key: SecretKey, fallback: String) -> String {
    (try? secureStore.value(for: key.rawValue)) ?? fallback
  }

  private func setSecret(_ value: String, for key: SecretKey) {
    do {
      if value.isEmpty {
        try secureStore.remove(key.rawValue)
      } else {
        try secureStore.set(value, for: key.rawValue)
      }
      defaults.removeObject(forKey: key.rawValue)
    } catch {
      NSLog("[Settings] Keychain update failed for %@: %@", key.rawValue, error.localizedDescription)
    }
  }

  private func migrateLegacySecrets() {
    let mappings: [(SecretKey, Key)] = [
      (.geminiAPIKey, .geminiAPIKey),
      (.openClawHookToken, .openClawHookToken),
      (.openClawGatewayToken, .openClawGatewayToken),
      (.cloudGatewayToken, .cloudGatewayToken)
    ]
    for (secretKey, legacyKey) in mappings {
      guard let value = defaults.string(forKey: legacyKey.rawValue), !value.isEmpty else { continue }
      if (try? secureStore.value(for: secretKey.rawValue)) == nil {
        try? secureStore.set(value, for: secretKey.rawValue)
      }
      defaults.removeObject(forKey: legacyKey.rawValue)
    }
  }

  private func migrateLegacyDefaultPrompt() {
    guard let stored = defaults.string(forKey: Key.geminiSystemPrompt.rawValue),
          stored == GeminiConfig.legacyDefaultSystemInstruction else { return }
    defaults.set(GeminiConfig.defaultSystemInstruction, forKey: Key.geminiSystemPrompt.rawValue)
  }

  // MARK: - Reset

  func resetAll() {
    for key in [Key.geminiSystemPrompt, .assistiveMode, .agentBackend, .openClawHost, .openClawPort,
                .cloudGatewayURL, .speakerOutputEnabled, .videoStreamingEnabled,
                .proactiveNotificationsEnabled] {
      defaults.removeObject(forKey: key.rawValue)
    }
    for key in [SecretKey.geminiAPIKey, .openClawHookToken, .openClawGatewayToken, .cloudGatewayToken] {
      try? secureStore.remove(key.rawValue)
      defaults.removeObject(forKey: key.rawValue)
    }
  }
}

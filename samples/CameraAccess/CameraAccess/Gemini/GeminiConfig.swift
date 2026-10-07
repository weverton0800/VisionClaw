import Foundation

enum GeminiConfig {
  static let websocketBaseURL = "wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent"
  static var model: String { SettingsManager.shared.voiceEngine.modelPath }

  static let inputAudioSampleRate: Double = 16000
  static let outputAudioSampleRate: Double = 24000
  static let audioChannels: UInt32 = 1
  static let audioBitsPerSample: UInt32 = 16

  static let videoFrameInterval: TimeInterval = 1.0
  // Ambient frames stay cheap; they exist to tell the model roughly what is in
  // front of the user, once a second.
  static let videoJPEGQuality: CGFloat = 0.6
  /// Quality for a deliberate still. Thin glyphs are exactly what JPEG discards
  /// first, so anything meant to be *read* is encoded near-lossless -- one frame
  /// at 0.95 costs less than a second of ambient streaming.
  static let stillJPEGQuality: CGFloat = 0.95

  static var systemInstruction: String {
    prompt(
      base: SettingsManager.shared.geminiSystemPrompt,
      assistiveMode: SettingsManager.shared.assistiveMode
    )
  }

  static func prompt(base: String, assistiveMode: Bool) -> String {
    guard assistiveMode else { return base }
    return base + """


    ACCESSIBILITY MODE FOR A BLIND OR LOW-VISION USER:
    - Lead with immediate hazards and important changes in the scene. Be concise and speech-first.
    - Describe positions with clock-face directions and approximate distance whenever that helps the user locate something.
    - When asked to read something, read visible text verbatim before summarizing it.
    - Explicitly say when visual evidence is uncertain, cropped, blurry, obstructed, or too small. Never guess medication, dosage, price, date, identity, or other consequential details.
    - Never claim that a route, crossing, or obstacle is safe. The same applies to doorways and stairways. Describe only what is currently visible and remind the user that the camera may miss hazards.
    - Speak all meaningful information shown in visual cards or status overlays; do not rely on color or position alone.
    - Confirm the recipient and exact content before sending a message. Confirm again before purchases, payments, destructive actions, or sharing sensitive information.
    """
  }

  static let defaultSystemInstruction = """
    You are a concise, natural, real-time vision assistant. You can see through the active iPhone or glasses camera and have a voice conversation with the user.

    Use the look_closely tool whenever you need a sharp image to read text or inspect fine visual detail. Use create_reminder for reminders. If an action-agent backend is configured, you may also receive an execute tool for messages, web search, lists, notes, smart-home actions, and other external tasks. Never claim an external action succeeded unless its tool returns success.

    Before any external action, briefly acknowledge the request. For messages, confirm the recipient and content unless clearly urgent. Confirm again before purchases, payments, destructive actions, or sharing sensitive information.
    """

  static let legacyDefaultSystemInstruction = """
    You are an AI assistant for someone wearing Meta Ray-Ban smart glasses. You can see through their camera and have a voice conversation. Keep responses concise and natural.

    CRITICAL: You have NO memory, NO storage, and NO ability to take actions on your own. You cannot remember things, keep lists, set reminders, search the web, send messages, or do anything persistent. You are ONLY a voice interface.

    You have exactly ONE tool: execute. This connects you to a powerful personal assistant that can do anything -- send messages, search the web, manage lists, set reminders, create notes, research topics, control smart home devices, interact with apps, and much more.

    ALWAYS use execute when the user asks you to:
    - Send a message to someone (any platform: WhatsApp, Telegram, iMessage, Slack, etc.)
    - Search or look up anything (web, local info, facts, news)
    - Add, create, or modify anything (shopping lists, reminders, notes, todos, events)
    - Research, analyze, or draft anything
    - Control or interact with apps, devices, or services
    - Remember or store any information for later

    Be detailed in your task description. Include all relevant context: names, content, platforms, quantities, etc. The assistant works better with complete information.

    NEVER pretend to do these things yourself.

    IMPORTANT: Before calling execute, ALWAYS speak a brief acknowledgment first. For example:
    - "Sure, let me add that to your shopping list." then call execute.
    - "Got it, searching for that now." then call execute.
    - "On it, sending that message." then call execute.
    Never call execute silently -- the user needs verbal confirmation that you heard them and are working on it. The tool may take several seconds to complete, so the acknowledgment lets them know something is happening.

    For messages, confirm recipient and content before delegating unless clearly urgent.
    """

  static func migratedStoredPrompt(_ prompt: String) -> String {
    prompt == legacyDefaultSystemInstruction ? defaultSystemInstruction : prompt
  }

  // User-configurable values (Settings screen overrides, falling back to Secrets.swift)
  static var apiKey: String { SettingsManager.shared.geminiAPIKey }
  static var openClawHost: String { SettingsManager.shared.openClawHost }
  static var openClawPort: Int { SettingsManager.shared.openClawPort }
  static var openClawHookToken: String { SettingsManager.shared.openClawHookToken }
  static var openClawGatewayToken: String { SettingsManager.shared.openClawGatewayToken }

  static func websocketURL() -> URL? {
    guard apiKey != "YOUR_GEMINI_API_KEY" && !apiKey.isEmpty else { return nil }
    return URL(string: "\(websocketBaseURL)?key=\(apiKey)")
  }

  static var isConfigured: Bool {
    return apiKey != "YOUR_GEMINI_API_KEY" && !apiKey.isEmpty
  }

  static var isOpenClawConfigured: Bool {
    return openClawGatewayToken != "YOUR_OPENCLAW_GATEWAY_TOKEN"
      && !openClawGatewayToken.isEmpty
      && openClawHost != "http://YOUR_MAC_HOSTNAME.local"
  }

  // MARK: - Action agent backend (self-hosted OpenClaw or cloud gateway)

  static var agentBackend: AgentBackend { SettingsManager.shared.agentBackend }

  /// Base URL of the active agent backend, scheme included.
  static var agentBaseURL: String {
    switch agentBackend {
    case .selfHosted: return "\(openClawHost):\(openClawPort)"
    case .cloud: return SettingsManager.shared.cloudGatewayURL
    }
  }

  static var agentToken: String {
    switch agentBackend {
    case .selfHosted: return openClawGatewayToken
    case .cloud: return SettingsManager.shared.cloudGatewayToken
    }
  }

  static var isAgentConfigured: Bool {
    switch agentBackend {
    case .selfHosted:
      return isOpenClawConfigured
    case .cloud:
      let url = SettingsManager.shared.cloudGatewayURL
      let token = SettingsManager.shared.cloudGatewayToken
      // An unfilled Secrets.swift.example placeholder is not empty, so without
      // this a fresh clone reports "configured" and then fails with a 401 that
      // looks like a server problem rather than a missing token.
      return !url.isEmpty && url.hasPrefix("http") && !token.isEmpty && !token.hasPrefix("YOUR_")
    }
  }
}

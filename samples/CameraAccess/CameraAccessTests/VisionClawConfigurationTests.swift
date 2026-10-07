import Foundation
import XCTest

@testable import CameraAccess

final class VisionClawConfigurationTests: XCTestCase {
  func testUsesCurrentStableGeminiLiveModel() {
    XCTAssertEqual(VoiceEngine.natural.modelPath, "models/gemini-3.8-live")
  }

  func testNoLongerOffersRetiredFastLiveModel() {
    XCTAssertEqual(VoiceEngine.allCases, [.natural])
    XCTAssertFalse(VoiceEngine.allCases.map(\.modelPath).contains("models/gemini-live-2.5-flash-preview"))
  }

  func testDirectModeToolDeclarationsDoNotAdvertiseUnavailableAgent() {
    let names = ToolDeclarations.allDeclarations(agentAvailable: false)
      .compactMap { $0["name"] as? String }

    XCTAssertEqual(Set(names), Set(["look_closely", "create_reminder"]))
    XCTAssertFalse(names.contains("execute"))
  }

  func testConnectedAgentAddsExecuteTool() {
    let names = ToolDeclarations.allDeclarations(agentAvailable: true)
      .compactMap { $0["name"] as? String }

    XCTAssertTrue(names.contains("execute"))
  }

  func testUnauthorizedGatewayIsNotConnected() {
    XCTAssertEqual(OpenClawBridge.connectionState(forHTTPStatus: 200), .connected)
    XCTAssertNotEqual(OpenClawBridge.connectionState(forHTTPStatus: 401), .connected)
    XCTAssertNotEqual(OpenClawBridge.connectionState(forHTTPStatus: 403), .connected)
  }

  func testCancelledStartupGenerationCannotResume() {
    var generation = SessionStartupGeneration()
    let first = generation.begin()
    XCTAssertTrue(generation.isCurrent(first))

    generation.cancel()
    XCTAssertFalse(generation.isCurrent(first))
  }

  func testLegacyDefaultPromptMigratesButCustomPromptDoesNot() {
    XCTAssertEqual(
      GeminiConfig.migratedStoredPrompt(GeminiConfig.legacyDefaultSystemInstruction),
      GeminiConfig.defaultSystemInstruction
    )
    XCTAssertEqual(GeminiConfig.migratedStoredPrompt("My custom prompt"), "My custom prompt")
  }

  func testSecureStoreRoundTrip() throws {
    let store = SecureStore(service: "VisionClawTests.\(UUID().uuidString)")
    defer { try? store.remove("api-key") }

    try store.set("secret-value", for: "api-key")
    XCTAssertEqual(try store.value(for: "api-key"), "secret-value")
    try store.remove("api-key")
    XCTAssertNil(try store.value(for: "api-key"))
  }

  func testAssistivePromptPrioritizesBlindUserSafety() {
    let prompt = GeminiConfig.prompt(base: "Base prompt", assistiveMode: true)

    XCTAssertTrue(prompt.contains("Base prompt"))
    XCTAssertTrue(prompt.localizedCaseInsensitiveContains("clock-face"))
    XCTAssertTrue(prompt.localizedCaseInsensitiveContains("read visible text verbatim"))
    XCTAssertTrue(prompt.localizedCaseInsensitiveContains("never claim that a route, crossing, or obstacle is safe"))
    XCTAssertTrue(prompt.localizedCaseInsensitiveContains("uncertain"))
  }

  func testRegularPromptIsUnchangedWhenAssistiveModeIsOff() {
    XCTAssertEqual(GeminiConfig.prompt(base: "Base prompt", assistiveMode: false), "Base prompt")
  }
}

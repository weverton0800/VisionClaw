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
    let names = ToolDeclarations.directModeDeclarations().compactMap { $0["name"] as? String }

    XCTAssertEqual(Set(names), Set(["look_closely", "create_reminder"]))
    XCTAssertFalse(names.contains("execute"))
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

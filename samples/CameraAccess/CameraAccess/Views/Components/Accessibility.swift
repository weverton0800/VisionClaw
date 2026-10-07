/*
 * Shared VoiceOver announcements for dynamic session state.
 */

import SwiftUI
import UIKit

enum A11y {
  static func announce(_ message: String, assertive: Bool = false) {
    guard !message.isEmpty else { return }
    var announcement = AttributedString(message)
    announcement.accessibilitySpeechAnnouncementPriority = assertive ? .high : .default
    AccessibilityNotification.Announcement(announcement).post()
  }
}

import SwiftUI
import AppKit

@main
struct AdderAllNightXRApp: App {
    @StateObject private var manager = CaffeinateManager()

    init() {
        // Equivalent of LSUIElement for `swift run` (no .app bundle).
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(manager: manager)
        } label: {
            MenuBarLabel(manager: manager)
        }
        .menuBarExtraStyle(.menu)
    }
}

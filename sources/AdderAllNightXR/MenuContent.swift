import SwiftUI

struct MenuContent: View {
    @ObservedObject var manager: CaffeinateManager

    var body: some View {
        Text(statusText)

        if let error = manager.lastError {
            Text("⚠️ \(error)")
        }

        Menu("Dosage") {
            ForEach(Dose.presets) { dose in
                Button(dose.title) { manager.activate(dose) }
            }
        }

        Divider()

        Button("Flush system (deactivate)") { manager.deactivate() }
            .disabled(!manager.isActive)

        Divider()

        Button("Quit AdderAllNight XR") { manager.quit() }
    }

    private var statusText: String {
        guard let dose = manager.activeDose else { return "Status: Sleeping / Idle" }
        if let remaining = manager.remaining {
            return "Status: Active (\(dose.shortName) · \(TimeFormat.minutesLeft(remaining)) left)"
        }
        return "Status: Active (\(dose.shortName))"
    }
}

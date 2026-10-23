import SwiftUI

/// Menu bar label: capsule icon, filling with the time left on timed doses.
struct MenuBarLabel: View {
    @ObservedObject var manager: CaffeinateManager

    var body: some View {
        Image(nsImage: CapsuleIcon.image(for: state))
    }

    private var state: CapsuleState {
        guard manager.isActive else { return .idle }
        guard let remaining = manager.remaining, let fraction = manager.remainingFraction else {
            return .extendedRelease
        }
        return .timed(fraction: fraction, label: TimeFormat.minutesLeft(remaining))
    }
}

import AppKit
import Foundation
import os

/// A "prescription": how long the system stays awake.
enum Dose: Equatable, Identifiable {
    case timed(label: String, seconds: Int)
    case extendedRelease

    static let presets: [Dose] = [
        .timed(label: "15mg (15 minutes)", seconds: 900),
        .timed(label: "30mg (30 minutes)", seconds: 1800),
        .timed(label: "60mg (1 hour)", seconds: 3600),
        .timed(label: "90mg (90 minutes)", seconds: 5400),
        .timed(label: "120mg (2 hours)", seconds: 7200),
        .extendedRelease,
    ]

    var id: String {
        switch self {
        case .timed(_, let seconds): return "timed-\(seconds)"
        case .extendedRelease: return "xr"
        }
    }

    var title: String {
        switch self {
        case .timed(let label, _): return label
        case .extendedRelease: return "Extended Release (XR - Indefinite)"
        }
    }

    var seconds: Int? {
        if case .timed(_, let seconds) = self { return seconds }
        return nil
    }

    /// Short label for the status header, e.g. "30mg" or "XR - Indefinite".
    var shortName: String {
        switch self {
        case .timed(let label, _): return label.components(separatedBy: " ").first ?? label
        case .extendedRelease: return "XR - Indefinite"
        }
    }
}

/// Owns the single `caffeinate` child process and publishes its state.
@MainActor
final class CaffeinateManager: ObservableObject {
    static let caffeinatePath = "/usr/bin/caffeinate"

    @Published private(set) var activeDose: Dose?
    @Published private(set) var endDate: Date?
    @Published private(set) var lastError: String?
    /// Seconds left on a timed dose; nil when idle or on indefinite XR.
    @Published private(set) var remaining: TimeInterval?

    var isActive: Bool { activeDose != nil }

    private var process: Process?
    private var tickTimer: Timer?
    private let logger = Logger(subsystem: "xr.adderallnight.app", category: "caffeinate")

    init() {
        // Safety net for exits that bypass `quit()` (e.g. `NSApp.terminate` from elsewhere).
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.terminateProcess() }
        }
    }

    // MARK: - Public actions

    /// Starts a dose, replacing any currently running one.
    func activate(_ dose: Dose) {
        terminateProcess()
        lastError = nil

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: Self.caffeinatePath)

        // -d: prevent display sleep, -i: prevent idle sleep,
        // -w: exit when this app's pid goes away (guards against SIGKILL/crash orphaning).
        var args = ["-di", "-w", String(ProcessInfo.processInfo.processIdentifier)]
        if let seconds = dose.seconds { args += ["-t", String(seconds)] }
        proc.arguments = args

        // Compare by identity so a stale termination can't clobber a newer dose.
        proc.terminationHandler = { [weak self] terminated in
            Task { @MainActor [weak self] in
                self?.handleTermination(of: terminated)
            }
        }

        do {
            try proc.run()
        } catch {
            logger.error("Failed to launch caffeinate: \(error.localizedDescription, privacy: .public)")
            lastError = "Could not launch caffeinate: \(error.localizedDescription)"
            return
        }

        process = proc
        activeDose = dose
        endDate = dose.seconds.map { Date().addingTimeInterval(TimeInterval($0)) }
        startTicking()
        logger.info("Dose started: \(dose.title, privacy: .public)")
    }

    /// "Flush System": stop caffeinate and return to idle.
    func deactivate() {
        terminateProcess()
        resetState()
    }

    /// Kills the child and terminates the app.
    func quit() {
        terminateProcess()
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Internals

    private func terminateProcess() {
        guard let proc = process else { return }
        process = nil // detach first so the termination handler ignores it
        if proc.isRunning {
            proc.terminate()
            proc.waitUntilExit()
        }
    }

    private func handleTermination(of terminated: Process) {
        // Ignore processes we replaced or deliberately killed.
        guard process === terminated else { return }
        process = nil
        if terminated.terminationReason == .exit, terminated.terminationStatus != 0 {
            lastError = "caffeinate exited with status \(terminated.terminationStatus)"
            logger.error("caffeinate exited with status \(terminated.terminationStatus)")
        }
        resetState()
    }

    private func resetState() {
        stopTicking()
        activeDose = nil
        endDate = nil
        remaining = nil
    }

    /// Fraction of the current timed dose still left (0...1); nil for XR or idle.
    var remainingFraction: Double? {
        guard let total = activeDose?.seconds, let remaining else { return nil }
        return min(max(remaining / Double(total), 0), 1)
    }

    private func startTicking() {
        stopTicking()
        guard endDate != nil else { return }
        updateRemaining()
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateRemaining() }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common) // keep ticking while the menu is open
        tickTimer = timer
    }

    private func stopTicking() {
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func updateRemaining() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
    }
}

import Foundation

enum TimeFormat {
    /// Whole minutes left, rounded up and never below 1: "89m" (not "1h 29m").
    static func minutesLeft(_ seconds: TimeInterval) -> String {
        "\(max(Int((seconds / 60).rounded(.up)), 1))m"
    }
}

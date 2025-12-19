import Foundation

enum TimeFormatters {
    // 00:23, 12:05, 59:59
    static func mmss(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

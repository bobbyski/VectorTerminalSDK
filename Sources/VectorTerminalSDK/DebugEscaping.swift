import Foundation

extension String {
    /// Human-readable representation of control characters in debug logs.
    var debugEscapedForVTG: String {
        replacingOccurrences(of: "\u{1B}", with: "ESC")
            .replacingOccurrences(of: "\u{07}", with: "BEL")
    }
}

extension [UInt8] {
    /// Human-readable representation of raw bytes in debug logs.
    var debugEscapedForVTG: String {
        map { byte in
            switch byte {
            case 0x1b:
                return "ESC"
            case 0x20...0x7e:
                return String(UnicodeScalar(byte))
            default:
                return String(format: "0x%02X", byte)
            }
        }
        .joined(separator: " ")
    }
}

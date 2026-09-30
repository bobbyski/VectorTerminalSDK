/// Turns a Windows console's input records into the bytes a pty sends.
///
/// A console in VT input mode already delivers VT sequences. One that does not
/// honour that mode (Wine's, and consoles older than Windows 10 1809) reports
/// arrows, function keys and the mouse as records instead: a key press with no
/// character, or a mouse event. These turn them into the xterm key sequences and
/// SGR mouse reports (`CSI < b ; x ; y M`/`m`) the parsers already read, so the
/// rest of the stack never learns which kind of console it had. Plain integers,
/// so the arithmetic is tested on any platform.
enum ConsoleInputTranslation {
    /// The xterm sequence for a key that types no character, by Windows virtual
    /// key code; nil for a key a terminal would not report.
    ///
    /// Modifiers take xterm's form: `CSI 1 ; m A` and `CSI n ; m ~`, with
    /// m = 1 + shift + 2·alt + 4·ctrl.
    static func keySequence(virtualKey: UInt16, shift: Bool, alt: Bool, ctrl: Bool) -> [UInt8]? {
        let modifier = 1 + (shift ? 1 : 0) + (alt ? 2 : 0) + (ctrl ? 4 : 0)
        func letter(_ final: String, ss3: Bool = false) -> String {
            if modifier > 1 { return "\u{1B}[1;\(modifier)\(final)" }
            return ss3 ? "\u{1B}O\(final)" : "\u{1B}[\(final)"
        }
        func tilde(_ number: Int) -> String {
            modifier > 1 ? "\u{1B}[\(number);\(modifier)~" : "\u{1B}[\(number)~"
        }

        let sequence: String
        switch virtualKey {
        case 0x26: sequence = letter("A")        // VK_UP
        case 0x28: sequence = letter("B")        // VK_DOWN
        case 0x27: sequence = letter("C")        // VK_RIGHT
        case 0x25: sequence = letter("D")        // VK_LEFT
        case 0x24: sequence = letter("H")        // VK_HOME
        case 0x23: sequence = letter("F")        // VK_END
        case 0x2D: sequence = tilde(2)           // VK_INSERT
        case 0x2E: sequence = tilde(3)           // VK_DELETE
        case 0x21: sequence = tilde(5)           // VK_PRIOR (Page Up)
        case 0x22: sequence = tilde(6)           // VK_NEXT (Page Down)
        case 0x70: sequence = letter("P", ss3: true)   // VK_F1
        case 0x71: sequence = letter("Q", ss3: true)
        case 0x72: sequence = letter("R", ss3: true)
        case 0x73: sequence = letter("S", ss3: true)   // VK_F4
        case 0x74: sequence = tilde(15)          // VK_F5
        case 0x75: sequence = tilde(17)
        case 0x76: sequence = tilde(18)
        case 0x77: sequence = tilde(19)
        case 0x78: sequence = tilde(20)
        case 0x79: sequence = tilde(21)          // VK_F10
        case 0x7A: sequence = tilde(23)
        case 0x7B: sequence = tilde(24)          // VK_F12
        default: return nil
        }
        return Array(sequence.utf8)
    }

    /// Console button bits: left, right, middle.
    static let leftButton: UInt32 = 0x1
    static let rightButton: UInt32 = 0x2
    static let middleButton: UInt32 = 0x4

    /// A mouse record as SGR reports, or nil for what a button-event tracking
    /// terminal (mode 1002, which TUIKit asks for) does not report: movement
    /// with no button held, and a record that changes no button.
    ///
    /// - Parameters:
    ///   - column: The cell's column in the visible window, from 0.
    ///   - row: The cell's row in the visible window, from 0.
    ///   - buttons: The console's button bits now.
    ///   - previous: The button bits before this record.
    ///   - moved: Whether the record is movement.
    ///   - wheel: +1 for the wheel turned away from the user, -1 towards, nil
    ///     for no wheel.
    static func mouseSequence(column: Int, row: Int, buttons: UInt32, previous: UInt32,
                              moved: Bool, wheel: Int?, shift: Bool, alt: Bool, ctrl: Bool) -> [UInt8]? {
        let modifiers = (shift ? 4 : 0) + (alt ? 8 : 0) + (ctrl ? 16 : 0)
        func report(_ code: Int, pressed: Bool = true) -> String {
            "\u{1B}[<\(code + modifiers);\(column + 1);\(row + 1)\(pressed ? "M" : "m")"
        }
        let order: [(bit: UInt32, code: Int)] = [(leftButton, 0), (middleButton, 1), (rightButton, 2)]

        if let wheel {
            return Array(report(wheel > 0 ? 64 : 65).utf8)
        }
        if moved {
            guard let held = order.first(where: { buttons & $0.bit != 0 }) else {
                return nil
            }
            return Array(report(32 + held.code).utf8)
        }
        let changed = order.filter { (buttons ^ previous) & $0.bit != 0 }
        guard !changed.isEmpty else {
            return nil
        }
        return Array(changed.map { report($0.code, pressed: buttons & $0.bit != 0) }.joined().utf8)
    }
}

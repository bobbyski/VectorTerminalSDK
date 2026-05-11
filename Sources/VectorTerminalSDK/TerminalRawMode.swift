import Foundation

/// Put stdin into a minimal raw mode and return the previous terminal settings.
func enableRawMode() -> termios? {
    var original = termios()
    guard tcgetattr(STDIN_FILENO, &original) == 0 else {
        return nil
    }
    var raw = original
    // Raw mode keeps input byte-oriented so escape sequences can be parsed
    // without waiting for a newline and without the terminal echoing bytes.
    raw.c_lflag &= ~UInt(ECHO | ICANON)
    raw.c_cc.16 = 1
    raw.c_cc.17 = 0
    guard tcsetattr(STDIN_FILENO, TCSANOW, &raw) == 0 else {
        return nil
    }
    return original
}

/// Restore terminal settings captured by `enableRawMode()`.
func restoreMode(_ mode: termios?) {
    guard var mode else {
        return
    }
    tcsetattr(STDIN_FILENO, TCSANOW, &mode)
}

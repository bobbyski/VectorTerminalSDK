import Darwin
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
    //
    // Earlier versions only cleared ECHO and ICANON. That was enough for
    // keyboard input, but VTG mouse APC responses could still leak into the
    // terminal text plane on some pty states. `cfmakeraw` gives us the normal
    // full-screen TUI behavior: no echo, no signal translation, no CR/LF
    // mapping, and no software flow-control interpretation.
    cfmakeraw(&raw)
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

/// Drain already-delivered input bytes while the app is still in raw mode.
///
/// This is intentionally small and best-effort. Mouse-up/click events can be
/// queued by the host at almost the same moment a graphical app decides to
/// exit. If those bytes are left for the shell after raw mode is restored, they
/// can appear as visible `VTG;mouse...` text or confuse the next launch.
func drainPendingTerminalInput(graceMilliseconds: Int) {
    guard graceMilliseconds > 0 else {
        return
    }

    let deadline = Date().addingTimeInterval(Double(graceMilliseconds) / 1000)
    var pollFD = pollfd(fd: STDIN_FILENO, events: Int16(POLLIN), revents: 0)
    var buffer = [UInt8](repeating: 0, count: 1024)

    while Date() < deadline {
        let remaining = max(1, Int(deadline.timeIntervalSinceNow * 1000))
        let result = poll(&pollFD, 1, Int32(min(remaining, 10)))
        if result < 0 {
            return
        }
        if result == 0 {
            continue
        }
        _ = read(STDIN_FILENO, &buffer, buffer.count)
    }
}

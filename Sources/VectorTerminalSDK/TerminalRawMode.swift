#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
// Static Linux (the musl SDK): the same C library under its own module name.
import Musl
#elseif os(Windows)
import WinSDK
#endif
import Foundation

#if os(Windows)
/// The console's settings as raw mode found them, to put back on the way out.
struct TerminalMode {
    var input: DWORD
    /// Nil when standard output is not a console (redirected).
    var output: DWORD?
    var inputCodePage: UINT
    var outputCodePage: UINT
}

/// Put the console into the raw mode `cfmakeraw` gives a pty, and return the
/// previous settings.
///
/// No line editing, no echo, no Ctrl-C translation (it arrives as 0x03, as in
/// raw mode on a pty), no QuickEdit selection eating mouse clicks. Keys and
/// mouse reports arrive as VT sequences (`ENABLE_VIRTUAL_TERMINAL_INPUT`), so
/// the parsers above read the same bytes they read from a pty; output takes VT
/// sequences and, like a raw pty, a line feed does not return the carriage.
/// Both code pages become UTF-8. Nil when standard input is not a console.
func enableRawMode() -> TerminalMode? {
    let input = GetStdHandle(STD_INPUT_HANDLE)
    let output = GetStdHandle(STD_OUTPUT_HANDLE)
    var inputMode: DWORD = 0
    guard GetConsoleMode(input, &inputMode) else {
        return nil
    }
    var outputMode: DWORD = 0
    let outputIsConsole = GetConsoleMode(output, &outputMode) != false
    let original = TerminalMode(input: inputMode, output: outputIsConsole ? outputMode : nil,
                                inputCodePage: GetConsoleCP(), outputCodePage: GetConsoleOutputCP())

    let cooked = DWORD(ENABLE_LINE_INPUT) | DWORD(ENABLE_ECHO_INPUT) | DWORD(ENABLE_PROCESSED_INPUT)
        | DWORD(ENABLE_QUICK_EDIT_MODE)
    // Mouse records too: a console that reports the mouse as records rather
    // than VT sequences (Wine's) reports nothing without this, and the reader
    // turns the records into SGR reports.
    let raw = (inputMode & ~cooked) | DWORD(ENABLE_MOUSE_INPUT)
        | DWORD(ENABLE_VIRTUAL_TERMINAL_INPUT) | DWORD(ENABLE_EXTENDED_FLAGS) | DWORD(ENABLE_WINDOW_INPUT)
    guard SetConsoleMode(input, raw) else {
        return nil
    }
    if outputIsConsole {
        _ = SetConsoleMode(output, outputMode
            | DWORD(ENABLE_VIRTUAL_TERMINAL_PROCESSING) | DWORD(DISABLE_NEWLINE_AUTO_RETURN))
    }
    _ = SetConsoleCP(UINT(CP_UTF8))
    _ = SetConsoleOutputCP(UINT(CP_UTF8))
    return original
}

/// Restore console settings captured by `enableRawMode()`.
func restoreMode(_ mode: TerminalMode?) {
    guard let mode else {
        return
    }
    _ = SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), mode.input)
    if let output = mode.output {
        _ = SetConsoleMode(GetStdHandle(STD_OUTPUT_HANDLE), output)
    }
    _ = SetConsoleCP(mode.inputCodePage)
    _ = SetConsoleOutputCP(mode.outputCodePage)
}
#else
/// The terminal settings raw mode replaces: a pty's `termios`.
typealias TerminalMode = termios

/// Put stdin into a minimal raw mode and return the previous terminal settings.
func enableRawMode() -> TerminalMode? {
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
func restoreMode(_ mode: TerminalMode?) {
    guard var mode else {
        return
    }
    tcsetattr(STDIN_FILENO, TCSANOW, &mode)
}
#endif

/// Raw mode as a value: entered by `enter()`, put back by `restore()`.
///
/// `cfmakeraw` on a pty; on Windows, the console modes that give the same
/// bytes (see `enableRawMode()`). Public so a terminal UI library enters raw
/// mode the same way everywhere.
public struct TerminalRawMode {
    private let original: TerminalMode

    /// Puts standard input into raw mode. Nil when it is not a terminal.
    public static func enter() -> TerminalRawMode? {
        enableRawMode().map { TerminalRawMode(original: $0) }
    }

    /// Puts back the settings `enter()` found.
    public func restore() {
        restoreMode(original)
    }
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
    #if os(Windows)
    var reader = TerminalInputReader(FileHandle.standardInput)
    while Date() < deadline {
        let remaining = max(1, Int(deadline.timeIntervalSinceNow * 1000))
        let result = reader.wait(timeoutMilliseconds: Int32(min(remaining, 10)))
        if result < 0 {
            return
        }
        if result > 0 {
            _ = reader.readByte()
        }
    }
    #else
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
    #endif
}

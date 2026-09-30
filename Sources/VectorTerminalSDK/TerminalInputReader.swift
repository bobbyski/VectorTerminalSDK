#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif os(Windows)
import WinSDK
#endif
import Foundation

/// Waits for terminal input and reads it a byte at a time.
///
/// Everything that reads the terminal (event polling, query answers, the
/// cursor report) waits for a byte with a timeout and then reads it. On POSIX
/// that is `poll` and `read` on the input's file descriptor. A Windows console
/// has neither, so there it is the console's input handle
/// (`WindowsConsoleInput`), and the input is always the process's standard
/// input: Windows Foundation gives no descriptor for a `FileHandle`.
///
/// Public so a terminal UI library reads the terminal the same way on every
/// platform (TUIKit's driver does, on Windows).
public struct TerminalInputReader: @unchecked Sendable {
    #if os(Windows)
    public init(_ input: FileHandle = .standardInput) {}

    /// Waits up to `timeoutMilliseconds` for a byte; a negative timeout waits
    /// for ever. Answers as `poll` does: 1 when a byte is ready, 0 on timeout,
    /// negative on error.
    public mutating func wait(timeoutMilliseconds: Int32) -> Int32 {
        WindowsConsoleInput.shared.wait(timeoutMilliseconds: timeoutMilliseconds)
    }

    /// Reads one byte, or nil when none could be read.
    public func readByte() -> UInt8? {
        WindowsConsoleInput.shared.readByte()
    }
    #else
    private var pollFD: pollfd

    public init(_ input: FileHandle = .standardInput) {
        pollFD = pollfd(fd: input.fileDescriptor, events: Int16(POLLIN), revents: 0)
    }

    /// Waits up to `timeoutMilliseconds` for a byte; a negative timeout waits
    /// for ever. Answers as `poll` does: 1 when a byte is ready, 0 on timeout,
    /// negative on error.
    public mutating func wait(timeoutMilliseconds: Int32) -> Int32 {
        poll(&pollFD, 1, timeoutMilliseconds)
    }

    /// Reads one byte, or nil when none could be read.
    public func readByte() -> UInt8? {
        var byte: UInt8 = 0
        return read(pollFD.fd, &byte, 1) == 1 ? byte : nil
    }
    #endif
}

#if os(Windows)
/// The console's standard input, shared by every reader.
///
/// Read one input record at a time: a character is passed on as UTF-8, and a
/// key or mouse record a console reports instead of a VT sequence (Wine's, or a
/// console older than VT input mode) is translated into the sequence a pty
/// would send (`ConsoleInputTranslation`). One record can make several bytes;
/// the ones not yet asked for wait here for the next reader, whichever thread
/// it runs on. Input from a pipe or a file (a test, a redirect) is read as
/// bytes.
final class WindowsConsoleInput: @unchecked Sendable {
    static let shared = WindowsConsoleInput()

    private let lock = NSLock()
    private let handle: HANDLE?
    private let fileType: DWORD
    private var pending: [UInt8] = []
    private var highSurrogate: UInt16?
    private var mouseButtons: UInt32 = 0

    private init() {
        handle = GetStdHandle(STD_INPUT_HANDLE)
        fileType = GetFileType(handle)
    }

    func wait(timeoutMilliseconds: Int32) -> Int32 {
        lock.lock()
        let hasPending = !pending.isEmpty
        lock.unlock()
        if hasPending {
            return 1
        }
        let waitsForever = timeoutMilliseconds < 0
        let deadline = GetTickCount64() + UInt64(max(0, timeoutMilliseconds))
        while true {
            let now = GetTickCount64()
            let remaining = waitsForever ? INFINITE : DWORD(deadline > now ? deadline - now : 0)
            switch fileType {
            case DWORD(FILE_TYPE_CHAR):
                // Short slices, and a look at the queue after every one,
                // signalled or not. On Windows the wait alone would do; Wine's
                // console reads the terminal only when asked about input, so
                // there a bare wait never wakes and the keys sit unread (found
                // running the Windows build under CrossOver, 2026-09-30).
                let result = WaitForSingleObject(handle, min(remaining, 50))
                guard result == DWORD(WAIT_OBJECT_0) || result == DWORD(WAIT_TIMEOUT) else {
                    return -1
                }
                if reportableRecordIsWaiting() {
                    return 1
                }
            case DWORD(FILE_TYPE_PIPE):
                var available: DWORD = 0
                guard PeekNamedPipe(handle, nil, 0, nil, &available, nil) else {
                    return -1
                }
                if available > 0 {
                    return 1
                }
                // A pipe cannot be waited on; look again shortly.
                Sleep(1)
            default:
                // A file is always readable; the read says whether it ended.
                return 1
            }
            if !waitsForever && GetTickCount64() >= deadline {
                return 0
            }
        }
    }

    func readByte() -> UInt8? {
        lock.lock()
        defer { lock.unlock() }
        if pending.isEmpty {
            fill()
        }
        return pending.isEmpty ? nil : pending.removeFirst()
    }

    /// Discards the records a pty would not have sent anything for (key-ups,
    /// bare modifier presses, focus, menu and resize records, mouse movement
    /// with no button held) and answers whether one it would is at the front.
    private func reportableRecordIsWaiting() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        var record = INPUT_RECORD()
        var count: DWORD = 0
        while PeekConsoleInputW(handle, &record, 1, &count), count == 1 {
            if translation(of: record) != nil {
                return true
            }
            _ = ReadConsoleInputW(handle, &record, 1, &count)
        }
        return false
    }

    private func fill() {
        if fileType == DWORD(FILE_TYPE_CHAR) {
            // One record at a time, so a reader never takes more than it asks
            // for: a probe reading its reply leaves the keys typed meanwhile
            // in the console for whoever reads next (TUIKit's input thread).
            var record = INPUT_RECORD()
            var count: DWORD = 0
            guard ReadConsoleInputW(handle, &record, 1, &count), count == 1,
                  let bytes = translation(of: record) else {
                return
            }
            if record.EventType == WORD(MOUSE_EVENT) {
                let mouse = record.Event.MouseEvent
                if mouse.dwEventFlags & DWORD(MOUSE_WHEELED) == 0 {
                    mouseButtons = UInt32(mouse.dwButtonState) & 0x7
                }
            }
            if record.EventType == WORD(KEY_EVENT), record.Event.KeyEvent.uChar.UnicodeChar != 0 {
                let unit = record.Event.KeyEvent.uChar.UnicodeChar
                var text = highSurrogate.map { [$0] } ?? []
                highSurrogate = nil
                text += Array(repeating: unit, count: max(1, Int(record.Event.KeyEvent.wRepeatCount)))
                // Half a surrogate pair waits for its other half.
                if let last = text.last, UTF16.isLeadSurrogate(last) {
                    highSurrogate = text.removeLast()
                }
                pending += Array(String(decoding: text, as: UTF16.self).utf8)
            } else {
                pending += bytes
            }
        } else {
            var byte: UInt8 = 0
            var count: DWORD = 0
            if ReadFile(handle, &byte, 1, &count, nil), count == 1 {
                pending.append(byte)
            }
        }
    }

    /// The bytes a pty would have sent for a record, or nil for none. For a
    /// character the bytes are a marker only: `fill()` decodes the character
    /// itself, pairing surrogates across records.
    private func translation(of record: INPUT_RECORD) -> [UInt8]? {
        switch record.EventType {
        case WORD(KEY_EVENT):
            let key = record.Event.KeyEvent
            guard key.bKeyDown != false else {
                return nil
            }
            if key.uChar.UnicodeChar != 0 {
                return [0]
            }
            let state = key.dwControlKeyState
            guard let sequence = ConsoleInputTranslation.keySequence(
                virtualKey: key.wVirtualKeyCode,
                shift: state & DWORD(SHIFT_PRESSED) != 0,
                alt: state & DWORD(LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED) != 0,
                ctrl: state & DWORD(LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED) != 0
            ) else {
                return nil
            }
            return Array(repeating: sequence, count: max(1, Int(key.wRepeatCount))).flatMap { $0 }

        case WORD(MOUSE_EVENT):
            let mouse = record.Event.MouseEvent
            // Buffer coordinates, made relative to the visible window.
            var info = CONSOLE_SCREEN_BUFFER_INFO()
            let hasWindow = GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &info) != false
            let column = Int(mouse.dwMousePosition.X) - (hasWindow ? Int(info.srWindow.Left) : 0)
            let row = Int(mouse.dwMousePosition.Y) - (hasWindow ? Int(info.srWindow.Top) : 0)
            let flags = mouse.dwEventFlags
            let wheeled = flags & DWORD(MOUSE_WHEELED) != 0
            // The wheel's direction is the high word, signed.
            let wheel = wheeled ? (Int16(truncatingIfNeeded: mouse.dwButtonState >> 16) > 0 ? 1 : -1) : nil
            let state = mouse.dwControlKeyState
            return ConsoleInputTranslation.mouseSequence(
                column: column, row: row,
                buttons: UInt32(mouse.dwButtonState) & 0x7, previous: mouseButtons,
                moved: flags & DWORD(MOUSE_MOVED) != 0, wheel: wheel,
                shift: state & DWORD(SHIFT_PRESSED) != 0,
                alt: state & DWORD(LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED) != 0,
                ctrl: state & DWORD(LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED) != 0
            )

        default:
            return nil
        }
    }
}
#endif

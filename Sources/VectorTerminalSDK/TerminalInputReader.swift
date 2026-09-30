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
/// One console read returns UTF-16, which can decode to several UTF-8 bytes;
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
                let result = WaitForSingleObject(handle, remaining)
                if result == DWORD(WAIT_TIMEOUT) {
                    return 0
                }
                guard result == DWORD(WAIT_OBJECT_0) else {
                    return -1
                }
                if characterIsWaiting() {
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

    /// Discards what a console read skips, and would block on: key-ups, bare
    /// modifier presses, focus, menu and resize records. Answers whether a
    /// character is left at the front of the queue.
    private func characterIsWaiting() -> Bool {
        var record = INPUT_RECORD()
        var count: DWORD = 0
        while PeekConsoleInputW(handle, &record, 1, &count), count == 1 {
            if record.EventType == WORD(KEY_EVENT),
               record.Event.KeyEvent.bKeyDown != false,
               record.Event.KeyEvent.uChar.UnicodeChar != 0 {
                return true
            }
            _ = ReadConsoleInputW(handle, &record, 1, &count)
        }
        return false
    }

    private func fill() {
        if fileType == DWORD(FILE_TYPE_CHAR) {
            // One unit at a time, so a reader never takes more than it asks
            // for: a probe reading its reply leaves the keys typed meanwhile
            // in the console for whoever reads next (TUIKit's input thread).
            var units: [UInt16] = [0]
            var count: DWORD = 0
            guard ReadConsoleW(handle, &units, 1, &count, nil), count > 0 else {
                return
            }
            var text = highSurrogate.map { [$0] } ?? []
            highSurrogate = nil
            text += units[0..<Int(count)]
            // Half a surrogate pair waits for its other half.
            if let last = text.last, UTF16.isLeadSurrogate(last) {
                highSurrogate = text.removeLast()
            }
            pending += Array(String(decoding: text, as: UTF16.self).utf8)
        } else {
            var byte: UInt8 = 0
            var count: DWORD = 0
            if ReadFile(handle, &byte, 1, &count, nil), count == 1 {
                pending.append(byte)
            }
        }
    }
}
#endif

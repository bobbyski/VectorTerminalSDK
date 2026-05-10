import Foundation

/// Pixel dimensions reported by VectorTerminal for the graphics canvas.
public struct VTGCanvas: Equatable {
    public var width: Int
    public var height: Int
    public var source: String?
    public var rawResponse: String?

    public init(width: Int, height: Int, source: String? = nil, rawResponse: String? = nil) {
        self.width = width
        self.height = height
        self.source = source
        self.rawResponse = rawResponse
    }

    public var debugDescription: String {
        let sourceText = source.map { " source=\($0)" } ?? ""
        let rawText = rawResponse.map { " raw=\($0.debugEscapedForVTG)" } ?? ""
        return "width=\(width) height=\(height)\(sourceText)\(rawText)"
    }
}

/// Character-cell dimensions for the underlying terminal grid.
///
/// VectorTank needed both coordinate systems: VTG pixels for graphics and
/// terminal rows/columns for text/status sanity checks during resize testing.
public struct TerminalCellSize: Equatable {
    public var columns: Int
    public var rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }
}

public struct VTGColor: Equatable, ExpressibleByStringLiteral {
    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public static let green: VTGColor = "#22c55e"
    public static let blue: VTGColor = "#3b82f6"
    public static let red: VTGColor = "#fb7185"
    public static let cyan: VTGColor = "#5eead4"
    public static let white: VTGColor = "#f8fafc"
    public static let transparent: VTGColor = "none"
}

public struct VTGPoint: Equatable {
    public var x: Int
    public var y: Int

    public init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

public enum VectorTerminalSDKError: Error, LocalizedError {
    case vectorTerminalNotDetected

    public var errorDescription: String? {
        switch self {
        case .vectorTerminalNotDetected:
            return "VectorTerminal graphics support was not detected."
        }
    }
}

public struct VTGMouseEvent: Equatable {
    public var x: Int
    public var y: Int
    public var cellX: Int?
    public var cellY: Int?
    public var isPress: Bool
    public var button: Int
    public var type: String
    public var modifiers: String
    public var scrollX: Int?
    public var scrollY: Int?
    public var rawSequence: String

    public init(
        x: Int,
        y: Int,
        isPress: Bool,
        button: Int = 0,
        cellX: Int? = nil,
        cellY: Int? = nil,
        type: String? = nil,
        modifiers: String = "none",
        scrollX: Int? = nil,
        scrollY: Int? = nil,
        rawSequence: String = ""
    ) {
        self.x = x
        self.y = y
        self.cellX = cellX
        self.cellY = cellY
        self.isPress = isPress
        self.button = button
        self.type = type ?? (isPress ? "down" : "up")
        self.modifiers = modifiers
        self.scrollX = scrollX
        self.scrollY = scrollY
        self.rawSequence = rawSequence
    }

    public var debugDescription: String {
        let cellText = cellX.flatMap { cx in cellY.map { cy in " cell=\(cx),\(cy)" } } ?? ""
        let scrollText = scrollX.flatMap { sx in scrollY.map { sy in " scroll=\(sx),\(sy)" } } ?? ""
        return "button=\(button) type=\(type) x=\(x) y=\(y)\(cellText)\(scrollText) mods=\(modifiers) raw=\(rawSequence.debugEscapedForVTG)"
    }
}

/// Unified input/event type returned by the SDK event readers.
///
/// Real-time demos such as VectorTank use this to drain keyboard, resize, and
/// canvas events inside a frame loop without hand-parsing terminal escape
/// sequences.
public enum VectorTerminalEvent: Equatable {
    case key(UInt8)
    case specialKey(ANSISpecialKey)
    case mouse(VTGMouseEvent)
    case resize(VTGCanvas)
    case canvas(VTGCanvas)
}

/// Small typed subset of ANSI special keys needed by current demos.
///
/// This was added for VectorTank movement so arrow keys could share the same
/// code path as `w`/`s`/`a`/`d`.
public enum ANSISpecialKey: Equatable {
    case up
    case down
    case right
    case left
}

public enum ANSIColor: Int {
    case black = 0
    case red = 1
    case green = 2
    case yellow = 3
    case blue = 4
    case magenta = 5
    case cyan = 6
    case white = 7
}

public final class VectorTerminalCanvas {
    private let output: FileHandle
    private let input: FileHandle
    private let esc = "\u{1B}"
    private let isEnabled: Bool
    public var eventDebugHandler: ((String) -> Void)?

    public init(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput,
        timeoutMilliseconds: Int = 750
    ) throws {
        self.input = input
        self.output = output
        self.isEnabled = true

        guard let response = query("capabilities?", timeoutMilliseconds: timeoutMilliseconds),
              response.contains("_VTG;capabilities") else {
            throw VectorTerminalSDKError.vectorTerminalNotDetected
        }
    }

    public static func noOp(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput
    ) -> VectorTerminalCanvas {
        VectorTerminalCanvas(input: input, output: output, isEnabled: false)
    }

    private init(input: FileHandle, output: FileHandle, isEnabled: Bool) {
        self.input = input
        self.output = output
        self.isEnabled = isEnabled
    }

    public func clear() {
        send("clear")
    }

    public func present() {
        send("present")
    }

    public func line(
        id: String,
        x1: Int,
        y1: Int,
        x2: Int,
        y2: Int,
        stroke: VTGColor = .white,
        width: Int = 1
    ) {
        send("line,id=\(id),x1=\(x1),y1=\(y1),x2=\(x2),y2=\(y2),stroke=\(stroke.rawValue),width=\(width)")
    }

    public func draw(
        id: String,
        points: [VTGPoint],
        stroke: VTGColor = .white,
        width: Int = 1
    ) {
        guard points.count >= 2 else {
            return
        }
        let payload = points.map { "\($0.x),\($0.y)" }.joined(separator: " ")
        send("draw,id=\(id),stroke=\(stroke.rawValue),width=\(width)", payload: payload)
    }

    public func rect(
        id: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("rect,id=\(id),x=\(x),y=\(y),w=\(width),h=\(height),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)")
    }

    public func circle(
        id: String,
        cx: Int,
        cy: Int,
        radius: Int,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("circle,id=\(id),cx=\(cx),cy=\(cy),r=\(radius),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)")
    }

    public func ellipse(
        id: String,
        cx: Int,
        cy: Int,
        rx: Int,
        ry: Int,
        stroke: VTGColor? = .white,
        fill: VTGColor? = nil,
        lineWidth: Int = 1
    ) {
        let strokeValue = stroke?.rawValue ?? "none"
        let fillValue = fill?.rawValue ?? "none"
        send("ellipse,id=\(id),cx=\(cx),cy=\(cy),rx=\(rx),ry=\(ry),stroke=\(strokeValue),fill=\(fillValue),width=\(lineWidth)")
    }

    public func text(
        id: String,
        x: Int,
        y: Int,
        value: String,
        color: VTGColor = .white,
        size: Int = 14
    ) {
        send("text,id=\(id),x=\(x),y=\(y),color=\(color.rawValue),size=\(size)", payload: sanitizedPayload(value))
    }

    public func vectorPrint(
        id: String,
        x: Int,
        y: Int,
        height: Int,
        value: String,
        stroke: VTGColor = .white,
        width: Int = 2
    ) {
        let scale = max(1.0, Double(height) / 7.0)
        let glyphWidth = Int((5.0 * scale).rounded())
        let advance = Int((7.0 * scale).rounded())
        var cursorX = x
        var glyphIndex = 0

        for scalar in value.unicodeScalars {
            let ascii = Int(scalar.value)
            if ascii == 32 {
                cursorX += advance
                continue
            }
            let strokes = vectorGlyphStrokes(for: ascii)
            for (strokeIndex, strokePoints) in strokes.enumerated() {
                let points = strokePoints.map {
                    VTGPoint(
                        x: cursorX + Int((Double($0.x) * scale).rounded()),
                        y: y + Int((Double($0.y) * scale).rounded())
                    )
                }
                draw(id: "\(id)-\(glyphIndex)-\(strokeIndex)", points: points, stroke: stroke, width: width)
            }
            if ascii < 32 || ascii == 127 {
                let code = String(ascii)
                let smallHeight = max(5, Int(Double(height) * 0.34))
                vectorPrint(id: "\(id)-code-\(glyphIndex)", x: cursorX + glyphWidth / 5, y: y + height / 3, height: smallHeight, value: code, stroke: stroke, width: max(1, width - 1))
            }
            cursorX += advance
            glyphIndex += 1
        }
    }

    public func queryCapabilities(timeoutMilliseconds: Int = 750) -> String? {
        query("capabilities?", timeoutMilliseconds: timeoutMilliseconds)
    }

    public func queryCanvas(timeoutMilliseconds: Int = 750) -> VTGCanvas? {
        guard let response = query("canvas?", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseWidthHeight(from: response, source: "canvas?")
    }

    /// Query the best available pixel canvas size.
    ///
    /// VectorTank exposed that real-time apps should not need to care which
    /// VTG query a terminal version supports. Prefer `canvas?`, fall back to
    /// `size?`, then fall back to the canvas fields embedded in
    /// `capabilities?`.
    public func queryCurrentCanvas(timeoutMilliseconds: Int = 750) -> VTGCanvas? {
        if let canvas = queryCanvas(timeoutMilliseconds: timeoutMilliseconds) {
            return canvas
        }
        if let response = query("size?", timeoutMilliseconds: timeoutMilliseconds),
           let canvas = parseWidthHeight(from: response, source: "size?") {
            return canvas
        }
        if let response = queryCapabilities(timeoutMilliseconds: timeoutMilliseconds),
           let canvas = parseCapabilitiesCanvas(from: response, source: "capabilities?") {
            return canvas
        }
        return nil
    }

    /// Read the terminal's current character grid size.
    ///
    /// This is intentionally separate from `queryCurrentCanvas(...)`: VTG
    /// pixels answer "where can I draw?", while terminal cells answer "what is
    /// the text grid doing?".
    public func queryTerminalCellSize() -> TerminalCellSize? {
        var windowSize = winsize()
        guard ioctl(input.fileDescriptor, TIOCGWINSZ, &windowSize) == 0,
              windowSize.ws_col > 0,
              windowSize.ws_row > 0 else {
            return nil
        }
        return TerminalCellSize(columns: Int(windowSize.ws_col), rows: Int(windowSize.ws_row))
    }

    public func enableResizeEvents() {
        send("resizeEvents,enabled=1")
    }

    public func disableResizeEvents() {
        send("resizeEvents,enabled=0")
    }

    public func bell() {
        writeANSI("\u{07}")
    }

    public func writeText(_ value: String) {
        output.write(Data(sanitizedPayload(value).utf8))
    }

    public func withRawInput<T>(_ body: () throws -> T) rethrows -> T {
        let original = enableRawMode()
        defer { restoreMode(original) }
        return try body()
    }

    public func withRawInput<T>(_ body: () async throws -> T) async rethrows -> T {
        let original = enableRawMode()
        defer { restoreMode(original) }
        return try await body()
    }

    public func enterAlternateScreen() {
        writeANSI("\(esc)[?1049h")
    }

    public func leaveAlternateScreen() {
        writeANSI("\(esc)[?1049l")
    }

    public func clearScreen() {
        writeANSI("\(esc)[2J")
    }

    public func clearScrollbackAndScreen() {
        writeANSI("\(esc)[3J\(esc)[2J")
    }

    public func clearLine() {
        writeANSI("\(esc)[2K")
    }

    public func clearToEndOfLine() {
        writeANSI("\(esc)[K")
    }

    public func moveCursor(row: Int, column: Int) {
        writeANSI("\(esc)[\(max(1, row));\(max(1, column))H")
    }

    public func setCursor(row: Int, column: Int) {
        moveCursor(row: row, column: column)
    }

    public func moveCursorUp(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))A")
    }

    public func moveCursorDown(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))B")
    }

    public func moveCursorForward(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))C")
    }

    public func moveCursorBackward(_ count: Int = 1) {
        writeANSI("\(esc)[\(max(1, count))D")
    }

    public func saveCursor() {
        writeANSI("\(esc)7")
    }

    public func restoreCursor() {
        writeANSI("\(esc)8")
    }

    public func hideCursor() {
        writeANSI("\(esc)[?25l")
    }

    public func showCursor() {
        writeANSI("\(esc)[?25h")
    }

    public func resetTextAttributes() {
        writeANSI("\(esc)[0m")
    }

    public func bold(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 1 : 22)m")
    }

    public func underline(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 4 : 24)m")
    }

    public func inverse(_ enabled: Bool = true) {
        writeANSI("\(esc)[\(enabled ? 7 : 27)m")
    }

    public func setForeground(_ color: ANSIColor, bright: Bool = false) {
        writeANSI("\(esc)[\(color.rawValue + (bright ? 90 : 30))m")
    }

    public func setBackground(_ color: ANSIColor, bright: Bool = false) {
        writeANSI("\(esc)[\(color.rawValue + (bright ? 100 : 40))m")
    }

    public func setForegroundRGB(red: Int, green: Int, blue: Int) {
        writeANSI("\(esc)[38;2;\(clampColor(red));\(clampColor(green));\(clampColor(blue))m")
    }

    public func setBackgroundRGB(red: Int, green: Int, blue: Int) {
        writeANSI("\(esc)[48;2;\(clampColor(red));\(clampColor(green));\(clampColor(blue))m")
    }

    public func enableBracketedPaste() {
        writeANSI("\(esc)[?2004h")
    }

    public func disableBracketedPaste() {
        writeANSI("\(esc)[?2004l")
    }

    public func enableFocusReporting() {
        writeANSI("\(esc)[?1004h")
    }

    public func disableFocusReporting() {
        writeANSI("\(esc)[?1004l")
    }

    public func enableMouseReporting() {
        send("mouseEvents,enabled=1,mode=raw")
        writeANSI("\(esc)[?1000h")
        writeANSI("\(esc)[?1006h")
    }

    public func enableMouseReporting(mode: String) {
        send("mouseEvents,enabled=1,mode=\(sanitizedPayload(mode))")
        writeANSI("\(esc)[?1000h")
        writeANSI("\(esc)[?1006h")
    }

    public func disableMouseReporting() {
        send("mouseEvents,enabled=0")
        writeANSI("\(esc)[?1006l")
        writeANSI("\(esc)[?1000l")
    }

    /// Asynchronous event stream for apps that prefer Swift concurrency.
    ///
    /// This path periodically polls capabilities so canvas changes can still
    /// surface even when explicit resize events are not flowing.
    public func events(canvasPollInterval: TimeInterval = 0.5) -> AsyncStream<VectorTerminalEvent> {
        AsyncStream { continuation in
            let inputFD = input.fileDescriptor
            let canvas = self
            let task = Task.detached {
                var escapeBuffer: [UInt8] = []
                var collectingEscape = false
                var lastCanvasPoll = Date.distantPast

                while !Task.isCancelled {
                    var pollFD = pollfd(fd: inputFD, events: Int16(POLLIN), revents: 0)
                    let result = poll(&pollFD, 1, 100)

                    if result <= 0 {
                        if Date().timeIntervalSince(lastCanvasPoll) >= canvasPollInterval {
                            canvas.send("capabilities?")
                            lastCanvasPoll = Date()
                        }
                        continue
                    }

                    var byte: UInt8 = 0
                    guard read(inputFD, &byte, 1) == 1 else {
                        continue
                    }

                    if collectingEscape || byte == 0x1b {
                        collectingEscape = true
                        escapeBuffer.append(byte)
                        if canvas.isCompleteEscape(escapeBuffer) {
                            if let event = canvas.parseEscapeEvent(escapeBuffer) {
                                continuation.yield(event)
                            }
                            escapeBuffer.removeAll(keepingCapacity: true)
                            collectingEscape = false
                        } else if escapeBuffer.count > 8192 {
                            escapeBuffer.removeAll(keepingCapacity: true)
                            collectingEscape = false
                        }
                        continue
                    }

                    continuation.yield(.key(byte))
                }

                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Synchronous event poller for frame-loop based applications.
    ///
    /// VectorTank uses this to drain all currently available input each frame.
    /// A zero timeout means "do not block"; a positive timeout waits for input
    /// up to that many milliseconds.
    public func readEvent(timeoutMilliseconds: Int = 0) -> VectorTerminalEvent? {
        var pollFD = pollfd(fd: input.fileDescriptor, events: Int16(POLLIN), revents: 0)
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000)

        while true {
            let remaining: Int32
            if timeoutMilliseconds <= 0 {
                remaining = 0
            } else {
                remaining = Int32(max(0, Int(deadline.timeIntervalSinceNow * 1000)))
            }

            let result = poll(&pollFD, 1, remaining)
            if result <= 0 {
                return nil
            }

            var byte: UInt8 = 0
            guard read(input.fileDescriptor, &byte, 1) == 1 else {
                return nil
            }

            if byte != 0x1b {
                return .key(byte)
            }

            var escapeBuffer = [byte]
            while !isCompleteEscape(escapeBuffer) {
                if escapeBuffer.count > 8192 {
                    return nil
                }
                let nextTimeout: Int32
                if timeoutMilliseconds <= 0 {
                    nextTimeout = 1
                } else {
                    nextTimeout = Int32(max(1, Int(deadline.timeIntervalSinceNow * 1000)))
                }
                let nextResult = poll(&pollFD, 1, nextTimeout)
                if nextResult <= 0 {
                    return nil
                }
                guard read(input.fileDescriptor, &byte, 1) == 1 else {
                    return nil
                }
                escapeBuffer.append(byte)
            }
            if let event = parseEscapeEvent(escapeBuffer) {
                return event
            }
            if timeoutMilliseconds > 0 && Date() >= deadline {
                return nil
            }
        }
    }

    private func send(_ command: String, payload: String? = nil) {
        guard isEnabled else {
            return
        }
        let sequence: String
        if let payload {
            sequence = "\(esc)_VTG;\(command);\(payload)\(esc)\\"
        } else {
            sequence = "\(esc)_VTG;\(command)\(esc)\\"
        }
        output.write(Data(sequence.utf8))
    }

    private func writeANSI(_ sequence: String) {
        output.write(Data(sequence.utf8))
    }

    private func query(_ command: String, timeoutMilliseconds: Int) -> String? {
        let original = enableRawMode()
        defer { restoreMode(original) }

        send(command)
        guard let bytes = readAPCResponse(timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return String(bytes: bytes, encoding: .utf8)
    }

    private func readAPCResponse(timeoutMilliseconds: Int) -> [UInt8]? {
        var pollFD = pollfd(fd: input.fileDescriptor, events: Int16(POLLIN), revents: 0)
        var collected: [UInt8] = []
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000)

        while Date() < deadline {
            let remaining = max(1, Int(deadline.timeIntervalSinceNow * 1000))
            let result = poll(&pollFD, 1, Int32(remaining))
            if result <= 0 {
                break
            }

            var byte: UInt8 = 0
            guard read(input.fileDescriptor, &byte, 1) == 1 else {
                continue
            }
            collected.append(byte)
            if collected.count >= 2,
               collected[collected.count - 2] == 0x1b,
               collected[collected.count - 1] == UInt8(ascii: "\\") {
                return collected
            }
            if collected.count > 8192 {
                return collected
            }
        }

        return collected.isEmpty ? nil : collected
    }

    private func parseWidthHeight(from response: String, source: String) -> VTGCanvas? {
        let fields = response.split(separator: ",")
        let values = Dictionary(uniqueKeysWithValues: fields.compactMap { field -> (String, String)? in
            let pair = field.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else {
                return nil
            }
            return (String(pair[0]), String(pair[1]))
        })
        guard let width = values["width"].flatMap(Int.init),
              let height = values["height"].flatMap(Int.init) else {
            return nil
        }
        return VTGCanvas(width: width, height: height, source: source, rawResponse: response)
    }

    private func parseCapabilitiesCanvas(from response: String, source: String) -> VTGCanvas? {
        let fields = response.split(separator: ",")
        let values = Dictionary(uniqueKeysWithValues: fields.compactMap { field -> (String, String)? in
            let pair = field.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else {
                return nil
            }
            return (String(pair[0]), String(pair[1]))
        })
        guard let width = values["canvasWidth"].flatMap(Int.init),
              let height = values["canvasHeight"].flatMap(Int.init) else {
            return nil
        }
        return VTGCanvas(width: width, height: height, source: source, rawResponse: response)
    }

    private func parseEscapeEvent(_ bytes: [UInt8]) -> VectorTerminalEvent? {
        if let specialKey = parseSpecialKey(bytes) {
            return .specialKey(specialKey)
        }
        if let sequence = String(bytes: bytes, encoding: .utf8),
           sequence.hasPrefix("\(esc)[<") {
            eventDebugHandler?("SDK parser saw SGR candidate raw=\(sequence.debugEscapedForVTG)")
        }
        if let response = String(bytes: bytes, encoding: .utf8) {
            if response.contains("_VTG;resize"), let canvas = parseWidthHeight(from: response, source: "resize") {
                return .resize(canvas)
            }
            if response.contains("_VTG;canvas"), let canvas = parseWidthHeight(from: response, source: "canvas") {
                return .canvas(canvas)
            }
            if response.contains("_VTG;size"), let canvas = parseWidthHeight(from: response, source: "size") {
                return .canvas(canvas)
            }
            if response.contains("_VTG;capabilities"), let canvas = parseCapabilitiesCanvas(from: response, source: "capabilities") {
                return .canvas(canvas)
            }
            if response.contains("_VTG;mouse"), let mouse = parseVTGMouseEvent(from: response) {
                return .mouse(mouse)
            }
        }
        if let mouse = parseMouseEvent(bytes) {
            return .mouse(mouse)
        }
        return nil
    }

    private func parseSpecialKey(_ bytes: [UInt8]) -> ANSISpecialKey? {
        guard bytes.count >= 3,
              bytes[0] == 0x1b else {
            return nil
        }

        let introducer = bytes[1]
        guard introducer == UInt8(ascii: "[") || introducer == UInt8(ascii: "O"),
              let final = bytes.last else {
            return nil
        }

        switch final {
        case UInt8(ascii: "A"):
            return .up
        case UInt8(ascii: "B"):
            return .down
        case UInt8(ascii: "C"):
            return .right
        case UInt8(ascii: "D"):
            return .left
        default:
            return nil
        }
    }

    /// Parse VectorTerminal-native mouse events.
    ///
    /// These events carry both graphics-pixel and terminal-cell coordinates.
    /// That dual coordinate payload was added after the TicTacToe mouse
    /// debugging pass and is still useful for demos that need live diagnostics.
    private func parseVTGMouseEvent(from response: String) -> VTGMouseEvent? {
        let fields = response.split(separator: ",")
        let values = Dictionary(uniqueKeysWithValues: fields.compactMap { field -> (String, String)? in
            let pair = field.split(separator: "=", maxSplits: 1)
            guard pair.count == 2 else {
                return nil
            }
            return (String(pair[0]), String(pair[1]))
        })
        guard let x = values["x"].flatMap(Int.init),
              let y = values["y"].flatMap(Int.init) else {
            eventDebugHandler?("SDK parser rejected VTG mouse raw=\(response.debugEscapedForVTG)")
            return nil
        }
        let type = values["type"] ?? "down"
        let button = values["button"].flatMap(Int.init) ?? 0
        let cellX = values["cellX"].flatMap(Int.init)
        let cellY = values["cellY"].flatMap(Int.init)
        let modifiers = values["mods"] ?? "none"
        let scrollX = values["scrollX"].flatMap(Int.init)
        let scrollY = values["scrollY"].flatMap(Int.init)
        eventDebugHandler?("SDK parser accepted VTG mouse type=\(type) button=\(button) x=\(x) y=\(y) cell=\(cellX.map(String.init) ?? "?"),\(cellY.map(String.init) ?? "?") scroll=\(scrollX.map(String.init) ?? "?"),\(scrollY.map(String.init) ?? "?") mods=\(modifiers) raw=\(response.debugEscapedForVTG)")
        return VTGMouseEvent(
            x: x,
            y: y,
            isPress: type == "down" || type == "drag" || type == "click",
            button: button,
            cellX: cellX,
            cellY: cellY,
            type: type,
            modifiers: modifiers,
            scrollX: scrollX,
            scrollY: scrollY,
            rawSequence: response
        )
    }

    /// Parse fallback ANSI mouse reports for non-VTG or transitional paths.
    ///
    /// VTG-native mouse events are preferred because they can include pixel
    /// coordinates. The ANSI fallback remains useful for debugging and for
    /// terminals that only emit traditional mouse sequences.
    private func parseMouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
        parseSGRMouseEvent(bytes) ?? parseX10MouseEvent(bytes)
    }

    private func parseSGRMouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
        guard let sequence = String(bytes: bytes, encoding: .utf8) else {
            eventDebugHandler?("SDK parser rejected non-UTF8 CSI bytes count=\(bytes.count)")
            return nil
        }
        guard sequence.hasPrefix("\(esc)[<") else {
            return nil
        }
        guard sequence.hasSuffix("M") || sequence.hasSuffix("m") else {
            eventDebugHandler?("SDK parser rejected SGR without M/m terminator raw=\(sequence.debugEscapedForVTG)")
            return nil
        }
        let body = sequence
            .dropFirst(3)
            .dropLast()
            .split(separator: ";")
        guard body.count == 3,
              let button = Int(body[0]),
              let x = Int(body[1]),
              let y = Int(body[2]) else {
            eventDebugHandler?("SDK parser rejected malformed SGR raw=\(sequence.debugEscapedForVTG)")
            return nil
        }

        let isPress = sequence.hasSuffix("M")
        let isRelease = sequence.hasSuffix("m")
        guard button == 0 || isRelease else {
            eventDebugHandler?("SDK parser ignored non-left press button=\(button) x=\(x) y=\(y) raw=\(sequence.debugEscapedForVTG)")
            return nil
        }
        eventDebugHandler?("SDK parser accepted button=\(button) press=\(isPress) x=\(x) y=\(y) raw=\(sequence.debugEscapedForVTG)")
        return VTGMouseEvent(x: x, y: y, isPress: isPress, button: button, rawSequence: sequence)
    }

    private func parseX10MouseEvent(_ bytes: [UInt8]) -> VTGMouseEvent? {
        guard bytes.count == 6,
              bytes[0] == 0x1b,
              bytes[1] == UInt8(ascii: "["),
              bytes[2] == UInt8(ascii: "M") else {
            return nil
        }

        let button = Int(bytes[3]) - 32
        let x = Int(bytes[4]) - 32
        let y = Int(bytes[5]) - 32
        let isRelease = button == 3
        guard button == 0 || isRelease else {
            eventDebugHandler?("SDK parser ignored X10 button=\(button) x=\(x) y=\(y) raw=\(bytes.debugEscapedForVTG)")
            return nil
        }
        eventDebugHandler?("SDK parser accepted X10 button=\(button) press=\(!isRelease) x=\(x) y=\(y) raw=\(bytes.debugEscapedForVTG)")
        return VTGMouseEvent(
            x: x,
            y: y,
            isPress: !isRelease,
            button: button,
            type: isRelease ? "up" : "down",
            rawSequence: bytes.debugEscapedForVTG
        )
    }

    private func isCompleteEscape(_ bytes: [UInt8]) -> Bool {
        guard bytes.count >= 2, bytes[0] == 0x1b else {
            return false
        }
        // APC responses such as ESC _ VTG;canvas,width=... ESC \ must be
        // collected through the string terminator before parsing.
        if bytes[1] == UInt8(ascii: "_") {
            return bytes.count >= 2 &&
                bytes[bytes.count - 2] == 0x1b &&
                bytes[bytes.count - 1] == UInt8(ascii: "\\")
        }
        // X10 mouse reports have a fixed six-byte form: ESC [ M b x y.
        if bytes.count >= 3,
           bytes[1] == UInt8(ascii: "["),
           bytes[2] == UInt8(ascii: "M") {
            return bytes.count >= 6
        }
        if bytes[1] == UInt8(ascii: "[") {
            guard bytes.count >= 3 else {
                return false
            }
            // SGR mouse reports can contain multi-digit coordinates, so wait
            // for their explicit M/m terminator. This avoids splitting large
            // screen mouse coordinates across multiple bogus events.
            if bytes[2] == UInt8(ascii: "<") {
                guard let last = bytes.last else {
                    return false
                }
                return last == UInt8(ascii: "M") || last == UInt8(ascii: "m")
            }
            // Generic CSI sequence. Important: ESC [ alone is not complete,
            // even though `[` is in the broad final-byte range. Treating it as
            // complete broke down/right arrows during VectorTank testing.
            guard let last = bytes.last else {
                return false
            }
            return last >= 0x40 && last <= 0x7e
        }
        // SS3 sequences cover alternate cursor-key modes such as ESC O A.
        if bytes[1] == UInt8(ascii: "O"),
           let last = bytes.last {
            return bytes.count >= 3 && last >= 0x40 && last <= 0x7e
        }
        return bytes.count > 1
    }

    private func sanitizedPayload(_ value: String) -> String {
        value
            .replacingOccurrences(of: esc, with: "")
            .replacingOccurrences(of: "\u{07}", with: "")
    }

    private func clampColor(_ value: Int) -> Int {
        min(255, max(0, value))
    }
}

private func enableRawMode() -> termios? {
    var original = termios()
    guard tcgetattr(STDIN_FILENO, &original) == 0 else {
        return nil
    }
    var raw = original
    raw.c_lflag &= ~UInt(ECHO | ICANON)
    raw.c_cc.16 = 1
    raw.c_cc.17 = 0
    guard tcsetattr(STDIN_FILENO, TCSANOW, &raw) == 0 else {
        return nil
    }
    return original
}

private func restoreMode(_ mode: termios?) {
    guard var mode else {
        return
    }
    tcsetattr(STDIN_FILENO, TCSANOW, &mode)
}

private func vectorGlyphStrokes(for ascii: Int) -> [[VTGPoint]] {
    let glyph = Character(UnicodeScalar(ascii >= 32 && ascii <= 126 ? ascii : 63)!).uppercased()
    switch glyph {
    case "A": return [p("0,7 0,2 2,0 4,2 4,7"), p("0,4 4,4")]
    case "B": return [p("0,0 0,7 3,7 4,6 4,4 3,3 0,3"), p("3,3 4,2 4,1 3,0 0,0")]
    case "C": return [p("4,1 3,0 1,0 0,1 0,6 1,7 3,7 4,6")]
    case "D": return [p("0,0 0,7 3,7 4,6 4,1 3,0 0,0")]
    case "E": return [p("4,0 0,0 0,7 4,7"), p("0,3 3,3")]
    case "F": return [p("0,7 0,0 4,0"), p("0,3 3,3")]
    case "G": return [p("4,1 3,0 1,0 0,1 0,6 1,7 4,7 4,4 2,4")]
    case "H": return [p("0,0 0,7"), p("4,0 4,7"), p("0,3 4,3")]
    case "I": return [p("0,0 4,0"), p("2,0 2,7"), p("0,7 4,7")]
    case "J": return [p("4,0 4,6 3,7 1,7 0,6")]
    case "K": return [p("0,0 0,7"), p("4,0 0,4 4,7")]
    case "L": return [p("0,0 0,7 4,7")]
    case "M": return [p("0,7 0,0 2,3 4,0 4,7")]
    case "N": return [p("0,7 0,0 4,7 4,0")]
    case "O": return [p("1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0")]
    case "P": return [p("0,7 0,0 3,0 4,1 4,3 3,4 0,4")]
    case "Q": return [p("1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0"), p("2,5 4,7")]
    case "R": return [p("0,7 0,0 3,0 4,1 4,3 3,4 0,4"), p("2,4 4,7")]
    case "S": return [p("4,1 3,0 1,0 0,1 0,3 4,4 4,6 3,7 1,7 0,6")]
    case "T": return [p("0,0 4,0"), p("2,0 2,7")]
    case "U": return [p("0,0 0,6 1,7 3,7 4,6 4,0")]
    case "V": return [p("0,0 2,7 4,0")]
    case "W": return [p("0,0 1,7 2,4 3,7 4,0")]
    case "X": return [p("0,0 4,7"), p("4,0 0,7")]
    case "Y": return [p("0,0 2,3 4,0"), p("2,3 2,7")]
    case "Z": return [p("0,0 4,0 0,7 4,7")]
    case "0": return [p("1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0"), p("1,6 3,1")]
    case "1": return [p("1,1 2,0 2,7"), p("0,7 4,7")]
    case "2": return [p("0,1 1,0 3,0 4,1 4,3 0,7 4,7")]
    case "3": return [p("0,0 4,0 2,3 4,4 4,6 3,7 1,7 0,6")]
    case "4": return [p("4,7 4,0 0,5 4,5")]
    case "5": return [p("4,0 0,0 0,3 3,3 4,4 4,6 3,7 1,7 0,6")]
    case "6": return [p("4,1 3,0 1,0 0,1 0,6 1,7 3,7 4,6 4,4 3,3 0,3")]
    case "7": return [p("0,0 4,0 1,7")]
    case "8": return [p("1,0 3,0 4,1 4,2 3,3 1,3 0,2 0,1 1,0"), p("1,3 3,3 4,4 4,6 3,7 1,7 0,6 0,4 1,3")]
    case "9": return [p("4,6 3,7 1,7 0,6 0,4 1,3 4,3 4,1 3,0 1,0 0,1")]
    case "-": return [p("0,3 4,3")]
    case ":": return [p("2,2 2,2"), p("2,5 2,5")]
    default: return [p("0,0 4,0 4,7 0,7 0,0")]
    }
}

private func p(_ encoded: String) -> [VTGPoint] {
    encoded.split(separator: " ").compactMap { pair in
        let values = pair.split(separator: ",", maxSplits: 1)
        guard values.count == 2,
              let x = Int(values[0]),
              let y = Int(values[1]) else {
            return nil
        }
        return VTGPoint(x: x, y: y)
    }
}

private extension String {
    var debugEscapedForVTG: String {
        replacingOccurrences(of: "\u{1B}", with: "ESC")
            .replacingOccurrences(of: "\u{07}", with: "BEL")
    }
}

private extension [UInt8] {
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

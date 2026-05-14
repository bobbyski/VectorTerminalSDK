import Foundation

extension VectorTerminalCanvas {
    /// Return the raw VTG capabilities response, if the host answers.
    public func queryCapabilities(timeoutMilliseconds: Int = 750) -> String? {
        query("capabilities?", timeoutMilliseconds: timeoutMilliseconds)
    }

    /// Query the current VTG pixel canvas size with the direct `canvas?` command.
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

    /// Subscribe to VTG resize events from VectorTerminal.
    public func enableResizeEvents() {
        send("resizeEvents,enabled=1")
    }

    /// Disable VTG resize events from VectorTerminal.
    public func disableResizeEvents() {
        send("resizeEvents,enabled=0")
    }

    /// Send a VTG query and wait for one APC response.
    func query(_ command: String, timeoutMilliseconds: Int) -> String? {
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

    /// Parse `width=...` and `height=...` fields from a VTG APC response.
    func parseWidthHeight(from response: String, source: String) -> VTGCanvas? {
        let values = vtgFields(from: response)
        guard let width = values["width"].flatMap(Int.init),
              let height = values["height"].flatMap(Int.init) else {
            return nil
        }
        return VTGCanvas(width: width, height: height, source: source, rawResponse: response)
    }

    /// Parse canvas dimensions embedded in the VTG capabilities response.
    func parseCapabilitiesCanvas(from response: String, source: String) -> VTGCanvas? {
        let values = vtgFields(from: response)
        guard let width = values["canvasWidth"].flatMap(Int.init),
              let height = values["canvasHeight"].flatMap(Int.init) else {
            return nil
        }
        return VTGCanvas(width: width, height: height, source: source, rawResponse: response)
    }

    /// Parse comma-separated VTG APC fields while stripping the APC envelope.
    ///
    /// Query and event responses arrive as complete strings such as
    /// `ESC _ VTG;resize,width=100,height=80 ESC \`. The parser needs the raw
    /// response for diagnostics, but field values must not include the trailing
    /// string terminator. Centralizing that cleanup prevents the final field
    /// from becoming values like `"80ESC\"`.
    func vtgFields(from response: String) -> [String: String] {
        var content = response
        let prefix = "\(esc)_VTG;"
        if content.hasPrefix(prefix) {
            content.removeFirst(prefix.count)
        }
        let suffix = "\(esc)\\"
        if content.hasSuffix(suffix) {
            content.removeLast(suffix.count)
        }

        return Dictionary(uniqueKeysWithValues: content.split(separator: ",").compactMap { field -> (String, String)? in
            let pair = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard pair.count == 2 else {
                return nil
            }
            return (String(pair[0]), String(pair[1]))
        })
    }

}

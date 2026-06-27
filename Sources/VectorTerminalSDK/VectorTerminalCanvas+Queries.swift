import Foundation

/// VTG query convenience APIs.
extension VectorTerminalCanvas {
    /// Return the raw VTG capabilities response, if the host answers.
    public func queryCapabilities(timeoutMilliseconds: Int = 750) -> String? {
        query("capabilities?", timeoutMilliseconds: timeoutMilliseconds)
    }

    /// Return a parsed VTG capabilities response, if the host answers.
    public func queryCapabilityInfo(timeoutMilliseconds: Int = 750) -> VTGCapabilities? {
        guard let response = queryCapabilities(timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseCapabilities(from: response)
    }

    /// Query the current VTG pixel canvas size with the direct `canvas?` command.
    public func queryCanvas(timeoutMilliseconds: Int = 750) -> VTGCanvas? {
        guard let response = query("canvas?", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseWidthHeight(from: response, source: "canvas?")
    }

    /// Query the current VTG pixel canvas size with the legacy `size?` command.
    ///
    /// Prefer `queryCanvas(...)` or `queryCurrentCanvas(...)` for new code.
    /// This one-to-one wrapper exists for compatibility, diagnostics, and
    /// escape-sequence coverage audits.
    public func querySize(timeoutMilliseconds: Int = 750) -> VTGCanvas? {
        guard let response = query("size?", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseWidthHeight(from: response, source: "size?")
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
        if let canvas = querySize(timeoutMilliseconds: timeoutMilliseconds) {
            return canvas
        }
        if let response = queryCapabilities(timeoutMilliseconds: timeoutMilliseconds),
           let canvas = parseCapabilitiesCanvas(from: response, source: "capabilities?") {
            return canvas
        }
        return nil
    }

    /// Query whether the host is currently rendering retained graphics layers.
    public func areGraphicsLayersVisible(timeoutMilliseconds: Int = 750) -> Bool? {
        guard let response = query("graphicsVisible?", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseGraphicsLayersVisible(from: response)
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

}

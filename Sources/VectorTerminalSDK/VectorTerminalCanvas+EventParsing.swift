import Foundation

extension VectorTerminalCanvas {
    /// Parse a complete escape sequence into an SDK event.
    func parseEscapeEvent(_ bytes: [UInt8]) -> VectorTerminalEvent? {
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
            if let frame = parseVTGFrameEvent(from: response) {
                return .frame(frame)
            }
        }
        if let mouse = parseMouseEvent(bytes) {
            return .mouse(mouse)
        }
        return nil
    }

    /// Parse common cursor-key escape sequences.
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
        let values = vtgFields(from: response)
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
        let hitID = values["hit"]
        let targetID = values["target"]
        let viewportLayer = values["viewportLayer"].flatMap(Int.init)
        let virtualX = values["virtualX"].flatMap(Int.init)
        let virtualY = values["virtualY"].flatMap(Int.init)
        eventDebugHandler?("SDK parser accepted VTG mouse type=\(type) button=\(button) x=\(x) y=\(y) cell=\(cellX.map(String.init) ?? "?"),\(cellY.map(String.init) ?? "?") scroll=\(scrollX.map(String.init) ?? "?"),\(scrollY.map(String.init) ?? "?") hit=\(hitID ?? "none") target=\(targetID ?? "none") viewport=\(viewportLayer.map(String.init) ?? "none") virtual=\(virtualX.map(String.init) ?? "?"),\(virtualY.map(String.init) ?? "?") mods=\(modifiers) raw=\(response.debugEscapedForVTG)")
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
            hitID: hitID,
            targetID: targetID,
            viewportLayer: viewportLayer,
            virtualX: virtualX,
            virtualY: virtualY,
            rawSequence: response
        )
    }

    /// Parse graphics-only offscreen frame lifecycle responses.
    private func parseVTGFrameEvent(from response: String) -> VTGFrameEvent? {
        guard let type = ["frameStarted", "frameCommitted", "frameCanceled", "frameTimeout", "frameRejected"]
            .first(where: { response.contains("_VTG;\($0)") }) else {
            return nil
        }
        let values = vtgFields(from: response)
        guard let id = values["id"], id.isEmpty == false else {
            return nil
        }
        return VTGFrameEvent(
            type: type,
            id: id,
            reason: values["reason"],
            timeoutMilliseconds: values["timeout"].flatMap(Int.init),
            rawResponse: response
        )
    }

    /// Determine whether enough bytes have arrived to parse one escape sequence.
    func isCompleteEscape(_ bytes: [UInt8]) -> Bool {
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
}

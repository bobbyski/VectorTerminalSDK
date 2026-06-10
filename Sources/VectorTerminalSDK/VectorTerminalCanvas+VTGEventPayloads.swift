import Foundation

extension VectorTerminalCanvas {
    /// Parse common cursor-key escape sequences.
    func parseSpecialKey(_ bytes: [UInt8]) -> ANSISpecialKey? {
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
    func parseVTGMouseEvent(from response: String) -> VTGMouseEvent? {
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
    func parseVTGFrameEvent(from response: String) -> VTGFrameEvent? {
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
}

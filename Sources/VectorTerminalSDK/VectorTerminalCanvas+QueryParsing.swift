import Foundation

/// VTG query-response parsing helpers.
extension VectorTerminalCanvas {
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

    /// Parse the versioned flat VTG capabilities response into a typed value.
    func parseCapabilities(from response: String) -> VTGCapabilities {
        let values = vtgFields(from: response)
        return VTGCapabilities(
            protocolName: values["protocol"],
            schema: values["schema"],
            version: values["version"],
            renderer: values["renderer"],
            canvas: parseCapabilitiesCanvas(from: response, source: "capabilities?"),
            commands: pipeList(values["commands"]),
            planned: pipeList(values["planned"]),
            primitives: pipeList(values["primitives"]),
            underTextPrimitives: pipeList(values["underText"]),
            formats: pipeList(values["formats"]),
            raster: pipeList(values["raster"]),
            sprites: pipeList(values["sprites"]),
            layers: values["layers"],
            defaultLayer: values["defaultLayer"].flatMap(Int.init),
            textPlane: values["textPlane"],
            layerScroll: values["layerScroll"].map(parseBool),
            layerAlpha: values["layerAlpha"],
            clip: values["clip"],
            hit: values["hit"],
            events: pipeList(values["events"]),
            colors: pipeList(values["colors"]),
            rawResponse: response
        )
    }

    /// Parse the `graphicsVisible?` response.
    func parseGraphicsLayersVisible(from response: String) -> Bool? {
        let values = vtgFields(from: response)
        return (values["visible"] ?? values["enabled"]).map(parseBool)
    }

    /// Parse the `glyphSize?` response.
    func parseTerminalGlyphSize(from response: String) -> TerminalGlyphSize? {
        let values = vtgFields(from: response)
        guard let width = values["width"].flatMap(Double.init),
              let height = values["height"].flatMap(Double.init) else {
            return nil
        }
        return TerminalGlyphSize(width: width, height: height)
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

    private func pipeList(_ value: String?) -> [String] {
        value?
            .split(separator: "|")
            .map(String.init) ?? []
    }

    func parseBool(_ value: String) -> Bool {
        switch value.lowercased() {
        case "1", "true", "yes", "on":
            return true
        default:
            return false
        }
    }
}

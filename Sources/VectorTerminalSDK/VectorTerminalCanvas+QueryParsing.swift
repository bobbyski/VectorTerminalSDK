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

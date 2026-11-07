import Foundation

/// What may hide a graphics layer (`layerOcclude`, WINDOW_PLAN.md Phase 1).
public enum VTGOcclusionMode: String, Equatable, Sendable {
    /// Nothing hides the layer: graphics above text, as VTG has always drawn.
    case none
    /// Terminal cells with ink — a visible character, a colored background,
    /// inverse, underline — hide the layer, cell by cell. A text menu printed
    /// over a picture then covers it, as it would on paper.
    case ink
}

extension VectorTerminalCanvas {
    /// Let terminal text hide a graphics layer, or stop it doing so.
    ///
    /// The layer keeps its place in the stack; it is simply not drawn inside
    /// any cell that holds ink. Cells left blank in the default colors do not
    /// count — a window whose inside is plain spaces still shows graphics
    /// through it, which is what VTG windows (``createWindow(id:columns:rows:x:y:title:border:shadow:)``)
    /// are for.
    ///
    /// Sends `layerOcclude,layer=<n>,by=ink|none`. A layer outside `-1...4` is
    /// silently ignored. Check ``VTGCapabilities/supportsTextOcclusion`` first:
    /// an older terminal ignores the command and keeps graphics on top.
    ///
    /// - Parameters:
    ///   - layer: The layer, `-1...4`.
    ///   - mode: What may hide it.
    public func setLayerOcclusion(_ layer: Int, by mode: VTGOcclusionMode) {
        guard isSupportedVTGLayer(layer) else {
            return
        }
        send("layerOcclude,layer=\(layer),by=\(mode.rawValue)")
    }
}

extension VTGCapabilities {
    /// Fields the terminal appended after the shapes this type models.
    private var appendedFields: [String: String] {
        var fields: [String: String] = [:]
        var body = rawResponse
        if let start = body.range(of: "_VTG;") {
            body = String(body[start.upperBound...])
        }
        if body.hasSuffix("\u{1B}\\") {
            body = String(body.dropLast(2))
        }
        for part in body.split(separator: ",") {
            let pair = part.split(separator: "=", maxSplits: 1)
            if pair.count == 2 {
                fields[String(pair[0])] = String(pair[1])
            }
        }
        return fields
    }

    /// What can hide a layer, from `occlusion=`; empty on older terminals.
    public var occlusion: [String] {
        (appendedFields["occlusion"] ?? "").split(separator: "|").map(String.init)
    }

    /// Whether `layerOcclude,by=ink` works here.
    public var supportsTextOcclusion: Bool {
        occlusion.contains("ink")
    }

    /// VTG windows, from `windows=`: `experimental` today, nil where the
    /// terminal does not composite windows.
    public var windows: String? {
        appendedFields["windows"]
    }

    /// Whether this terminal composites VTG windows.
    public var supportsWindows: Bool {
        windows != nil
    }

    /// The most windows a program may have at once, from `windowMax=`.
    public var windowMax: Int? {
        appendedFields["windowMax"].flatMap(Int.init)
    }

    /// Raster-mode features, from `rasterText=`: `erases` when text written
    /// over raster drawing erases it (``VectorTerminalCanvas/enterRasterMode(textErases:)``).
    public var rasterTextErases: Bool {
        appendedFields["rasterText"] == "erases"
    }
}

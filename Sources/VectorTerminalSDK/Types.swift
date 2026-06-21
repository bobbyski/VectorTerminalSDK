import Foundation

/// Pixel dimensions reported by VectorTerminal for the graphics canvas.
public struct VTGCanvas: Equatable {
    /// Canvas width in VTG pixel coordinates.
    public var width: Int

    /// Canvas height in VTG pixel coordinates.
    public var height: Int

    /// Query or event source that produced this size, when known.
    public var source: String?

    /// Raw VTG response used to produce the parsed value, when captured.
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
    /// Number of terminal text columns currently visible.
    public var columns: Int

    /// Number of terminal text rows currently visible.
    public var rows: Int

    public init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }
}

/// Pixel dimensions for SDK-rendered vector text.
///
/// `width` is the horizontal advance consumed by a string. `height` is the
/// requested glyph height passed to `vectorPrint(...)`, clamped to the same
/// minimum scale used by rendering.
public struct VTGTextSize: Equatable {
    /// Width in VTG pixels.
    public var width: Int

    /// Height in VTG pixels.
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

/// Named layer values for VTG drawing commands.
///
/// Layer -1 is the under-text graphics plane. Layer 0 is reserved for the
/// future shared text/graphics plane. Layers 1-4 are the current overlay layers,
/// with layer 1 as the default. These constants intentionally remain `Int`
/// values so they can be passed directly to existing SDK methods that accept
/// `layer: Int?`.
public enum VTGLayer {
    /// Native graphics plane below terminal glyphs.
    public static let underText = -1

    /// Reserved future shared text/graphics plane.
    public static let textPlane = 0

    /// Default overlay layer used by drawing calls that omit `layer:`.
    public static let defaultOverlay = 1

    /// First overlay layer.
    public static let overlay1 = 1

    /// Second overlay layer.
    public static let overlay2 = 2

    /// Third overlay layer.
    public static let overlay3 = 3

    /// Fourth overlay layer.
    public static let overlay4 = 4

    /// Inclusive range accepted by the VTG protocol.
    public static let supportedRange = underText...overlay4

    /// Overlay layers that can scroll, fade, and use fixed-resolution viewports.
    public static let overlayRange = overlay1...overlay4

    /// Human-readable layer range advertised in VTG capabilities.
    public static let advertisedRange = "\(underText)-\(overlay4)"

    /// Clamp arbitrary user input into the VTG layer range.
    public static func clamped(_ layer: Int) -> Int {
        min(supportedRange.upperBound, max(supportedRange.lowerBound, layer))
    }

    /// Return whether a layer is accepted by VTG drawing commands.
    public static func isSupported(_ layer: Int) -> Bool {
        supportedRange.contains(layer)
    }

    /// Return whether a layer can currently scroll independently.
    public static func isScrollable(_ layer: Int) -> Bool {
        overlayRange.contains(layer)
    }
}

/// Scale behavior for fixed-resolution overlay compatibility layers.
///
/// Fixed viewports are intended for old-game style demos that want to draw to
/// a stable virtual resolution and let VectorTerminal scale overlay layers to
/// the current window. Layer 0 is excluded because terminal text remains native.
public enum VTGViewportScaleMode: String {
    /// Preserve aspect ratio and fit the full virtual viewport inside the canvas.
    case fit

    /// Preserve aspect ratio and fill the available canvas, cropping overflow.
    case fill

    /// Preserve aspect ratio with an integer scale factor for pixel art.
    case integer

    /// Stretch the virtual viewport independently in each axis.
    case stretch
}

/// Sampling hint for uploaded raster sprite assets.
public enum VTGSpriteFilter: String {
    /// Preserve image-like smoothing when scaling sprites.
    case smooth

    /// Prefer crisp nearest-neighbor sampling for pixel art.
    case nearest
}

/// Errors thrown by SDK initialization.
public enum VectorTerminalSDKError: Error, LocalizedError {
    /// The SDK did not receive a VTG capabilities response during initialization.
    case vectorTerminalNotDetected

    public var errorDescription: String? {
        switch self {
        case .vectorTerminalNotDetected:
            return "VectorTerminal graphics support was not detected."
        }
    }
}

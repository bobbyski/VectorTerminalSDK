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

/// Named layer values for VTG drawing commands.
///
/// Layer 0 is reserved for the future shared text/graphics plane. Layers 1-4
/// are the current overlay layers, with layer 1 as the default. These constants
/// intentionally remain `Int` values so they can be passed directly to existing
/// SDK methods that accept `layer: Int?`.
public enum VTGLayer {
    public static let textPlane = 0
    public static let defaultOverlay = 1
    public static let overlay1 = 1
    public static let overlay2 = 2
    public static let overlay3 = 3
    public static let overlay4 = 4

    public static let supportedRange = textPlane...overlay4
    public static let overlayRange = overlay1...overlay4
    public static let advertisedRange = "\(textPlane)-\(overlay4)"

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
    case fit
    case fill
    case integer
    case stretch
}

/// Errors thrown by SDK initialization.
public enum VectorTerminalSDKError: Error, LocalizedError {
    case vectorTerminalNotDetected

    public var errorDescription: String? {
        switch self {
        case .vectorTerminalNotDetected:
            return "VectorTerminal graphics support was not detected."
        }
    }
}

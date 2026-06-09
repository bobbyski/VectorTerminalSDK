import Foundation

/// Public status advertised for VTG layer `0`.
///
/// Layer `0` is accepted by the wire protocol today, but `reserved` tells
/// applications not to treat it as a stable shared text/graphics plane yet.
public enum VTGTextPlaneStatus: Equatable {
    /// The terminal accepts layer `0`, but app-facing text-plane semantics are
    /// not finalized.
    case reserved

    /// A future terminal may advertise a named app-facing text-plane feature
    /// set. Unknown values are preserved so new terminals can be observed by
    /// older SDK builds.
    case other(String)

    public init(_ rawValue: String?) {
        switch rawValue?.lowercased() {
        case "reserved":
            self = .reserved
        case .some(let value):
            self = .other(value)
        case .none:
            self = .other("")
        }
    }

    public var rawValue: String {
        switch self {
        case .reserved:
            return "reserved"
        case .other(let value):
            return value
        }
    }

    /// Whether applications should avoid depending on layer `0` semantics.
    public var isReserved: Bool {
        self == .reserved
    }
}

/// Parsed VTG capability response.
///
/// `primitives` describes the broad retained-scene drawing surface. The
/// narrower `underTextPrimitives` set describes which primitives are native on
/// layer `-1` beneath terminal glyphs.
public struct VTGCapabilities: Equatable {
    public var protocolName: String?
    public var schema: String?
    public var version: String?
    public var renderer: String?
    public var canvas: VTGCanvas?
    public var commands: [String]
    public var planned: [String]
    public var primitives: [String]
    public var underTextPrimitives: [String]
    public var formats: [String]
    public var raster: [String]
    public var sprites: [String]
    public var layers: String?
    public var defaultLayer: Int?
    public var textPlane: String?
    public var textPlaneStatus: VTGTextPlaneStatus {
        VTGTextPlaneStatus(textPlane)
    }
    public var layerScroll: Bool?
    public var layerAlpha: String?
    public var clip: String?
    public var hit: String?
    public var events: [String]
    public var colors: [String]
    public var rawResponse: String

    public init(
        protocolName: String? = nil,
        schema: String? = nil,
        version: String? = nil,
        renderer: String? = nil,
        canvas: VTGCanvas? = nil,
        commands: [String] = [],
        planned: [String] = [],
        primitives: [String] = [],
        underTextPrimitives: [String] = [],
        formats: [String] = [],
        raster: [String] = [],
        sprites: [String] = [],
        layers: String? = nil,
        defaultLayer: Int? = nil,
        textPlane: String? = nil,
        layerScroll: Bool? = nil,
        layerAlpha: String? = nil,
        clip: String? = nil,
        hit: String? = nil,
        events: [String] = [],
        colors: [String] = [],
        rawResponse: String
    ) {
        self.protocolName = protocolName
        self.schema = schema
        self.version = version
        self.renderer = renderer
        self.canvas = canvas
        self.commands = commands
        self.planned = planned
        self.primitives = primitives
        self.underTextPrimitives = underTextPrimitives
        self.formats = formats
        self.raster = raster
        self.sprites = sprites
        self.layers = layers
        self.defaultLayer = defaultLayer
        self.textPlane = textPlane
        self.layerScroll = layerScroll
        self.layerAlpha = layerAlpha
        self.clip = clip
        self.hit = hit
        self.events = events
        self.colors = colors
        self.rawResponse = rawResponse
    }
}

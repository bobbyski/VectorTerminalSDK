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
    /// Protocol name advertised by the terminal, normally `VTG`.
    public var protocolName: String?

    /// Capability schema identifier, such as `vtg.capabilities.v1`.
    public var schema: String?

    /// VTG protocol implementation version.
    public var version: String?

    /// Renderer backend name reported by the terminal.
    public var renderer: String?

    /// Pixel canvas dimensions embedded in the capabilities response.
    public var canvas: VTGCanvas?

    /// Command names advertised as implemented by the terminal.
    public var commands: [String]

    /// Command names advertised as planned but not yet implemented.
    public var planned: [String]

    /// Graphics primitive categories supported by the retained VTG scene.
    public var primitives: [String]

    /// Primitive categories that can render on layer `-1` beneath text.
    public var underTextPrimitives: [String]

    /// Raster image payload formats accepted by the terminal.
    public var formats: [String]

    /// Raster image feature tokens advertised by the terminal.
    public var raster: [String]

    /// Sprite feature tokens advertised by the terminal.
    public var sprites: [String]

    /// Human-readable supported layer range, such as `-1-4`.
    public var layers: String?

    /// Default drawing layer advertised by the terminal.
    public var defaultLayer: Int?

    /// Raw text-plane status value advertised for layer `0`.
    public var textPlane: String?

    public var textPlaneStatus: VTGTextPlaneStatus {
        VTGTextPlaneStatus(textPlane)
    }

    /// Whether layer scrolling is advertised.
    public var layerScroll: Bool?

    /// Layer-alpha support descriptor, typically `1-4`.
    public var layerAlpha: String?

    /// Layer clipping support descriptor.
    public var clip: String?

    /// Hit-region support descriptor.
    public var hit: String?

    /// Event categories advertised by the terminal.
    public var events: [String]

    /// Color formats accepted by drawing commands.
    public var colors: [String]

    /// Raw capabilities response for diagnostics and forward compatibility.
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

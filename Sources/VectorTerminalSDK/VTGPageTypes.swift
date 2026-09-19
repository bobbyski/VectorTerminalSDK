import Foundation

// Value types for VTG Page Mode (VPM): an off-screen page that floats above
// the terminal, drawn into while hidden and shown when ready.

/// A Page Mode or rich-text event from the terminal: `pageBegan`,
/// `pageOpened`, `pageShown`, `pageHidden`, `pageClosed`, `pageGrew`,
/// `pageResized`, `pageScrolled`, `pageEnded`, `pageError`, `pageRejected`.
///
/// Delivered through ``VectorTerminalCanvas/pageEventHandler``.
public struct VTGPageEvent: Equatable {
    /// The event name, such as `pageOpened`.
    public var name: String
    /// Every `key=value` field of the event.
    public var fields: [String: String]
    /// The complete response, for diagnostics.
    public var rawResponse: String

    public init(name: String, fields: [String: String], rawResponse: String = "") {
        self.name = name
        self.fields = fields
        self.rawResponse = rawResponse
    }

    /// The page, layer, or session the event concerns.
    public var id: String? { fields["id"] }
    /// Why a page ended, was rejected, or failed.
    public var reason: String? { fields["reason"] }
    /// The buffer slot, `A` or `B`, for `pageOpened` and `pageShown`.
    public var slot: String? { fields["slot"] }
    /// Page extent, for `pageOpened`, `pageGrew`, and `pageResized`.
    public var width: Double? { fields["w"].flatMap(Double.init) }
    public var height: Double? { fields["h"].flatMap(Double.init) }
    /// Scroll origin, for `pageScrolled`.
    public var scrollX: Double? { fields["x"].flatMap(Double.init) }
    public var scrollY: Double? { fields["y"].flatMap(Double.init) }

    /// Whether a response name belongs to this channel.
    static func isPageEventName(_ name: String) -> Bool {
        name.hasPrefix("page") || name == "textMeasure" || name == "fonts" || name == "windowCanvas"
    }
}

/// How big one axis of a page is when it opens.
public enum VTGPageExtent: Equatable {
    /// The terminal window's text area, fixed.
    case window
    /// Starts at the window's size and grows to fit what is drawn.
    case growable
    /// A fixed size in pixels.
    case pixels(Int)
    /// A fixed size in terminal cells.
    case cells(Int)
}

/// Where the visible page composites.
public enum VTGPageStacking: String {
    /// Above everything, including VTG overlay layers.
    case all
    /// Above terminal text, beneath VTG overlay layers.
    case text
}

/// What a page does when the terminal window resizes.
public enum VTGPageResizePolicy: String {
    /// Axes sized from the window follow it; explicit sizes stay.
    case auto
    case fixed
    case followWidth
    case followViewport
}

/// Whether a page layer scrolls with the page or stays pinned to the view.
public enum VTGPageLayerScrollMode: String {
    case page
    case fixed
}

/// Which axes the user's wheel or trackpad scrolls.
public enum VTGPageScrollAxis: String {
    case both
    case x
    case y
}

/// How `copyPageLayer` brings a layer in from another page.
public enum VTGPageLayerCopyMode: String {
    /// Shared and read-only here; the owner's changes appear everywhere.
    case reference
    /// An independent snapshot.
    case copy
}

/// Where ordinary drawing commands go while page mode is active.
public enum VTGPageDrawTarget: String {
    case page
    case base
}

/// An edge to scroll a page to.
public enum VTGPageEdge: String {
    case top
    case bottom
    case left
    case right
}

/// The answer to ``VectorTerminalCanvas/queryPageState(id:timeoutMilliseconds:)``.
public struct VTGPageState: Equatable {
    public var id: String
    public var slot: String
    public var width: Double
    public var height: Double
    public var growsWidth: Bool
    public var growsHeight: Bool
    public var scrollX: Double
    public var scrollY: Double
    public var alpha: Double
    /// `#RRGGBBAA`, or `none` for a transparent page.
    public var background: String
    public var isVisible: Bool
    /// Layer ids in drawing order.
    public var layers: [String]
    public var rawResponse: String

    public init(
        id: String,
        slot: String,
        width: Double,
        height: Double,
        growsWidth: Bool,
        growsHeight: Bool,
        scrollX: Double,
        scrollY: Double,
        alpha: Double,
        background: String,
        isVisible: Bool,
        layers: [String],
        rawResponse: String = ""
    ) {
        self.id = id
        self.slot = slot
        self.width = width
        self.height = height
        self.growsWidth = growsWidth
        self.growsHeight = growsHeight
        self.scrollX = scrollX
        self.scrollY = scrollY
        self.alpha = alpha
        self.background = background
        self.isVisible = isVisible
        self.layers = layers
        self.rawResponse = rawResponse
    }
}

extension VTGCapabilities {
    /// Page Mode features the terminal advertises in `page=`. Empty when the
    /// terminal has no page mode.
    public var pageFeatures: [String] {
        Self.pipeField("page", in: rawResponse)
    }

    /// Rich-text features the terminal advertises in `text=`.
    public var textFeatures: [String] {
        Self.pipeField("text", in: rawResponse)
    }

    /// Whether the terminal supports VTG Page Mode. Check this before
    /// ``VectorTerminalCanvas/beginPageMode(id:stacking:)``.
    public var supportsPageMode: Bool {
        pageFeatures.contains("buffers2")
    }

    /// Whether the terminal draws `styledText`, `attrText`, and `textBox`.
    public var supportsRichText: Bool {
        textFeatures.contains("styled")
    }

    /// Read a `|`-separated field out of the raw response. Derived rather
    /// than stored, so the public initializer is unchanged.
    private static func pipeField(_ key: String, in response: String) -> [String] {
        let trimmed = response
            .replacingOccurrences(of: "\u{1B}\\", with: "")
        for field in trimmed.split(separator: ",") {
            let pair = field.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if pair.count == 2, pair[0] == Substring(key) {
                return pair[1].split(separator: "|").map(String.init)
            }
        }
        return []
    }
}

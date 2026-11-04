import Foundation

// Value types for VTG rich text: styles, attributed runs, measurements.

/// Horizontal alignment of rich text.
public enum VTGTextAlignment: String {
    /// Align lines to the left edge.
    case left
    /// Center each line.
    case center
    /// Align lines to the right edge.
    case right
    /// Justify lines to the width. Current hosts lay this out as `left`.
    case justify
}

/// Vertical placement inside a text box.
public enum VTGTextVerticalAlignment: String {
    /// Place text at the top of the box.
    case top
    /// Center text vertically in the box.
    case middle
    /// Place text at the bottom of the box.
    case bottom
}

/// What `y` means for styled and attributed text. `top` matches ``VectorTerminalCanvas/text(id:x:y:value:color:size:layer:)``.
public enum VTGTextBaseline: String {
    /// `y` is the top of the text. The host default.
    case top
    /// `y` is the alphabetic baseline of the first line.
    case alphabetic
    /// `y` is the vertical middle of the text.
    case middle
    /// `y` is the bottom of the text.
    case bottom
}

/// How text breaks at the available width.
public enum VTGTextWrap: String {
    /// Break between words.
    case word
    /// Break between any two characters.
    case char
    /// Never break; lines break only at newlines.
    case none
}

/// What a text box does with text that does not fit its height.
public enum VTGTextOverflow: String {
    /// Drop lines that do not fit the box's height.
    case clip
    /// Grow the box to fit the text.
    case grow
    /// Drop lines that do not fit and end the last visible line with an ellipsis.
    case ellipsis
}

/// Underline appearance.
public enum VTGTextUnderline: String {
    /// No underline.
    case none
    /// One solid line.
    case single
    /// Two solid lines.
    case double
    /// A wavy line.
    case curly
    /// A dotted line.
    case dotted
    /// A dashed line.
    case dashed
}

/// A set of text attributes. Unset fields cascade from the style below.
///
/// With an `id`, it is a named style defined once with
/// ``VectorTerminalCanvas/defineTextStyle(_:)`` and referenced by runs;
/// without one it can still be passed inline.
public struct VTGTextStyle: Equatable {
    /// The style name, used by ``VectorTerminalCanvas/defineTextStyle(_:)``
    /// and as the `style=` reference; `nil` for an inline-only style.
    public var id: String?
    /// Parent style to cascade from.
    public var inherit: String?
    /// A family name, or `sans`, `serif`, `mono`, `terminal`.
    public var font: String?
    /// Font size, in pixels. Values of zero or less are not sent.
    public var size: Double?
    /// 100 through 900.
    public var weight: Int?
    /// Whether to use an italic slant; `false` forces a normal slant.
    public var italic: Bool?
    /// Text color.
    public var color: VTGColor?
    /// Background color behind the text.
    public var background: VTGColor?
    /// Extra space between characters, in pixels.
    public var tracking: Double?
    /// Distance between baselines, in pixels. Values of zero or less are not sent.
    public var lineHeight: Double?
    /// Underline appearance.
    public var underline: VTGTextUnderline?
    /// Underline color.
    public var underlineColor: VTGColor?
    /// Whether to draw a strikethrough line.
    public var strike: Bool?
    /// Create a text style. Every attribute defaults to `nil`, meaning
    /// unset: it cascades from the parent or base style.
    ///
    /// - Parameters:
    ///   - id: The style name, or `nil` for an inline-only style.
    ///   - inherit: Parent style to cascade from.
    ///   - font: A family name, or `sans`, `serif`, `mono`, `terminal`.
    ///   - size: Font size, in pixels.
    ///   - weight: Font weight, 100 through 900; clamped when sent.
    ///   - italic: Whether to use an italic slant.
    ///   - color: Text color.
    ///   - background: Background color behind the text.
    ///   - tracking: Extra space between characters, in pixels.
    ///   - lineHeight: Distance between baselines, in pixels.
    ///   - underline: Underline appearance.
    ///   - underlineColor: Underline color.
    ///   - strike: Whether to draw a strikethrough line.

    public init(
        id: String? = nil,
        inherit: String? = nil,
        font: String? = nil,
        size: Double? = nil,
        weight: Int? = nil,
        italic: Bool? = nil,
        color: VTGColor? = nil,
        background: VTGColor? = nil,
        tracking: Double? = nil,
        lineHeight: Double? = nil,
        underline: VTGTextUnderline? = nil,
        underlineColor: VTGColor? = nil,
        strike: Bool? = nil
    ) {
        self.id = id
        self.inherit = inherit
        self.font = font
        self.size = size
        self.weight = weight
        self.italic = italic
        self.color = color
        self.background = background
        self.tracking = tracking
        self.lineHeight = lineHeight
        self.underline = underline
        self.underlineColor = underlineColor
        self.strike = strike
    }
}

/// Attributed text assembled from runs that each name a style.
///
/// ```swift
/// let text = VTGAttributedText()
///     .append("Chapter 1", style: "h1")
///     .newline()
///     .append("The page is a document.", style: "body")
/// ```
///
/// Encodes to the wire's length-prefixed runs, so no character in the text
/// needs escaping.
public struct VTGAttributedText: Equatable {
    /// One piece of attributed text: a style id and the text drawn in it.
    public struct Run: Equatable {
        /// A style id, `-` for the command's base style, or `NL` for a break.
        public var style: String
        /// The run's text, with no newlines or control characters.
        public var text: String
    }

    /// The runs, in order.
    public private(set) var runs: [Run] = []

    /// Create empty attributed text.
    public init() {}

    /// Create attributed text from one string in one style.
    ///
    /// - Parameters:
    ///   - text: The text; each newline becomes a line break.
    ///   - style: A style id, or `nil` for the command's base style.
    public init(_ text: String, style: String? = nil) {
        self = VTGAttributedText().append(text, style: style)
    }

    /// Add text in a named style, or the base style when `style` is `nil`.
    ///
    /// Each newline becomes a line break, and control characters are
    /// removed. An invalid style name (empty, over 64 characters, not
    /// letters, digits, `_` or `-`, or `NL`) falls back to the base style.
    ///
    /// - Parameters:
    ///   - text: The text to add.
    ///   - style: A style id, or `nil` for the command's base style.
    /// - Returns: A copy with the new runs appended; the original is unchanged.
    public func append(_ text: String, style: String? = nil) -> VTGAttributedText {
        var copy = self
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        for (index, line) in lines.enumerated() {
            if index > 0 {
                copy.runs.append(Run(style: "NL", text: ""))
            }
            let cleaned = String(line).filter { character in
                character.unicodeScalars.allSatisfy { $0.value >= 0x20 && $0.value != 0x7F }
            }
            if !cleaned.isEmpty {
                copy.runs.append(Run(style: Self.validStyle(style) ?? "-", text: cleaned))
            }
        }
        return copy
    }

    /// Add a line break.
    ///
    /// - Returns: A copy with a break run appended; the original is unchanged.
    public func newline() -> VTGAttributedText {
        var copy = self
        copy.runs.append(Run(style: "NL", text: ""))
        return copy
    }

    /// The `style:length:text` wire form.
    public var encoded: String {
        runs.map { "\($0.style):\($0.text.utf8.count):\($0.text)" }.joined()
    }

    private static func validStyle(_ style: String?) -> String? {
        guard let style, !style.isEmpty, style.count <= 64,
              style.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") }),
              style != "NL" else {
            return nil
        }
        return style
    }
}

/// The answer to a text measurement.
public struct VTGTextMeasurement: Equatable {
    /// Measured width, in pixels.
    public var width: Double
    /// Measured height, in pixels.
    public var height: Double
    /// Number of laid-out lines; zero when the host did not report it.
    public var lineCount: Int
    /// Baselines from the top of the measured frame.
    public var firstBaseline: Double
    /// The last line's baseline, in pixels from the top of the measured frame.
    public var lastBaseline: Double
    /// Whether a box dropped or shortened lines.
    public var truncated: Bool
    /// The families the host actually used.
    public var resolvedFonts: [String]
}

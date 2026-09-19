import Foundation

/// Horizontal alignment of rich text.
public enum VTGTextAlignment: String {
    case left
    case center
    case right
    case justify
}

/// Vertical placement inside a text box.
public enum VTGTextVerticalAlignment: String {
    case top
    case middle
    case bottom
}

/// What `y` means for styled and attributed text. `top` matches ``VectorTerminalCanvas/text(id:x:y:value:color:size:layer:)``.
public enum VTGTextBaseline: String {
    case top
    case alphabetic
    case middle
    case bottom
}

/// How text breaks at the available width.
public enum VTGTextWrap: String {
    case word
    case char
    case none
}

/// What a text box does with text that does not fit its height.
public enum VTGTextOverflow: String {
    case clip
    case grow
    case ellipsis
}

/// Underline appearance.
public enum VTGTextUnderline: String {
    case none
    case single
    case double
    case curly
    case dotted
    case dashed
}

/// A set of text attributes. Unset fields cascade from the style below.
///
/// With an `id`, it is a named style defined once with
/// ``VectorTerminalCanvas/defineTextStyle(_:)`` and referenced by runs;
/// without one it can still be passed inline.
public struct VTGTextStyle: Equatable {
    public var id: String?
    /// Parent style to cascade from.
    public var inherit: String?
    /// A family name, or `sans`, `serif`, `mono`, `terminal`.
    public var font: String?
    public var size: Double?
    /// 100 through 900.
    public var weight: Int?
    public var italic: Bool?
    public var color: VTGColor?
    public var background: VTGColor?
    public var tracking: Double?
    public var lineHeight: Double?
    public var underline: VTGTextUnderline?
    public var underlineColor: VTGColor?
    public var strike: Bool?

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
    public struct Run: Equatable {
        /// A style id, `-` for the command's base style, or `NL` for a break.
        public var style: String
        public var text: String
    }

    public private(set) var runs: [Run] = []

    public init() {}

    public init(_ text: String, style: String? = nil) {
        self = VTGAttributedText().append(text, style: style)
    }

    /// Add text in a named style, or the base style when `style` is `nil`.
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
    public var width: Double
    public var height: Double
    public var lineCount: Int
    /// Baselines from the top of the measured frame.
    public var firstBaseline: Double
    public var lastBaseline: Double
    /// Whether a box dropped or shortened lines.
    public var truncated: Bool
    /// The families the host actually used.
    public var resolvedFonts: [String]
}

/// Rich text: any font and size, attributed runs, and wrapped text boxes.
///
/// Retained primitives like every other VTG drawing call — they carry an id,
/// live in a layer, and work in the base scene and in pages alike. Check
/// ``VTGCapabilities/supportsRichText`` first.
extension VectorTerminalCanvas {
    /// Define or replace a named style. Styles last for the session and are
    /// unaffected by `clear()`.
    public func defineTextStyle(_ style: VTGTextStyle) {
        guard let id = style.id, isValidVTGIdentifier(id) else {
            return
        }
        var command = "textStyle,id=\(id)"
        if let inherit = style.inherit, isValidVTGIdentifier(inherit) {
            command += ",inherit=\(inherit)"
        }
        command += textStyleParameters(style)
        send(command)
    }

    /// Draw one run of text in any font and size.
    public func styledText(
        id: String,
        x: Int,
        y: Int,
        value: String,
        style: VTGTextStyle = VTGTextStyle(),
        align: VTGTextAlignment? = nil,
        baseline: VTGTextBaseline? = nil,
        angle: Double? = nil,
        maxWidth: Int? = nil,
        layer: Int? = nil
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        var command = "styledText,id=\(id),x=\(x),y=\(y)\(styleReference(style))\(textStyleParameters(style))"
        command += textLayoutParameters(align: align, baseline: baseline, angle: angle)
        if let maxWidth, maxWidth > 0 { command += ",maxWidth=\(maxWidth)" }
        command += layerParameter(layer)
        let plain = sanitizedPayload(value).filter { $0 != "\n" && $0 != "\r" }
        send(command, payload: plain)
    }

    /// Draw attributed text. Lines break only where the text has newlines,
    /// unless `maxWidth` is given.
    public func attributedText(
        id: String,
        x: Int,
        y: Int,
        text: VTGAttributedText,
        style: VTGTextStyle = VTGTextStyle(),
        align: VTGTextAlignment? = nil,
        baseline: VTGTextBaseline? = nil,
        angle: Double? = nil,
        maxWidth: Int? = nil,
        lineHeight: Double? = nil,
        layer: Int? = nil
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        var command = "attrText,id=\(id),x=\(x),y=\(y)\(styleReference(style))\(textStyleParameters(style, includeLineHeight: false))"
        command += textLayoutParameters(align: align, baseline: baseline, angle: angle)
        if let maxWidth, maxWidth > 0 { command += ",maxWidth=\(maxWidth)" }
        if let lineHeight, lineHeight > 0 { command += ",lineHeight=\(vtgNumber(lineHeight))" }
        command += layerParameter(layer)
        send(command, payload: text.encoded)
    }

    /// Draw attributed text wrapped inside a rectangle.
    ///
    /// - Parameter height: The box height, or `nil` to grow to fit — which,
    ///   in a page with a growable height, grows the page too.
    public func textBox(
        id: String,
        x: Int,
        y: Int,
        width: Int,
        height: Int? = nil,
        text: VTGAttributedText,
        style: VTGTextStyle = VTGTextStyle(),
        align: VTGTextAlignment? = nil,
        verticalAlign: VTGTextVerticalAlignment? = nil,
        wrap: VTGTextWrap? = nil,
        overflow: VTGTextOverflow? = nil,
        inset: Int? = nil,
        lineHeight: Double? = nil,
        layer: Int? = nil
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        var command = "textBox,id=\(id),x=\(x),y=\(y),w=\(max(1, width)),h=\(height.map { String(max(0, $0)) } ?? "-1")"
        command += styleReference(style) + textStyleParameters(style, includeLineHeight: false)
        command += textLayoutParameters(align: align, baseline: nil, angle: nil)
        if let verticalAlign { command += ",valign=\(verticalAlign.rawValue)" }
        if let wrap { command += ",wrap=\(wrap.rawValue)" }
        if let overflow { command += ",overflow=\(overflow.rawValue)" }
        if let inset, inset > 0 { command += ",inset=\(inset)" }
        if let lineHeight, lineHeight > 0 { command += ",lineHeight=\(vtgNumber(lineHeight))" }
        command += layerParameter(layer)
        send(command, payload: text.encoded)
    }

    /// Measure text exactly as the host would lay it out. Pass `width` to
    /// measure it wrapped in a box of that width.
    public func measureText(
        _ text: VTGAttributedText,
        style: VTGTextStyle = VTGTextStyle(),
        width: Int? = nil,
        height: Int? = nil,
        wrap: VTGTextWrap? = nil,
        overflow: VTGTextOverflow? = nil,
        lineHeight: Double? = nil,
        timeoutMilliseconds: Int = 750
    ) -> VTGTextMeasurement? {
        var command = "textMeasure?,id=measure\(styleReference(style))\(textStyleParameters(style, includeLineHeight: false))"
        if let width, width > 0 {
            command += ",kind=textBox,w=\(width),h=\(height.map { String(max(0, $0)) } ?? "-1")"
        } else {
            command += ",kind=attrText"
        }
        if let wrap { command += ",wrap=\(wrap.rawValue)" }
        if let overflow { command += ",overflow=\(overflow.rawValue)" }
        if let lineHeight, lineHeight > 0 { command += ",lineHeight=\(vtgNumber(lineHeight))" }
        guard let response = queryNamed(command, payload: text.encoded, responseName: "textMeasure", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        let values = vtgFields(from: response)
        guard let measuredWidth = values["w"].flatMap(Double.init),
              let measuredHeight = values["h"].flatMap(Double.init) else {
            return nil
        }
        return VTGTextMeasurement(
            width: measuredWidth,
            height: measuredHeight,
            lineCount: values["lines"].flatMap(Int.init) ?? 0,
            firstBaseline: values["firstBaseline"].flatMap(Double.init) ?? 0,
            lastBaseline: values["lastBaseline"].flatMap(Double.init) ?? 0,
            truncated: values["truncated"] == "1",
            resolvedFonts: values["fontResolved"].map { $0.split(separator: "|").map(String.init) } ?? []
        )
    }

    /// Font families the host can draw with, and what `sans` resolves to.
    public func queryFonts(timeoutMilliseconds: Int = 750) -> (defaultFamily: String, families: [String])? {
        guard let response = queryNamed("fonts?", responseName: "fonts", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        let values = vtgFields(from: response)
        return (
            values["default"] ?? "sans",
            values["families"].map { $0.split(separator: "|").map(String.init) } ?? []
        )
    }

    // MARK: - Encoding

    private func styleReference(_ style: VTGTextStyle) -> String {
        guard let id = style.id, isValidVTGIdentifier(id) else {
            return ""
        }
        return ",style=\(id)"
    }

    /// Inline attributes. Sent alongside a `style=` reference, they override
    /// the named style's values for this command only.
    private func textStyleParameters(_ style: VTGTextStyle, includeLineHeight: Bool = true) -> String {
        var parameters = ""
        if let font = style.font, !font.isEmpty {
            let safe = font.filter { $0 != "," && $0 != ";" && $0 != "=" && !$0.isNewline }
            parameters += ",font=\(sanitizedPayload(safe))"
        }
        if let size = style.size, size > 0 { parameters += ",size=\(vtgNumber(size))" }
        if let weight = style.weight { parameters += ",weight=\(min(900, max(100, weight)))" }
        if let italic = style.italic { parameters += ",slant=\(italic ? "italic" : "normal")" }
        parameters += colorParameter("color", style.color)
        parameters += colorParameter("bg", style.background)
        if let tracking = style.tracking { parameters += ",tracking=\(vtgNumber(tracking))" }
        if includeLineHeight, let lineHeight = style.lineHeight, lineHeight > 0 {
            parameters += ",lineHeight=\(vtgNumber(lineHeight))"
        }
        if let underline = style.underline { parameters += ",underline=\(underline.rawValue)" }
        parameters += colorParameter("underlineColor", style.underlineColor)
        if let strike = style.strike { parameters += ",strike=\(strike ? 1 : 0)" }
        return parameters
    }

    private func textLayoutParameters(align: VTGTextAlignment?, baseline: VTGTextBaseline?, angle: Double?) -> String {
        var parameters = ""
        if let align { parameters += ",align=\(align.rawValue)" }
        if let baseline { parameters += ",baseline=\(baseline.rawValue)" }
        if let angle, angle != 0 { parameters += ",angle=\(vtgNumber(angle))" }
        return parameters
    }
}

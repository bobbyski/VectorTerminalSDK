import Foundation

/// Rich text: any font and size, attributed runs, and wrapped text boxes.
///
/// Retained primitives like every other VTG drawing call — they carry an id,
/// live in a layer, and work in the base scene and in pages alike. Check
/// ``VTGCapabilities/supportsRichText`` first.
extension VectorTerminalCanvas {
    /// Define or replace a named style. Styles last for the session and are
    /// unaffected by `clear()`.
    ///
    /// Sends `textStyle,id=...`. Nothing is sent when the style has no `id`
    /// or the id is not a valid VTG identifier; an invalid `inherit` is
    /// left out.
    ///
    /// - Parameter style: The style to define; its `id` names it.
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
    ///
    /// Sends `styledText,id=...`. Newlines are removed from `value`. Nothing
    /// is sent when `id` is not a valid VTG identifier.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - x: Anchor x, in pixels.
    ///   - y: Anchor y, in pixels; `baseline` says which part of the text it is.
    ///   - value: The text, on one line.
    ///   - style: A named style (by `id`) and inline attributes that override it.
    ///   - align: Horizontal alignment around `x`, or `nil` for the host default (`left`).
    ///   - baseline: What `y` means, or `nil` for the host default (`top`).
    ///   - angle: Rotation, in degrees; `nil` or zero sends nothing.
    ///   - maxWidth: Width to wrap at, in pixels; `nil` or zero or less sends nothing.
    ///   - layer: The target layer, or `nil` for the default layer.
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
    ///
    /// Sends `attrText,id=...` with the runs as payload. The style's own
    /// `lineHeight` is not sent; use the `lineHeight` parameter. Nothing is
    /// sent when `id` is not a valid VTG identifier.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - x: Anchor x, in pixels.
    ///   - y: Anchor y, in pixels; `baseline` says which part of the text it is.
    ///   - text: The attributed runs.
    ///   - style: The base style for `-` runs: a named style (by `id`) and
    ///     inline attributes that override it.
    ///   - align: Horizontal alignment around `x`, or `nil` for the host default (`left`).
    ///   - baseline: What `y` means, or `nil` for the host default (`top`).
    ///   - angle: Rotation, in degrees; `nil` or zero sends nothing.
    ///   - maxWidth: Width to wrap at, in pixels; `nil` or zero or less sends nothing.
    ///   - lineHeight: Distance between baselines, in pixels; `nil` or zero or less sends nothing.
    ///   - layer: The target layer, or `nil` for the default layer.
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
    /// Sends `textBox,id=...` with the runs as payload. The style's own
    /// `lineHeight` is not sent; use the `lineHeight` parameter. Nothing is
    /// sent when `id` is not a valid VTG identifier.
    ///
    /// - Parameters:
    ///   - id: The retained primitive id; drawing again with the same id replaces it.
    ///   - x: Left edge of the box, in pixels.
    ///   - y: Top edge of the box, in pixels.
    ///   - width: Box width, in pixels; at least 1.
    ///   - height: The box height, or `nil` to grow to fit — which,
    ///     in a page with a growable height, grows the page too.
    ///     Negative values become zero.
    ///   - text: The attributed runs.
    ///   - style: The base style for `-` runs: a named style (by `id`) and
    ///     inline attributes that override it.
    ///   - align: Horizontal alignment inside the box, or `nil` for `left`.
    ///   - verticalAlign: Vertical placement inside the box, or `nil` for `top`.
    ///   - wrap: How lines break, or `nil` for the host default.
    ///   - overflow: What happens to text past the height, or `nil` for `clip`.
    ///   - inset: Padding on every side, in pixels; `nil` or zero or less sends nothing.
    ///   - lineHeight: Distance between baselines, in pixels; `nil` or zero or less sends nothing.
    ///   - layer: The target layer, or `nil` for the default layer.
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
    ///
    /// Sends `textMeasure?` and waits for the `textMeasure` response.
    ///
    /// - Parameters:
    ///   - text: The attributed runs to measure.
    ///   - style: The base style for `-` runs.
    ///   - width: Box width, in pixels; `nil` or zero or less measures
    ///     unwrapped attributed text instead of a box.
    ///   - height: Box height, in pixels, or `nil` to grow to fit. Used only
    ///     with `width`.
    ///   - wrap: How lines break, or `nil` for the host default.
    ///   - overflow: What happens to text past the height, or `nil` for `clip`.
    ///   - lineHeight: Distance between baselines, in pixels; `nil` or zero or less sends nothing.
    ///   - timeoutMilliseconds: How long to wait for the response.
    /// - Returns: The measurement, or `nil` when graphics are disabled, the
    ///   host does not answer in time, or the response lacks a width or height.
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
    ///
    /// Sends `fonts?` and waits for the `fonts` response.
    ///
    /// - Parameter timeoutMilliseconds: How long to wait for the response.
    /// - Returns: The default family (`sans` when unreported) and the family
    ///   list (empty when unreported), or `nil` when graphics are disabled or
    ///   the host does not answer in time.
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

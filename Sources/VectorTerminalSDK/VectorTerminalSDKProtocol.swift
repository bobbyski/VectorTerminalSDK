import Foundation

/// SDK surface for apps that want to depend on VectorTerminal
/// graphics without depending directly on `VectorTerminalCanvas`.
///
/// The protocol intentionally describes the instance API used after a canvas
/// has been created. Concrete factory helpers such as
/// `VectorTerminalCanvas.hostValidated(...)` remain on `VectorTerminalCanvas`
/// because static factory requirements are awkward to use through existentials.
///
public protocol VectorTerminalSDKProtocol: AnyObject {
    /// Optional hook used by demos and host apps to surface parser details.
    var eventDebugHandler: ((String) -> Void)? { get set }

    /// Default graphics layer used by VTG commands that omit `layer:`.
    var defaultLayer: Int { get set }

    // MARK: - Scene

    /// Clear all retained VTG primitives.
    func clear()

    /// Request presentation of the current VTG scene.
    ///
    /// `present()` is optional for normal retained drawing: VectorTerminal
    /// renders mutations as they arrive today. Call it when an app wants an
    /// explicit flush point, clearer intent, or future renderer compatibility.
    func present()

    /// Delete one retained VTG primitive by id.
    func delete(id: String)

    // MARK: - Primitive Drawing

    func pixel(id: String, x: Int, y: Int, color: VTGColor, layer: Int?)
    func line(id: String, x1: Int, y1: Int, x2: Int, y2: Int, stroke: VTGColor, width: Int, lineCap: VTGLineCap?, layer: Int?)
    func clearRect(id: String, x: Int, y: Int, width: Int, height: Int, layer: Int?)
    func draw(id: String, points: [VTGPoint], stroke: VTGColor, width: Int, lineCap: VTGLineCap?, lineJoin: VTGLineJoin?, layer: Int?)
    func quadraticCurve(id: String, x1: Int, y1: Int, cx: Int, cy: Int, x2: Int, y2: Int, stroke: VTGColor, width: Int, lineCap: VTGLineCap?, lineJoin: VTGLineJoin?, layer: Int?)
    func cubicCurve(id: String, x1: Int, y1: Int, c1x: Int, c1y: Int, c2x: Int, c2y: Int, x2: Int, y2: Int, stroke: VTGColor, width: Int, lineCap: VTGLineCap?, lineJoin: VTGLineJoin?, layer: Int?)
    func path(id: String, payload: String, stroke: VTGColor?, fill: VTGColor?, lineWidth: Int, lineCap: VTGLineCap?, lineJoin: VTGLineJoin?, layer: Int?)
    func triangle(id: String, p1: VTGPoint, p2: VTGPoint, p3: VTGPoint, stroke: VTGColor?, fill: VTGColor?, lineWidth: Int, radius: Int, lineJoin: VTGLineJoin?, layer: Int?)
    func rect(id: String, x: Int, y: Int, width: Int, height: Int, stroke: VTGColor?, fill: VTGColor?, lineWidth: Int, radius: Int, corners: String?, lineJoin: VTGLineJoin?, layer: Int?)
    func circle(id: String, cx: Int, cy: Int, radius: Int, stroke: VTGColor?, fill: VTGColor?, lineWidth: Int, layer: Int?)
    func ellipse(id: String, cx: Int, cy: Int, rx: Int, ry: Int, stroke: VTGColor?, fill: VTGColor?, lineWidth: Int, layer: Int?)
    func text(id: String, x: Int, y: Int, value: String, color: VTGColor, size: Int, layer: Int?)

    // MARK: - Raster And Sprites

    func image(id: String, x: Int, y: Int, width: Int, height: Int, pngData: Data, filter: VTGSpriteFilter, layer: Int?)
    func image(id: String, x: Int, y: Int, width: Int, height: Int, jpegData: Data, filter: VTGSpriteFilter, layer: Int?)
    func uploadSprite(id: String, width: Int, height: Int, pngData: Data, filter: VTGSpriteFilter)
    func uploadSprite(id: String, width: Int, height: Int, jpegData: Data, filter: VTGSpriteFilter)
    func uploadSprite(id: String, width: Int, height: Int, pixels: [Int], palette: [VTGColor], transparentIndex: Int?, filter: VTGSpriteFilter)
    func uploadIndexedSprite(id: String, width: Int, height: Int, pixels: [Int], palette: [VTGColor], transparentIndex: Int?, filter: VTGSpriteFilter)
    func uploadVectorSprite(id: String, width: Int, height: Int, path: String, stroke: VTGColor?, fill: VTGColor?, lineWidth: Double)
    func sprite(id: String, imageID: String, x: Int, y: Int, rotation: Double, scale: Double, anchorX: Double, anchorY: Double, layer: Int?)
    func moveSprite(id: String, x: Int, y: Int)
    func rotateSprite(id: String, rotation: Double)
    func transformSprite(id: String, x: Int, y: Int, rotation: Double, scale: Double, anchorX: Double?, anchorY: Double?)
    func anchorSprite(id: String, anchorX: Double, anchorY: Double)
    func removeSprite(id: String)
    func clearSprites()

    // MARK: - Layers, Viewports, And Hit Regions

    func setDefaultLayer(_ layer: Int)
    func setLayer(id: String, layer: Int)
    func scrollLayer(_ layer: Int, x: Int, y: Int)
    func setLayerAlpha(_ layer: Int, alpha: Double)
    func clipLayer(_ layer: Int, x: Int, y: Int, width: Int, height: Int)
    func clearLayerClip(_ layer: Int)
    func setGraphicsLayersVisible(_ isVisible: Bool)
    func setViewportMode(layer: Int, width: Int, height: Int, scale: VTGViewportScaleMode)
    func clearViewportMode(layer: Int)
    func setViewportScale(layer: Int, scale: Double, x: Int, y: Int)
    func hitRegion(id: String, x: Int, y: Int, width: Int, height: Int, layer: Int?, target: String?)
    func clearHitRegions(id: String?, layer: Int?)

    // MARK: - Frames

    func startFrame(id: String, timeoutMilliseconds: Int)
    func endFrame(id: String)
    func cancelFrame(id: String)
    func withFrame<T>(id: String, timeoutMilliseconds: Int, _ body: () throws -> T) rethrows -> T

    // MARK: - Text And ANSI Helpers

    func vectorTextSize(height: Int, value: String) -> VTGTextSize
    func vectorPrint(id: String, x: Int, y: Int, height: Int, value: String, stroke: VTGColor, width: Int, layer: Int?)
    func bell()
    func writeText(_ value: String)
    func clearScreen()
    func clearScrollbackAndScreen()
    func clearLine()
    func clearToEndOfLine()
    func moveCursor(row: Int, column: Int)
    func setCursor(row: Int, column: Int)
    func moveCursorUp(_ count: Int)
    func moveCursorDown(_ count: Int)
    func moveCursorForward(_ count: Int)
    func moveCursorBackward(_ count: Int)
    func saveCursor()
    func restoreCursor()
    func hideCursor()
    func showCursor()
    func resetTextAttributes()
    func bold(_ enabled: Bool)
    func underline(_ enabled: Bool)
    func inverse(_ enabled: Bool)
    func setForeground(_ color: ANSIColor, bright: Bool)
    func setBackground(_ color: ANSIColor, bright: Bool)
    func setForegroundRGB(red: Int, green: Int, blue: Int)
    func setBackgroundRGB(red: Int, green: Int, blue: Int)
    func withRawInput<T>(_ body: () throws -> T) rethrows -> T
    func withRawInput<T>(_ body: () async throws -> T) async rethrows -> T
    func enterAlternateScreen()
    func leaveAlternateScreen()
    func enableBracketedPaste()
    func disableBracketedPaste()
    func enableFocusReporting()
    func disableFocusReporting()

    // MARK: - Input, Events, And Queries

    func enableMouseReporting()
    func enableMouseReporting(mode: String)
    func disableMouseReporting()
    func enableResizeEvents()
    func disableResizeEvents()
    func queryCapabilities(timeoutMilliseconds: Int) -> String?
    func queryCapabilityInfo(timeoutMilliseconds: Int) -> VTGCapabilities?
    func queryCanvas(timeoutMilliseconds: Int) -> VTGCanvas?
    func querySize(timeoutMilliseconds: Int) -> VTGCanvas?
    func queryCurrentCanvas(timeoutMilliseconds: Int) -> VTGCanvas?
    func areGraphicsLayersVisible(timeoutMilliseconds: Int) -> Bool?
    func queryTerminalCellSize() -> TerminalCellSize?
    func readEvent(timeoutMilliseconds: Int) -> VectorTerminalEvent?
    func events(canvasPollInterval: TimeInterval) -> AsyncStream<VectorTerminalEvent>
}

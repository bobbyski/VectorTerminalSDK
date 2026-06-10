# VectorTerminalSDK API Reference

Version: `1.1.0`

VectorTerminalSDK is a Swift wrapper around VectorTerminal Graphics (VTG) plus the ANSI helpers needed to run graphical terminal apps safely. The SDK is deliberately low-level: drawing methods map closely to VTG escape sequences, while session, event, and output helpers remove the repetitive terminal plumbing.

All VTG drawing APIs use pixel coordinates with the origin at the top-left of the VTG canvas. ANSI cursor APIs use traditional one-based terminal row/column coordinates.

## Initialization

### `VectorTerminalCanvas`

```swift
public final class VectorTerminalCanvas
```

The canvas is the main SDK object. It owns the input/output handles, performs optional VTG detection, and emits VTG or ANSI bytes.

```swift
public init(
    input: FileHandle = .standardInput,
    output: VTGOutput = FileHandle.standardOutput,
    timeoutMilliseconds: Int = 750
) throws
```

Creates a graphics-enabled canvas by querying `capabilities?`. Throws `VectorTerminalSDKError.vectorTerminalNotDetected` if the terminal does not answer as VectorTerminal.

```swift
public static func noOp(
    input: FileHandle = .standardInput,
    output: VTGOutput = FileHandle.standardOutput
) -> VectorTerminalCanvas
```

Creates a canvas where VTG drawing commands silently do nothing. ANSI helpers still write to `output`.

```swift
public static func hostValidated(
    input: FileHandle = .standardInput,
    output: VTGOutput
) -> VectorTerminalCanvas
```

Creates an enabled canvas for apps that already own a VTG-capable view, such as a SwiftUI/AppKit host feeding bytes directly into `VectorTerminalView.feedVTG(_:)`.

```swift
public var defaultLayer: Int
public var eventDebugHandler: ((String) -> Void)?
```

`defaultLayer` changes the terminal-side retained drawing default. `eventDebugHandler` receives parser diagnostics from event readers.

### `VTGOutput`

```swift
public protocol VTGOutput: AnyObject {
    func write(_ data: Data)
}
```

Output abstraction used by the SDK. `FileHandle` conforms directly.

```swift
public final class ClosureVTGOutput: VTGOutput {
    public init(_ writer: @escaping (Data) -> Void)
    public func write(_ data: Data)
}
```

Use `ClosureVTGOutput` for host-fed apps where VTG bytes should be delivered to an in-process terminal view rather than stdout.

## Session Lifecycle

```swift
public struct VectorTerminalSessionOptions: Equatable
```

Options for scoped setup and teardown:

| Property | Default | Meaning |
|---|---:|---|
| `useAlternateScreen` | `true` | Enter alternate screen on start, leave it on end. |
| `hideCursor` | `true` | Hide the terminal cursor while active. |
| `clearOnStart` | `true` | Clear ANSI text and retained VTG graphics on start. |
| `clearOnEnd` | `false` | Clear ANSI text and retained VTG graphics on end. |
| `resetTextAttributesOnEnd` | `true` | Emit ANSI SGR reset during teardown. |
| `resizeEvents` | `true` | Subscribe to VTG resize events. |
| `mouseMode` | `nil` | Optional VTG mouse mode, such as `"raw"`. |
| `rawInput` | `false` | Put stdin in raw mode for byte-oriented input. |

```swift
public final class VectorTerminalSession {
    public let canvas: VectorTerminalCanvas
    public let options: VectorTerminalSessionOptions

    public init(canvas: VectorTerminalCanvas, options: VectorTerminalSessionOptions = .init())
    public func start()
    public func end()
}
```

`start()` applies the configured terminal state. `end()` restores state and is idempotent. The session also calls `end()` from `deinit`.

```swift
public static func run<T>(
    canvas: VectorTerminalCanvas,
    options: VectorTerminalSessionOptions = .init(),
    _ body: (VectorTerminalSession) throws -> T
) rethrows -> T

public static func run<T>(
    canvas: VectorTerminalCanvas,
    options: VectorTerminalSessionOptions = .init(),
    _ body: (VectorTerminalSession) async throws -> T
) async rethrows -> T
```

Convenience wrappers that start a session, run work, and always restore terminal state.

## Scene Commands

These commands affect retained VTG scene state.

```swift
public func clear()
public func present()
public func delete(id: String)
```

`clear()` removes all retained VTG primitives. `present()` is a presentation hint. `delete(id:)` removes a single retained primitive by id.

## Drawing Primitives

All drawing calls create or replace retained primitives. Reusing the same `id` updates the existing primitive.

```swift
public func pixel(id: String, x: Int, y: Int, color: VTGColor = .white, layer: Int? = nil)
```

Draws a single retained pixel.

```swift
public func line(
    id: String,
    x1: Int,
    y1: Int,
    x2: Int,
    y2: Int,
    stroke: VTGColor = .white,
    width: Int = 1,
    lineCap: VTGLineCap? = nil,
    layer: Int? = nil
)
```

Draws a retained line segment.

```swift
public func draw(
    id: String,
    points: [VTGPoint],
    stroke: VTGColor = .white,
    width: Int = 1,
    lineCap: VTGLineCap? = nil,
    lineJoin: VTGLineJoin? = nil,
    layer: Int? = nil
)
```

Draws a connected polyline from at least two points.

```swift
public func quadraticCurve(
    id: String,
    x1: Int,
    y1: Int,
    cx: Int,
    cy: Int,
    x2: Int,
    y2: Int,
    stroke: VTGColor = .white,
    width: Int = 1,
    lineCap: VTGLineCap? = nil,
    lineJoin: VTGLineJoin? = nil,
    layer: Int? = nil
)

public func cubicCurve(
    id: String,
    x1: Int,
    y1: Int,
    c1x: Int,
    c1y: Int,
    c2x: Int,
    c2y: Int,
    x2: Int,
    y2: Int,
    stroke: VTGColor = .white,
    width: Int = 1,
    lineCap: VTGLineCap? = nil,
    lineJoin: VTGLineJoin? = nil,
    layer: Int? = nil
)
```

Draws retained quadratic and cubic Bezier curves.

```swift
public func path(
    id: String,
    payload: String,
    stroke: VTGColor? = .white,
    fill: VTGColor? = nil,
    lineWidth: Int = 1,
    lineCap: VTGLineCap? = nil,
    lineJoin: VTGLineJoin? = nil,
    layer: Int? = nil
)
```

Draws a constrained absolute SVG-like path. Current path commands are `M`, `L`, `Q`, `C`, and `Z`.

```swift
public func text(
    id: String,
    x: Int,
    y: Int,
    value: String,
    color: VTGColor = .white,
    size: Int = 14,
    layer: Int? = nil
)
```

Draws host-rendered graphics text in pixel coordinates.

```swift
public func vectorPrint(
    id: String,
    x: Int,
    y: Int,
    height: Int,
    value: String,
    stroke: VTGColor = .white,
    width: Int = 1,
    layer: Int? = nil
)
```

Draws ASCII-subset vector text using VTG polyline commands. Unsupported control characters render as a square with their numeric code.

## Enclosed Shapes

```swift
public func triangle(
    id: String,
    p1: VTGPoint,
    p2: VTGPoint,
    p3: VTGPoint,
    stroke: VTGColor? = .white,
    fill: VTGColor? = nil,
    lineWidth: Int = 1,
    radius: Int = 0,
    lineJoin: VTGLineJoin? = nil,
    layer: Int? = nil
)
```

Draws a sharp or rounded triangle. `radius` is clamped by the terminal renderer.

```swift
public func rect(
    id: String,
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    stroke: VTGColor? = .white,
    fill: VTGColor? = nil,
    lineWidth: Int = 1,
    radius: Int = 0,
    corners: String? = nil,
    lineJoin: VTGLineJoin? = nil,
    layer: Int? = nil
)
```

Draws a sharp or rounded rectangle. `corners` limits rounding by digit: `1` top-left, `2` top-right, `3` bottom-right, `4` bottom-left. For example, `"12"` rounds only the top corners for TUI window headers.

```swift
public func circle(
    id: String,
    cx: Int,
    cy: Int,
    radius: Int,
    stroke: VTGColor? = .white,
    fill: VTGColor? = nil,
    lineWidth: Int = 1,
    layer: Int? = nil
)

public func ellipse(
    id: String,
    cx: Int,
    cy: Int,
    rx: Int,
    ry: Int,
    stroke: VTGColor? = .white,
    fill: VTGColor? = nil,
    lineWidth: Int = 1,
    layer: Int? = nil
)
```

Draws retained circles and ellipses.

## Raster Images

```swift
public func image(
    id: String,
    x: Int = 0,
    y: Int = 0,
    width: Int,
    height: Int,
    pngData: Data,
    filter: VTGSpriteFilter = .smooth,
    layer: Int? = nil
)

public func image(
    id: String,
    x: Int = 0,
    y: Int = 0,
    width: Int,
    height: Int,
    jpegData: Data,
    filter: VTGSpriteFilter = .smooth,
    layer: Int? = nil
)
```

Uploads and places a retained PNG or JPEG image. Use sprites when the same asset needs repeated move, rotate, or scale operations.

## Sprites

Sprite assets are uploaded once and placed as retained sprite instances. Transforms apply to sprite instances only.

```swift
public func uploadSprite(id: String, width: Int, height: Int, pngData: Data, filter: VTGSpriteFilter = .smooth)
public func uploadSprite(id: String, width: Int, height: Int, jpegData: Data, filter: VTGSpriteFilter = .smooth)
```

Uploads PNG or JPEG sprite assets.

```swift
public func uploadVectorSprite(
    id: String,
    width: Int,
    height: Int,
    path: String,
    stroke: VTGColor? = nil,
    fill: VTGColor? = nil,
    lineWidth: Double = 1
)
```

Uploads a vector sprite backed by one constrained VTG path payload.

```swift
public func uploadSprite(
    id: String,
    width: Int,
    height: Int,
    pixels: [Int],
    palette: [VTGColor],
    transparentIndex: Int? = nil,
    filter: VTGSpriteFilter = .nearest
)

public func uploadIndexedSprite(
    id: String,
    width: Int,
    height: Int,
    pixels: [Int],
    palette: [VTGColor],
    transparentIndex: Int? = nil,
    filter: VTGSpriteFilter = .nearest
)
```

Uploads a palette-indexed sprite from numeric arrays for retro BASIC-style callers.

```swift
public func sprite(
    id: String,
    imageID: String,
    x: Int,
    y: Int,
    rotation: Double = 0,
    scale: Double = 1,
    anchorX: Double = 0.5,
    anchorY: Double = 0.5,
    layer: Int? = nil
)
```

Places or replaces a retained sprite instance.

```swift
public func moveSprite(id: String, x: Int, y: Int)
public func rotateSprite(id: String, rotation: Double)
public func anchorSprite(id: String, anchorX: Double, anchorY: Double)

public func transformSprite(
    id: String,
    x: Int,
    y: Int,
    rotation: Double,
    scale: Double,
    anchorX: Double? = nil,
    anchorY: Double? = nil
)
```

Updates sprite instance position, rotation, anchor, or a full transform.

```swift
public func removeSprite(id: String)
public func clearSprites()
```

Removes one uploaded sprite asset and dependent instances, or removes all sprite assets and instances.

## Layers

VTG currently supports layers `-1...4`.

| Layer | Meaning |
|---:|---|
| `-1` | Under-text native graphics plane. |
| `0` | Reserved future shared text/graphics plane. |
| `1` | Default overlay layer. |
| `2...4` | Additional overlay layers. |

```swift
public enum VTGLayer {
    public static let underText = -1
    public static let textPlane = 0
    public static let defaultOverlay = 1
    public static let overlay1 = 1
    public static let overlay2 = 2
    public static let overlay3 = 3
    public static let overlay4 = 4

    public static func clamped(_ layer: Int) -> Int
    public static func isSupported(_ layer: Int) -> Bool
    public static func isScrollable(_ layer: Int) -> Bool
}
```

```swift
public func setDefaultLayer(_ layer: Int)
public func setLayer(id: String, layer: Int)
public func scrollLayer(_ layer: Int, x: Int, y: Int)
public func setLayerAlpha(_ layer: Int, alpha: Double)
public func clipLayer(_ layer: Int, x: Int, y: Int, width: Int, height: Int)
public func clearLayerClip(_ layer: Int)
```

Layer scrolling and alpha are limited to overlay layers `1...4`. Clipping accepts supported layers.

## Fixed-Resolution Viewports

Fixed-resolution viewports let overlay layers draw in virtual coordinates and scale to the live terminal canvas.

```swift
public enum VTGViewportScaleMode: String {
    case fit
    case fill
    case integer
    case stretch
}

public func setViewportMode(
    layer: Int,
    width: Int,
    height: Int,
    scale: VTGViewportScaleMode = .fit
)

public func clearViewportMode(layer: Int)
public func setViewportScale(layer: Int, scale: Double, x: Int, y: Int)
```

Viewport support is intentionally overlay-only. Layer `0` is excluded because native terminal text remains in live cell coordinates.

## Hit Regions

```swift
public func hitRegion(
    id: String,
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    layer: Int? = nil,
    target: String? = nil
)

public func clearHitRegions(id: String? = nil, layer: Int? = nil)
```

Registers rectangular regions that annotate mouse events with `hitID` and optional `targetID`. Regions are evaluated by layer from top to bottom, then by registration order within a layer.

## Offscreen Graphics Frames

```swift
public func startFrame(id: String, timeoutMilliseconds: Int = 250)
public func endFrame(id: String)
public func cancelFrame(id: String)

public func withFrame<T>(
    id: String,
    timeoutMilliseconds: Int = 250,
    _ body: () throws -> T
) rethrows -> T
```

Frames buffer VTG scene mutations offscreen until commit. ANSI text still writes immediately. `withFrame` sends `cancelFrame` if the Swift body throws, and the terminal has its own timeout watchdog for app crashes.

Frame lifecycle responses are parsed as `VectorTerminalEvent.frame(VTGFrameEvent)`.

## Queries And Capabilities

```swift
public func queryCapabilities(timeoutMilliseconds: Int = 750) -> String?
public func queryCapabilityInfo(timeoutMilliseconds: Int = 750) -> VTGCapabilities?
public func queryCanvas(timeoutMilliseconds: Int = 750) -> VTGCanvas?
public func querySize(timeoutMilliseconds: Int = 750) -> VTGCanvas?
public func queryCurrentCanvas(timeoutMilliseconds: Int = 750) -> VTGCanvas?
public func queryTerminalCellSize() -> TerminalCellSize?
```

`queryCurrentCanvas` is the recommended size query for app code. It tries `canvas?`, then `size?`, then the canvas fields embedded in `capabilities?`.

`VTGCapabilities` exposes parsed terminal capability fields:

```swift
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
    public var textPlaneStatus: VTGTextPlaneStatus
    public var layerScroll: Bool?
    public var layerAlpha: String?
    public var clip: String?
    public var hit: String?
    public var events: [String]
    public var colors: [String]
    public var rawResponse: String
}
```

## Events

```swift
public func enableResizeEvents()
public func disableResizeEvents()
public func enableMouseReporting()
public func enableMouseReporting(mode: String)
public func disableMouseReporting()
public func readEvent(timeoutMilliseconds: Int = 100) -> VectorTerminalEvent?
public func events(canvasPollInterval: TimeInterval = 0.5) -> AsyncStream<VectorTerminalEvent>
```

`events(...)` streams keyboard bytes, typed arrow keys, mouse events, resize events, frame events, and polled canvas updates. The periodic canvas poll is a compatibility fallback for older/debug builds.

```swift
public enum VectorTerminalEvent: Equatable {
    case key(UInt8)
    case specialKey(ANSISpecialKey)
    case mouse(VTGMouseEvent)
    case resize(VTGCanvas)
    case canvas(VTGCanvas)
    case frame(VTGFrameEvent)
}
```

Mouse events contain pixel coordinates, optional terminal cell coordinates, button, type, modifiers, scroll deltas, hit-region metadata, optional virtual viewport coordinates, and the raw escape sequence.

## ANSI Helpers

ANSI helpers work even on a no-op graphics canvas.

### Terminal Modes

```swift
public func withRawInput<T>(_ body: () throws -> T) rethrows -> T
public func withRawInput<T>(_ body: () async throws -> T) async rethrows -> T
public func enterAlternateScreen()
public func leaveAlternateScreen()
public func enableBracketedPaste()
public func disableBracketedPaste()
public func enableFocusReporting()
public func disableFocusReporting()
```

### Screen And Cursor

```swift
public func clearScreen()
public func clearScrollbackAndScreen()
public func clearLine()
public func clearToEndOfLine()

public func moveCursor(row: Int, column: Int)
public func setCursor(row: Int, column: Int)
public func moveCursorUp(_ count: Int = 1)
public func moveCursorDown(_ count: Int = 1)
public func moveCursorForward(_ count: Int = 1)
public func moveCursorBackward(_ count: Int = 1)
public func saveCursor()
public func restoreCursor()
public func hideCursor()
public func showCursor()
```

### Text Styling

```swift
public enum ANSIColor: Int {
    case black, red, green, yellow, blue, magenta, cyan, white
}

public func resetTextAttributes()
public func bold(_ enabled: Bool = true)
public func underline(_ enabled: Bool = true)
public func inverse(_ enabled: Bool = true)
public func setForeground(_ color: ANSIColor, bright: Bool = false)
public func setBackground(_ color: ANSIColor, bright: Bool = false)
public func setForegroundRGB(red: Int, green: Int, blue: Int)
public func setBackgroundRGB(red: Int, green: Int, blue: Int)
```

### Simple Output

```swift
public func bell()
public func writeText(_ value: String)
```

## Core Value Types

```swift
public struct VTGColor: Equatable, ExpressibleByStringLiteral
public struct VTGPoint: Equatable
public struct VTGCanvas: Equatable
public struct TerminalCellSize: Equatable
public enum VTGLineCap: String
public enum VTGLineJoin: String
public enum VTGSpriteFilter: String
public enum VectorTerminalSDKError: Error, LocalizedError
```

`VTGColor` accepts CSS-style `#RRGGBB`, `#RRGGBBAA`, or `"none"` for transparency. Convenience constants include `.green`, `.blue`, `.red`, `.cyan`, `.white`, and `.transparent`.

## Host-Fed Example

Use this pattern when an app owns the terminal view and does not launch a child process.

```swift
let output = ClosureVTGOutput { [weak terminalView] data in
    terminalView?.feedVTG(data)
}

let canvas = VectorTerminalCanvas.hostValidated(output: output)
canvas.clear()
canvas.rect(
    id: "panel",
    x: 20,
    y: 20,
    width: 400,
    height: 240,
    radius: 12,
    corners: "12",
    stroke: .green,
    fill: "#07111dcc"
)
canvas.vectorPrint(
    id: "title",
    x: 48,
    y: 64,
    height: 72,
    value: "BASIC",
    stroke: .cyan,
    width: 3
)
```

## Process Example

Use this pattern for normal command-line apps that should fall back when they are not inside VectorTerminal.

```swift
do {
    let canvas = try VectorTerminalCanvas()
    try VectorTerminalSession.run(
        canvas: canvas,
        options: .init(mouseMode: "raw", rawInput: true)
    ) { session in
        let canvas = session.canvas
        canvas.clear()
        canvas.rect(id: "border", x: 5, y: 5, width: 800, height: 500, stroke: .green)

        for await event in canvas.events() {
            if case .key(let byte) = event, byte == UInt8(ascii: "q") {
                break
            }
        }
    }
} catch VectorTerminalSDKError.vectorTerminalNotDetected {
    print("VectorTerminal graphics unavailable; running text fallback.")
}
```


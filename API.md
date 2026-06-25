# VectorTerminalSDK API Reference

Version: `1.1.2`

VectorTerminalSDK is a Swift wrapper around VectorTerminal Graphics (VTG) plus the ANSI helpers needed to run graphical terminal apps safely. The SDK is deliberately low-level: drawing methods map closely to VTG escape sequences, while session, event, and output helpers remove the repetitive terminal plumbing.

All VTG drawing APIs use pixel coordinates with the origin at the top-left of the VTG canvas. ANSI cursor APIs use traditional one-based terminal row/column coordinates.

## Initialization

### `VectorTerminalCanvas`

```swift
@MainActor
public final class VectorTerminalCanvas: VectorTerminalSDKProtocol
```

The canvas is the main SDK object. It owns the input/output handles, performs optional VTG detection, and emits VTG or ANSI bytes. `VectorTerminalCanvas` is main-actor isolated so retained graphics state and terminal output are mutated from one serialized execution context.

### `VectorTerminalSDKProtocol`

```swift
@MainActor
public protocol VectorTerminalSDKProtocol: AnyObject
```

Protocol-oriented surface for apps, hosts, and tests that want to depend on the SDK behavior without depending directly on `VectorTerminalCanvas`. The protocol covers the instance API after a canvas has been created: scene commands, drawing primitives, raster images, sprites, layers, viewports, hit regions, frames, ANSI helpers, events, and queries.

Static factory helpers such as `VectorTerminalCanvas.noOp(...)` and `VectorTerminalCanvas.hostValidated(...)` remain on `VectorTerminalCanvas`, because they create concrete canvas instances. Store the result behind the protocol once construction succeeds:

```swift
let canvas: VectorTerminalSDKProtocol = VectorTerminalCanvas.hostValidated(output: output)
canvas.clear()
canvas.rect(id: "panel", x: 20, y: 20, width: 360, height: 180, stroke: .green)
```

Because the protocol is `@MainActor`, calls made from background tasks must hop to the main actor:

```swift
Task.detached {
    let value = await loadStatus()
    await MainActor.run {
        canvas.text(id: "status", x: 20, y: 20, value: value, color: .white)
    }
}
```

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

### Object IDs And Retained State

VTG drawing commands are retained by the terminal. The `id` passed to drawing, image, sprite instance, and hit-region calls is not just a client-side label; it is the key the terminal uses to keep, replace, move, or delete the visible object.

Use stable object IDs for things that conceptually persist across frames:

```swift
canvas.line(id: "crosshair-horizontal", x1: 360, y1: 240, x2: 440, y2: 240, stroke: .green)
canvas.line(id: "crosshair-vertical", x1: 400, y1: 200, x2: 400, y2: 280, stroke: .green)

// Later in the app, the same IDs update the retained objects in place.
canvas.line(id: "crosshair-horizontal", x1: 370, y1: 250, x2: 450, y2: 250, stroke: .green)
canvas.line(id: "crosshair-vertical", x1: 410, y1: 210, x2: 410, y2: 290, stroke: .green)
```

Use unique IDs for things that are separate visible objects, even when they share a shape or style:

```swift
for bullet in bullets {
    canvas.circle(
        id: "bullet-\(bullet.id)",
        cx: bullet.x,
        cy: bullet.y,
        radius: 3,
        stroke: .cyan,
        fill: .cyan
    )
}
```

Delete objects when the model item leaves the screen or no longer exists:

```swift
let visibleIDs = Set(bullets.map { "bullet-\($0.id)" })
for id in previouslyDrawnBulletIDs.subtracting(visibleIDs) {
    canvas.delete(id: id)
}
previouslyDrawnBulletIDs = visibleIDs
```

Prefer stable, semantic IDs over frame-number IDs for persistent UI. For example, `"health-bar-fill"` is usually better than `"health-bar-fill-frame-318"`, because reusing the semantic ID replaces the old object. Generating a new ID every frame without deleting the previous one leaves old retained objects in the scene.

Be careful when reusing an ID for a different kind of object. Reusing `"status"` first for text and later for a rectangle replaces the retained object named `"status"`; that is useful for deliberate replacement, but surprising if two parts of the app accidentally share the same ID. Prefix IDs by feature or owner when multiple systems draw to the same canvas:

```swift
canvas.text(id: "hud-score", x: 20, y: 20, value: "1200", color: .white)
canvas.rect(id: "menu-score", x: 180, y: 80, width: 160, height: 40, stroke: .green)
```

`clear()` is the right reset point when entering a new screen, changing modes, or recovering from a state mismatch. After a `clear()`, any IDs your app still has in memory refer to objects that are no longer on the terminal screen. Send fresh drawing commands before expecting `delete(id:)`, `setLayer(id:)`, sprite transforms, or hit-region events for those objects to have visible meaning.

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

```swift
public static func vectorTextSize(height: Int, value: String) -> VTGTextSize
public func vectorTextSize(height: Int, value: String) -> VTGTextSize
```

Measures the pixel advance consumed by `vectorPrint(...)` for a string at the requested glyph height. Use the static form when no canvas exists yet, or the instance form when laying out near existing drawing calls.

## Enclosed Shapes

```swift
public func clearRect(
    id: String,
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    layer: Int? = nil
)
```

Clears a retained rectangular overlay graphics region back to transparent pixels. This is different from drawing a background-colored rectangle: earlier overlay graphics in the same compositing plane are erased inside the rectangle, while later primitives can still draw over it. Native under-text/text-plane clearing is intentionally deferred until shared-plane compositing is complete.

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

Hit regions are retained independently from drawing primitives. If a button, menu item, or sprite leaves the screen, clear or replace its hit region at the same time you update the visible object:

```swift
canvas.rect(id: "button-start", x: 40, y: 40, width: 160, height: 48, stroke: .green)
canvas.text(id: "button-start-label", x: 76, y: 54, value: "Start", color: .white)
canvas.hitRegion(id: "button-start-hit", x: 40, y: 40, width: 160, height: 48, target: "start")

// When the button is hidden, remove both the visible objects and the retained hit region.
canvas.delete(id: "button-start")
canvas.delete(id: "button-start-label")
canvas.clearHitRegions(id: "button-start-hit")
```

Do not assume a `hitID` proves the matching visible object is still on screen. It proves the terminal still has a retained hit region with that ID. Treat hit events as input hints and validate them against your current app model before acting on them.

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
public struct VTGTextSize: Equatable
public enum VTGLineCap: String
public enum VTGLineJoin: String
public enum VTGSpriteFilter: String
public enum VectorTerminalSDKError: Error, LocalizedError
```

`VTGColor` accepts CSS-style `#RRGGBB`, `#RRGGBBAA`, or `"none"` for transparency. Convenience constants include `.green`, `.blue`, `.red`, `.cyan`, `.white`, and `.transparent`.

## Common Use Cases

### Static Panels And HUDs

Use stable IDs for long-lived interface elements and redraw with the same IDs when values change. This keeps the retained scene small and avoids flicker from clearing and rebuilding the whole canvas.

```swift
func drawHUD(canvas: VectorTerminalCanvas, score: Int, shields: Int) {
    canvas.rect(id: "hud-frame", x: 12, y: 12, width: 260, height: 72, stroke: .green, fill: "#07111dcc")
    canvas.text(id: "hud-score", x: 28, y: 28, value: "Score \(score)", color: .white)
    canvas.rect(id: "hud-shields-bg", x: 28, y: 56, width: 200, height: 12, stroke: .cyan)
    canvas.rect(id: "hud-shields-fill", x: 28, y: 56, width: shields * 2, height: 12, stroke: nil, fill: .cyan)
}
```

Call `drawHUD(...)` whenever the values change. The IDs stay the same, so each call replaces the prior HUD primitives.

### Animated Model Objects

Keep a set of IDs that were drawn on the previous tick. Draw the current model using stable IDs derived from model identity, then delete IDs that disappeared.

```swift
var drawnEnemyIDs = Set<String>()

func drawEnemies(_ enemies: [Enemy], canvas: VectorTerminalCanvas) {
    var currentIDs = Set<String>()

    for enemy in enemies where enemy.isVisible {
        let id = "enemy-\(enemy.id)"
        currentIDs.insert(id)
        canvas.triangle(
            id: id,
            p1: .init(x: enemy.x, y: enemy.y - 12),
            p2: .init(x: enemy.x - 10, y: enemy.y + 10),
            p3: .init(x: enemy.x + 10, y: enemy.y + 10),
            stroke: .red,
            fill: "#fb718544"
        )
    }

    for staleID in drawnEnemyIDs.subtracting(currentIDs) {
        canvas.delete(id: staleID)
    }

    drawnEnemyIDs = currentIDs
}
```

This pattern avoids two common mistakes: leaving old objects behind when a model object is removed, and accidentally reusing one ID for every object in a collection.

### Sprite Assets And Sprite Instances

Sprite asset IDs and sprite instance IDs have different lifetimes. Upload the asset once with an image ID, then create one or more visible instances that reference it.

```swift
canvas.uploadSprite(id: "ship-image", width: 32, height: 32, pngData: shipPNG, filter: .nearest)

canvas.sprite(id: "player-ship", imageID: "ship-image", x: 400, y: 300, scale: 2, layer: 2)
canvas.transformSprite(id: "player-ship", x: 420, y: 300, rotation: 0.2, scale: 2)
```

Use the instance ID for `moveSprite`, `rotateSprite`, `anchorSprite`, and `transformSprite`. Use `removeSprite(id:)` only when you want to remove the uploaded asset and any dependent instances. If an image is still useful but one visible instance is gone, replace or delete the instance instead of removing the asset.

### Screen Changes

When switching between screens, prefer an explicit cleanup boundary. For a full mode change, `clear()` is simpler and safer than trying to remember every object from the prior screen.

```swift
func showPauseMenu(canvas: VectorTerminalCanvas) {
    canvas.clear()
    canvas.rect(id: "pause-panel", x: 220, y: 120, width: 360, height: 180, stroke: .cyan, fill: "#07111dcc")
    canvas.vectorPrint(id: "pause-title", x: 284, y: 164, height: 48, value: "PAUSED", stroke: .white, width: 2)
    canvas.hitRegion(id: "pause-resume-hit", x: 300, y: 232, width: 200, height: 44, target: "resume")
}
```

After `clear()`, also reset any client-side sets or dictionaries that were tracking retained object IDs for the previous screen. Keeping those IDs around can make later cleanup code look correct while it is actually referring to objects that have already been removed.

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

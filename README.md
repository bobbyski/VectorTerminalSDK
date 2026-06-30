# VectorTerminalSDK

VectorTerminalSDK is a Swift wrapper for VectorTerminal Graphics escape sequences.

The intent is conceptually similar to `ncurses`: application authors should be able to draw and interact with VectorTerminal graphics without hand-writing ANSI/APC escape codes.

This package is intentionally early. It exists so the project can eventually ship two examples:

- A raw VTG example that shows the protocol directly.
- An SDK example that shows the friendlier Swift API.

For the full method-by-method API reference, see [API.md](API.md).

## Requirements

- macOS 16.0 or newer.
- Swift Package Manager with Swift tools 5.9 or newer.

## Source Layout

The SDK source is split by responsibility so protocol growth does not turn into another monolith:

- `Types.swift`: public color, point, canvas, input, mouse, and event value types.
- `VectorTerminalCanvas.swift`: core canvas initialization, handshake state, and shared send/write helpers.
- `VectorTerminalCanvas+Scene.swift`: retained scene, layer, viewport, and hit-region controls.
- `VectorTerminalCanvas+Drawing.swift`: VTG drawing primitives, including sharp/rounded `rect(...)`, stroked paths, curves, and raster image placement.
- `VectorTerminalCanvas+VectorText.swift`: ASCII-subset vector text convenience built on VTG `draw(...)`.
- `VectorTerminalCanvas+Sprites.swift`: VTG sprite asset upload, retained sprite placement, and sprite transforms.
- `VectorTerminalCanvas+Frames.swift`: graphics-only offscreen frame helpers.
- `VectorTerminalCanvas+Queries.swift`: VTG capabilities, canvas, size, resize subscriptions, and terminal cell-size queries.
- `VTGCapabilities.swift`: typed parsing target for `capabilities?`, including the native under-text primitive subset.
- `VectorTerminalCanvas+Events.swift`: synchronous and async keyboard, mouse, resize, and canvas event parsing.
- `VectorTerminalCanvas+ANSI.swift`: standard ANSI screen, cursor, color, text-attribute, mouse, paste, and focus helpers.
- `VTGOutput.swift`: stdout/file-handle and closure-backed output transports.
- `VectorTerminalSession.swift`: scoped full-screen lifecycle setup/cleanup for demos and apps.
- `VectorGlyphs.swift`: ASCII-subset vector glyph stroke definitions.
- `TerminalRawMode.swift`: raw terminal input setup/restore helpers.
- `DebugEscaping.swift`: readable escape-sequence formatting for diagnostics.

## Current Implemented Scope

The current Swift implementation wraps:

- VTG `clear`
- VTG `present`
- VTG `pixel`
- VTG `line`
- VTG `draw` for polyline point lists
- VTG `curve` through `quadraticCurve(...)` and `cubicCurve(...)`
- optional stroke styling for supported vector primitives through `VTGLineCap` and `VTGLineJoin`
- VTG `triangle` with optional rounded corners
- VTG `path` with constrained absolute `M`, `L`, `Q`, `C`, and `Z` payloads
- VTG `rect` with optional rounded corners and per-corner selectors
- VTG `circle`
- VTG `ellipse`
- VTG `text`
- VTG `image` for retained PNG/JPEG placement
- VTG `capabilities?` as raw text and as typed `VTGCapabilities`
- VTG `canvas?`
- VTG `size?` through `querySize(...)` and as a fallback through `queryCurrentCanvas(...)`
- resize event enable/disable commands
- common ANSI screen, cursor, color, text-attribute, mouse, paste, and focus controls
- `setCursor(row:column:)` convenience alias for absolute ANSI cursor positioning
- `vectorPrint(id:x:y:height:value:stroke:width:)` for ASCII-subset vector text built on `draw`
- `vectorTextSize(height:value:)` for measuring the pixel advance consumed by SDK vector text
- async VTG-native mouse events with pixel coordinates, terminal cell coordinates, optional fixed-viewport virtual coordinates, mouse button, raw down/up, debounced click, drag, and scroll wheel data
- synchronous event polling with `readEvent(timeoutMilliseconds:)`
- `VectorTerminalSession` for scoped alternate screen, cursor, resize, mouse, raw-input, and cleanup management
- typed arrow-key events for `up`, `down`, `left`, and `right`
- terminal character-cell size queries with `queryTerminalCellSize()`
- small retained bitmap, indexed, or vector sprites that can be uploaded once, moved, rotated, anchored, and scaled without resending payload data
- named VTG layer constants through `VTGLayer.underText`, `VTGLayer.textPlane`, `VTGLayer.defaultOverlay`, and `VTGLayer.overlay1...overlay4`
- a `canvas.defaultLayer` property plus `setDefaultLayer(_:)` for changing the terminal-side retained drawing default
- retained-object layer reassignment with `setLayer(id:layer:)`
- overlay layer opacity with `setLayerAlpha(_:alpha:)`
- fixed-resolution overlay compatibility with `setViewportMode(layer:width:height:scale:)`, `setViewportScale(layer:scale:x:y:)`, and `clearViewportMode(layer:)`
- graphics-only offscreen frames with `startFrame(id:timeoutMilliseconds:)`, `endFrame(id:)`, `cancelFrame(id:)`, and `withFrame(id:timeoutMilliseconds:_:)`
- typed frame lifecycle events through `.frame(VTGFrameEvent)` for `frameStarted`, `frameCommitted`, `frameCanceled`, `frameTimeout`, and `frameRejected`

Retained scene helpers, layout abstractions, and higher-level widgets are planned follow-ups.

The preferred input API should use Swift `AsyncSequence` event streams.

The first async event pass exposes keyboard bytes, VTG-native mouse events, fallback ANSI mouse events, resize events, and polled canvas updates through `VectorTerminalCanvas.events(...)`.

## SDK To Raw VTG Quick Map

This table is the fastest way to see what the SDK emits. `ESC _` starts an APC control string and `ESC \` terminates it.

| SDK call | Raw VTG sequence shape | Notes |
|---|---|---|
| `canvas.queryCapabilities(...)` | `ESC _ VTG;capabilities? ESC \` | Reads the raw capabilities response. |
| `canvas.queryCapabilityInfo(...)` | `ESC _ VTG;capabilities? ESC \` | Parses the response into `VTGCapabilities`, including `underTextPrimitives`. |
| `canvas.queryCanvas(...)` | `ESC _ VTG;canvas? ESC \` | Preferred direct pixel-canvas query. |
| `canvas.querySize(...)` | `ESC _ VTG;size? ESC \` | Legacy compatibility pixel-canvas query. |
| `canvas.queryCurrentCanvas(...)` | `canvas?`, then `size?`, then `capabilities?` | Best app-facing size query. |
| `canvas.enableResizeEvents()` | `ESC _ VTG;resizeEvents,enabled=1 ESC \` | Subscribes to terminal resize events. |
| `canvas.disableResizeEvents()` | `ESC _ VTG;resizeEvents,enabled=0 ESC \` | Unsubscribes from terminal resize events. |
| `canvas.enableMouseReporting(...)` | `ESC _ VTG;mouseEvents,enabled=1,mode=<mode> ESC \` | Also enables ANSI mouse fallback modes. |
| `canvas.disableMouseReporting()` | `ESC _ VTG;mouseEvents,enabled=0 ESC \` | Also disables common ANSI mouse fallback modes. |
| `canvas.clear()` | `ESC _ VTG;clear ESC \` | Clears retained VTG scene state. |
| `canvas.present()` | `ESC _ VTG;present ESC \` | Presentation hint for the current retained scene. |
| `canvas.delete(id:)` | `ESC _ VTG;delete,id=<id> ESC \` | Removes one retained primitive by id. |
| `canvas.setDefaultLayer(_:)` / `canvas.defaultLayer = ...` | `ESC _ VTG;defaultLayer,layer=<-1-4> ESC \` | Changes the implicit layer for later retained drawing calls. |
| `canvas.setLayer(id:layer:)` | `ESC _ VTG;layer,id=<object-id>,layer=<-1-4> ESC \` | Moves an existing retained object between layers. |
| `canvas.scrollLayer(_:x:y:)` | `ESC _ VTG;layerScroll,layer=<1-4>,x=<px>,y=<px> ESC \` | Scrolls an overlay layer without changing object coordinates. |
| `canvas.setLayerAlpha(_:alpha:)` | `ESC _ VTG;layerAlpha,layer=<1-4>,alpha=<0-1> ESC \` | Fades a whole overlay layer. Layers -1 and 0 are excluded. |
| `canvas.clipLayer(_:x:y:width:height:)` | `ESC _ VTG;clip,layer=<-1-4>,x=<px>,y=<px>,w=<px>,h=<px> ESC \` | Rectangular layer clip. |
| `canvas.clearLayerClip(_:)` | `ESC _ VTG;clipClear,layer=<-1-4> ESC \` | Clears a rectangular layer clip. |
| `canvas.setViewportMode(layer:width:height:scale:)` | `ESC _ VTG;viewportMode,layer=<1-4>,width=<px>,height=<px>,scale=<mode> ESC \` | Fixed-resolution overlay coordinates. |
| `canvas.clearViewportMode(layer:)` | `ESC _ VTG;viewportMode,layer=<1-4>,value=native ESC \` | Restores native canvas coordinates. |
| `canvas.setViewportScale(layer:scale:x:y:)` | `ESC _ VTG;viewportScale,layer=<1-4>,scale=<n>,x=<px>,y=<px> ESC \` | Explicit fixed-viewport placement. |
| `canvas.hitRegion(id:x:y:width:height:layer:target:)` | `ESC _ VTG;hit,id=<id>,x=<px>,y=<px>,w=<px>,h=<px>,layer=<-1-4>,target=<id> ESC \` | Registers a rectangular hit region. |
| `canvas.clearHitRegions(id:layer:)` | `ESC _ VTG;hitClear,id=<id> ESC \`, `ESC _ VTG;hitClear,layer=<n> ESC \`, or `ESC _ VTG;hitClear ESC \` | Clears one, one layer, or all hit regions. |
| `canvas.pixel(...)` | `ESC _ VTG;pixel,id=<id>,x=<px>,y=<px>,color=<color> ESC \` | Single retained pixel. |
| `canvas.clearRect(...)` | `ESC _ VTG;clearRect,id=<id>,x=<px>,y=<px>,w=<px>,h=<px> ESC \` | Immediate region clear. Removes retained primitives on the target layer whose bounds touch the rectangle; it is not a background-colored fill. |
| `canvas.line(..., lineCap:)` | `ESC _ VTG;line,id=<id>,x1=<px>,y1=<px>,x2=<px>,y2=<px>,stroke=<color>,width=<n>,lineCap=<cap> ESC \` | Retained line segment. `lineCap` is optional. |
| `canvas.draw(..., lineCap:lineJoin:)` | `ESC _ VTG;draw,id=<id>,stroke=<color>,width=<n>,lineCap=<cap>,lineJoin=<join>;x,y x,y ... ESC \` | Retained polyline. Stroke style parameters are optional. |
| `canvas.quadraticCurve(..., lineCap:lineJoin:)` | `ESC _ VTG;curve,id=<id>,kind=quadratic,...,lineCap=<cap>,lineJoin=<join> ESC \` | Quadratic Bezier curve. Stroke style parameters are optional. |
| `canvas.cubicCurve(..., lineCap:lineJoin:)` | `ESC _ VTG;curve,id=<id>,kind=cubic,...,lineCap=<cap>,lineJoin=<join> ESC \` | Cubic Bezier curve. Stroke style parameters are optional. |
| `canvas.triangle(..., radius:lineJoin:)` | `ESC _ VTG;triangle,id=<id>,x1=<px>,y1=<px>,x2=<px>,y2=<px>,x3=<px>,y3=<px>,stroke=<color>,fill=<color>,width=<n>,radius=<px>,lineJoin=<join> ESC \` | Filled or stroked sharp/rounded triangle. `radius` and `lineJoin` are optional and omitted when unset. |
| `canvas.path(..., lineCap:lineJoin:)` | `ESC _ VTG;path,id=<id>,stroke=<color>,fill=<color>,width=<n>,lineCap=<cap>,lineJoin=<join>;M ... ESC \` | Constrained absolute `M`, `L`, `Q`, `C`, `Z` path grammar. Stroke style parameters are optional. |
| `canvas.rect(..., radius:corners:lineJoin:)` | `ESC _ VTG;rect,id=<id>,x=<px>,y=<px>,w=<px>,h=<px>,stroke=<color>,fill=<color>,width=<n>,radius=<px>,corners=<digits>,lineJoin=<join> ESC \` | Retained sharp or rounded rectangle. `radius`, `corners`, and `lineJoin` are optional and omitted when unset. `corners` uses `1` top-left, `2` top-right, `3` bottom-right, `4` bottom-left; omitted means all corners. |
| `canvas.circle(...)` | `ESC _ VTG;circle,id=<id>,cx=<px>,cy=<px>,r=<px>,stroke=<color>,fill=<color>,width=<n> ESC \` | Retained circle. |
| `canvas.ellipse(...)` | `ESC _ VTG;ellipse,id=<id>,cx=<px>,cy=<px>,rx=<px>,ry=<px>,stroke=<color>,fill=<color>,width=<n> ESC \` | Retained ellipse. |
| `canvas.text(...)` | `ESC _ VTG;text,id=<id>,x=<px>,y=<px>,color=<color>,size=<px>;text ESC \` | Pixel-positioned graphics text. |
| `canvas.image(...pngData:, filter:)` / `canvas.image(...jpegData:, filter:)` | `ESC _ VTG;image,id=<id>,format=<png/jpeg>,x=<px>,y=<px>,width=<px>,height=<px>,filter=<smooth/nearest>;base64 ESC \` | Uploads and places one retained raster image with optional smoothing or crisp pixel-art sampling. |
| `canvas.uploadSprite(..., filter: .smooth/.nearest)` | `ESC _ VTG;spriteUpload,id=<asset-id>,format=<png/jpeg>,width=<px>,height=<px>,filter=<smooth/nearest>;base64 ESC \` | Uploads or replaces a cached sprite asset, with optional smoothing or crisp pixel-art sampling. |
| `canvas.uploadVectorSprite(...)` | `ESC _ VTG;vectorSpriteUpload,id=<asset-id>,width=<px>,height=<px>,stroke=<color>,fill=<color>,lineWidth=<n>;path ESC \` | Uploads one constrained-path vector sprite asset. |
| `canvas.uploadSprite(...pixels:palette:, filter: .nearest)` / `canvas.uploadIndexedSprite(...)` | `ESC _ VTG;spriteDataUpload,id=<asset-id>,width=<px>,height=<px>,palette=<color>|<color>,transparent=<index>,filter=<smooth/nearest>;0,1,2,... ESC \` | Uploads a palette-indexed sprite from a numeric array for retro BASIC-style clients. |
| `canvas.sprite(...)` | `ESC _ VTG;sprite,id=<id>,image=<asset-id>,x=<px>,y=<px>,rotation=<deg>,scale=<n>,anchorX=<0-1>,anchorY=<0-1> ESC \` | Places or replaces a retained sprite instance. |
| `canvas.moveSprite(...)` | `ESC _ VTG;spriteMove,id=<id>,x=<px>,y=<px> ESC \` | Moves a sprite instance. |
| `canvas.rotateSprite(...)` | `ESC _ VTG;spriteRotate,id=<id>,rotation=<deg> ESC \` | Rotates a sprite instance. |
| `canvas.anchorSprite(...)` | `ESC _ VTG;spriteAnchor,id=<id>,anchorX=<0-1>,anchorY=<0-1> ESC \` | Changes sprite pivot. |
| `canvas.transformSprite(...)` | `ESC _ VTG;spriteTransform,id=<id>,x=<px>,y=<px>,rotation=<deg>,scale=<n>,anchorX=<0-1>,anchorY=<0-1> ESC \` | One-call sprite frame update. |
| `canvas.removeSprite(id:)` | `ESC _ VTG;spriteRemove,id=<asset-id> ESC \` | Removes an uploaded sprite asset and dependent instances. |
| `canvas.clearSprites()` | `ESC _ VTG;spriteClear ESC \` | Removes all uploaded sprite assets and sprite instances. |
| `canvas.vectorPrint(...)` | many `ESC _ VTG;draw,... ESC \` calls | SDK convenience; not a separate VTG command. |
| `VectorTerminalCanvas.vectorTextSize(...)` / `canvas.vectorTextSize(...)` | none | SDK-only layout helper matching `vectorPrint(...)` advance math. |
| `canvas.pillButton(...)` | ANSI `ESC[6n`, optional `glyphSize?`, then under-text `rect` + ordinary terminal text + optional `hit` | SDK-only solid pill helper at the current cursor. Width is text plus one terminal cell on each side. |
| `canvas.startFrame(id:timeoutMilliseconds:)` | `ESC _ VTG;startFrame,id=<id>,timeout=<ms> ESC \` | Starts graphics-only offscreen buffering. |
| `canvas.endFrame(id:)` | `ESC _ VTG;endFrame,id=<id> ESC \` | Commits a pending graphics frame. |
| `canvas.cancelFrame(id:)` | `ESC _ VTG;cancelFrame,id=<id> ESC \` | Discards a pending graphics frame. |
| `canvas.withFrame(id:timeoutMilliseconds:_:)` | `startFrame` + drawing + `endFrame` or `cancelFrame` | SDK safety helper around graphics-only frames. |

`ESC _ VTG;begin,frame=<id> ESC \` was an early prototype spelling for frame batching. It is still documented as a deprecated wire compatibility item, but the SDK intentionally exposes only the newer `startFrame`, `endFrame`, `cancelFrame`, and `withFrame(...)` APIs.

## SDK To ANSI Quick Map

These helpers emit traditional terminal control sequences and continue to work even when VTG initialization fails.

| SDK call | Raw sequence shape | Notes |
|---|---|---|
| `canvas.bell()` | `BEL` | Audible or visual bell. |
| `canvas.writeText(...)` | plain sanitized bytes | Writes ordinary text. |
| `canvas.withRawInput(...)` | termios raw-mode change | Host-side input mode helper, not an escape sequence. |
| `canvas.enterAlternateScreen()` | `ESC [?1049h` | Switch to alternate screen. |
| `canvas.leaveAlternateScreen()` | `ESC [?1049l` | Return from alternate screen. |
| `canvas.clearScreen()` | `ESC [2J` | Clear visible screen. |
| `canvas.clearScrollbackAndScreen()` | `ESC [3J ESC [2J` | Clear scrollback and visible screen. |
| `canvas.clearLine()` | `ESC [2K` | Clear current line. |
| `canvas.clearToEndOfLine()` | `ESC [K` | Clear cursor to line end. |
| `canvas.moveCursor(row:column:)` / `canvas.setCursor(row:column:)` | `ESC [<row>;<col>H` | One-based terminal cell coordinates. |
| `canvas.moveCursorUp/Down/Forward/Backward(...)` | `ESC [<n>A/B/C/D` | Relative cursor movement. |
| `canvas.saveCursor()` / `canvas.restoreCursor()` | `ESC 7` / `ESC 8` | DEC cursor save and restore. |
| `canvas.hideCursor()` / `canvas.showCursor()` | `ESC [?25l` / `ESC [?25h` | Text cursor visibility. |
| `canvas.resetTextAttributes()` | `ESC [0m` | Reset SGR styling. |
| `canvas.bold(...)` | `ESC [1m` / `ESC [22m` | Toggle bold. |
| `canvas.underline(...)` | `ESC [4m` / `ESC [24m` | Toggle underline. |
| `canvas.inverse(...)` | `ESC [7m` / `ESC [27m` | Toggle inverse video. |
| `canvas.setForeground(...)` | `ESC [30-37m` or `ESC [90-97m` | ANSI indexed foreground. |
| `canvas.setBackground(...)` | `ESC [40-47m` or `ESC [100-107m` | ANSI indexed background. |
| `canvas.setForegroundRGB(...)` | `ESC [38;2;<r>;<g>;<b>m` | True-color foreground. |
| `canvas.setBackgroundRGB(...)` | `ESC [48;2;<r>;<g>;<b>m` | True-color background. |
| `canvas.enableBracketedPaste()` / `disableBracketedPaste()` | `ESC [?2004h` / `ESC [?2004l` | Bracketed paste mode. |
| `canvas.enableFocusReporting()` / `disableFocusReporting()` | `ESC [?1004h` / `ESC [?1004l` | Terminal focus events. |
| `canvas.enableMouseReporting(...)` | VTG mouse plus `ESC [?1000h` and `ESC [?1006h` | VTG-native primary path with ANSI SGR fallback. |
| `canvas.disableMouseReporting()` | VTG mouse off plus `ESC [?1016l`, `?1015l`, `?1006l`, `?1005l`, `?1003l`, `?1002l`, `?1000l`, `?9l` | Broad mouse cleanup for shell restore safety. |

## VTGShowcase Gallery Demo

`VTGShowcase` teaches the protocol as it runs. It draws examples of VTG drawing commands, with the friendly SDK call shown beside or below the graphic and the raw escape sequence shown underneath.

The current version covers `pixel`, `clearRect`, `line`, `draw`, `rect`, `circle`, `ellipse`, `text`, `vectorPrint`, `curve`, `triangle`, bitmap image upload, bitmap sprite move/rotate examples, first-pass vector sprites backed by constrained path payloads, palette-indexed numeric sprites for retro BASIC-style clients, layers, clipping, hit regions, and a playable tic-tac-toe tab.

The point of this demo is documentation by inspection: users should be able to run it, see the rendered result, see the Swift SDK call that produced it, and see the exact escape sequence that would produce the same command without the SDK.

## Additions From VectorTank Development

VectorTank pushed the SDK beyond one-shot drawing and mouse-click demos. The following SDK surface was added or hardened while building that demo:

- `TerminalCellSize`: a small value type for terminal rows/columns.
- `queryTerminalCellSize()`: reads the current terminal character grid through `ioctl(TIOCGWINSZ)`.
- `TerminalGlyphSize`, `queryTerminalGlyphSize()`, and `queryTerminalWSize()`: ask VTG for the pixel width and height of a normal terminal `W` cell through `glyphSize?`, with local fallbacks for older hosts.
- `pillButton(...)`: creates a solid rounded pill at the current terminal cursor position using `TerminalGlyphSize`, writes the label as ordinary terminal text, and can attach the matching hit region for mouse-driven apps.
- `queryCurrentCanvas(timeoutMilliseconds:)`: asks `canvas?`, falls back to `size?`, then falls back to `capabilities?` canvas fields. This gives real-time demos one preferred way to learn their pixel canvas.
- `readEvent(timeoutMilliseconds:)`: a synchronous event-polling API for frame loops that want to drain input each tick.
- `VectorTerminalSession`: a scoped lifecycle helper for alternate screen, hidden cursor, resize/mouse subscriptions, optional raw input, idempotent cleanup, broad mouse-mode teardown, and a short pending-input drain before restoring cooked terminal mode.
- `ANSISpecialKey` and `.specialKey(...)`: typed arrow-key events for continuous movement controls.
- CSI/SS3 escape completion fixes: arrow keys now wait for the real final byte instead of treating `ESC [` as complete.
- SGR mouse escape completion fixes: `ESC [ < ... M/m` is treated as one complete mouse event.
- VTG APC envelope cleanup: query and event parsers strip the trailing `ESC \` before reading comma fields, preventing the final value from being polluted by the string terminator.
- Better VTG resize/canvas event parsing through the same event path used by game loops.

These APIs are intentionally still low-level. `VectorTerminalSession` now wraps common setup/teardown patterns such as alternate screen, raw input, hidden cursor, resize subscriptions, mouse subscriptions, and cleanup. On teardown it disables VTG-native mouse events plus common xterm mouse modes before briefly draining pending input, which keeps queued mouse-up/click bytes from leaking into the shell or the next app launch. A later frame-loop helper can build on top of it with a steady tick rate, input draining, and optional offscreen-frame coordination.

Graphics-only offscreen frames also emit lifecycle responses that the SDK parses into `.frame(...)` events:

```text
ESC _ VTG;frameStarted,id=<id>,timeout=<ms> ESC \
ESC _ VTG;frameCommitted,id=<id> ESC \
ESC _ VTG;frameCanceled,id=<id>,reason=app ESC \
ESC _ VTG;frameTimeout,id=<id>,reason=timeout ESC \
ESC _ VTG;frameRejected,id=<id>,reason=nested ESC \
ESC _ VTG;frameRejected,id=<id>,reason=idMismatch ESC \
```

`VTGShowcase` uses these events on its Frames tab: normal animation shows `frameCommitted`, while the tab's probe buttons intentionally exercise `frameCanceled` and `frameTimeout`.

VTG mouse events use APC framing and include both coordinate systems:

```text
ESC _ VTG;mouse,type=down,button=0,x=412,y=318,cellX=42,cellY=17,mods=none ESC \
ESC _ VTG;mouse,type=click,button=0,x=412,y=318,cellX=42,cellY=17,mods=none ESC \
ESC _ VTG;mouse,type=scroll,button=5,x=412,y=318,cellX=42,cellY=17,scrollX=0,scrollY=-3,mods=none ESC \
```

`x`/`y` are graphics-canvas pixel coordinates. `cellX`/`cellY` are 1-based terminal cell coordinates. Gameplay-style code should usually act on `type=click`, which VectorTerminal synthesizes from a matching mouse-down/mouse-up pair.

## Capability Schema

`capabilities?` advertises a versioned flat schema while preserving older fields:

```text
ESC _ VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=1.5.4,... ESC \
```

Important fields:

- `protocol=VTG`: identifies the graphics protocol.
- `schema=vtg.capabilities.v1`: identifies the shape of the capability response.
- `version=1.5.4`: identifies the VTG wire command version.
- `renderer=metal|coreGraphics|svg|overlay`: identifies the host terminal view's active renderer. The SDK exposes it as a string so clients can observe future renderer names without waiting for a package update.
- `commands=...`: pipe-separated implemented command names.
- `planned=...`: pipe-separated documented command names that are not yet implemented.
- `raster=image|filter`: retained raster image features.
- `sprites=bitmap|indexed|vector|move|rotate|scale|filter`: sprite asset and instance features.
- `textPlane=reserved`: layer `0` exists in the protocol model and has experimental renderer spikes, but it is not yet a finished shared text/graphics feature contract for applications to depend on. The SDK exposes this through `VTGCapabilities.textPlaneStatus` so apps do not need to compare raw strings.
- `events=mouse|resize|frame`: host-published event streams.

Older SDK code can continue checking only for `_VTG;capabilities`. Newer clients should prefer `schema` and `commands` when choosing optional features.

## Example

```swift
import VectorTerminalSDK

let canvas = try VectorTerminalCanvas()
let size = canvas.queryCanvas()

VectorTerminalSession.run(canvas: canvas) { _ in
    canvas.clear()
    canvas.pixel(id: "origin-dot", x: 20, y: 20, color: .green)
    canvas.rect(id: "border", x: 5, y: 5, width: 600, height: 400, stroke: .green)
    canvas.rect(id: "panel", x: 30, y: 70, width: 220, height: 120, stroke: .cyan, fill: "#07111dcc", radius: 18, corners: "12")
    canvas.line(id: "line", x1: 40, y1: 40, x2: 300, y2: 240, stroke: .blue, width: 4)
    canvas.draw(id: "zig", points: [.init(x: 40, y: 80), .init(x: 90, y: 40), .init(x: 140, y: 80)], stroke: .cyan, width: 3)
    canvas.vectorPrint(id: "arcade", x: 40, y: 120, height: 42, value: "GAME OVER", stroke: .green, width: 3)
    canvas.text(id: "label", x: 40, y: 40, value: "Hello VTG", color: .white, size: 18)
    canvas.present()
}
```

## ANSI Fallback

VTG drawing commands are gated by the VectorTerminal handshake. Common ANSI commands are not.

That means a program can catch failed VTG initialization and continue with normal terminal behavior:

```swift
let terminal: VectorTerminalCanvas

do {
    terminal = try VectorTerminalCanvas()
} catch {
    terminal = .noOp()
    terminal.setForeground(.yellow)
    terminal.writeText("VectorTerminal graphics are unavailable; continuing in text mode.\n")
    terminal.resetTextAttributes()
}
```

In the fallback case, VTG drawing methods no-op, but ANSI methods such as `clearScreen()`, `moveCursor(row:column:)`, `setForeground(_:)`, `enterAlternateScreen()`, and `showCursor()` still emit standard terminal control sequences.

## Design Direction

The SDK should eventually provide:

- A typed canvas API.
- A scoped session API for full-screen app setup/teardown. The first `VectorTerminalSession` pass is implemented.
- Immediate drawing first.
- A polyline `draw(...)` primitive for batching connected line segments into one VTG command.
- Bezier curve primitives in the core canvas API, shaped as `quadraticCurve(...)` and `cubicCurve(...)` helpers over one VTG `curve` escape sequence.
- Filled polygon basics start with sharp/rounded `triangle(...)`, with constrained `path(...)` support for absolute `M`, `L`, `Q`, `C`, and `Z` path payloads.
- Raster image placement starts with retained PNG/JPEG `image(...)` uploads and optional `smooth`/`nearest` filtering. Small bitmap sprite helpers support upload/place/move/rotate/anchor/scale for icons, cursors, simple game objects, and other tiny raster assets where vector primitives would be awkward. Vector sprite helpers now upload one constrained path payload as a reusable sprite asset and use the same placement, normalized anchor, and transform model as bitmap sprites. Palette-indexed sprite helpers upload a numeric pixel array plus a color palette, which keeps retro BASIC demos compact while still reusing the same retained sprite placement and transform commands.
- Layer support starts with named constants in `VTGLayer`, `canvas.defaultLayer`, `setDefaultLayer(_:)`, `setLayer(id:layer:)`, `scrollLayer(_:x:y:)`, `setLayerAlpha(_:alpha:)`, `clipLayer(_:x:y:width:height:)`, `clearLayerClip(_:)`, `delete(id:)`, and optional `layer:` parameters on drawing helpers. The current terminal prototype orders primitives by layer `-1...4`: layer `-1` is an under-text graphics plane, layer `0` is the reserved text plane, and layers `1...4` are ordered overlays. CoreGraphics and Metal both have experimental layer `0` render spikes for validation, but the SDK still treats `textPlane=reserved` as the public contract until scrollback, selection, ANSI clear behavior, and text ordering semantics settle. Independent scroll offsets and opacity apply to layers `1...4`; rectangular clips are supported across the graphics layers. Object-level clips and non-rectangular clipping are planned for later renderer work.
- Fixed-resolution compatibility starts with `setViewportMode(layer:width:height:scale:)`, `setViewportScale(layer:scale:x:y:)`, and `clearViewportMode(layer:)`. The scene stores this state for overlay layers only, and the macOS overlay renderer scales those layers with `fit`, `fill`, `integer`, or `stretch` behavior. Mouse events include `viewportLayer`, `virtualX`, and `virtualY` when the physical event lands inside a fixed-resolution viewport.
- Hit regions start with rectangular `hitRegion(...)` registration and `clearHitRegions(...)`. VTG mouse events include `hitID` and optional `targetID` when a click, drag, raw mouse, or scroll event lands inside the topmost matching region.
- Graphics-only offscreen frames start with `startFrame`, `endFrame`, `cancelFrame`, and `withFrame`. This first pass buffers VTG drawing commands into a pending retained scene while ANSI text remains visible. Full ANSI transactional rendering is a later renderer phase.
- A retained-object scene API as a second phase.
- Full off-screen rendering/composition support as part of the scene-graph phase.
- Layout helpers for panes, grids, and hit regions.
- Mouse and keyboard input wrappers exposed as async event streams.
- Higher-level frame-loop helpers built on top of `VectorTerminalSession`.

Widgets should live in a separate package rather than the core SDK. The likely split is:

- `VectorTerminalSDK`: canvas, session, protocol wrappers, async events.
- `VectorTerminalScene`: retained scene graph and off-screen composition.
- `VectorTerminalWidgets`: buttons, labels, logs, and simple controls.

The SDK should not replace the raw protocol documentation. It should sit above it.

## Output Transports

The SDK can now emit VTG bytes through an output abstraction instead of assuming every program is a child process writing to stdout.

Process-hosted apps still use the throwing initializer:

```swift
let canvas = try VectorTerminalCanvas()
```

That path writes to `FileHandle.standardOutput`, reads handshake responses from `FileHandle.standardInput`, and throws if VectorTerminal is not detected.

Host-fed apps can provide their own output:

```swift
let output = ClosureVTGOutput { data in
    vectorTerminalView.feedVTG(data)
}

let canvas = VectorTerminalCanvas.hostValidated(output: output)
canvas.line(id: "basic-line", x1: 20, y1: 20, x2: 220, y2: 120, stroke: .green)
```

Use `hostValidated(output:)` only when the embedding app has already selected a VTG-capable `VectorTerminalView`. This is the BASICStudio-style path: there is no child process terminal, so the host routes SDK-emitted bytes directly into the terminal view.

## Initialization Behavior

The friendly SDK path should require a successful VectorTerminal handshake before drawing commands are emitted.

If initialization has not succeeded, drawing APIs should silently no-op. This prevents VTG escape sequences from leaking into traditional terminals.

Discovery should use VTG APC framing:

```text
ESC _ VTG;capabilities? ESC \
```

ANSI/ECMA-48-style terminals are expected to consume or ignore unknown APC control strings, so this is intended to be a terminal-safe query. The SDK should still use a short timeout and treat no response as "not VectorTerminal."

## Language Roadmap

Support should be Swift first, then C/C++, then Python, then C#, then Java.

## Future Tic-Tac-Toe Demonstrations

After the raw VectorTicTacToe app stabilizes, add a second implementation:

- `VectorTicTacToeRaw`: direct escape sequences for protocol transparency.
- `VectorTicTacToeSDK`: same game using VectorTerminalSDK.

That gives users both a low-level protocol example and an ergonomic Swift example.

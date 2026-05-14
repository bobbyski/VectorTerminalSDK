# VectorTerminalSDK

VectorTerminalSDK is a Swift wrapper for VectorTerminal Graphics escape sequences.

The intent is conceptually similar to `ncurses`: application authors should be able to draw and interact with VectorTerminal graphics without hand-writing ANSI/APC escape codes.

This package is intentionally early. It exists so the project can eventually ship two examples:

- A raw VTG example that shows the protocol directly.
- An SDK example that shows the friendlier Swift API.

## Requirements

- macOS 16.0 or newer.
- Swift Package Manager with Swift tools 5.9 or newer.

## Source Layout

The SDK source is split by responsibility so protocol growth does not turn into another monolith:

- `Types.swift`: public color, point, canvas, input, mouse, and event value types.
- `VectorTerminalCanvas.swift`: core canvas initialization, handshake state, and shared send/write helpers.
- `VectorTerminalCanvas+Drawing.swift`: VTG drawing primitives, including `draw(...)` and `vectorPrint(...)`.
- `VectorTerminalCanvas+Queries.swift`: VTG capabilities, canvas, size, resize subscriptions, and terminal cell-size queries.
- `VectorTerminalCanvas+Events.swift`: synchronous and async keyboard, mouse, resize, and canvas event parsing.
- `VectorTerminalCanvas+ANSI.swift`: standard ANSI screen, cursor, color, text-attribute, mouse, paste, and focus helpers.
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
- VTG `triangle`
- VTG `path` with constrained absolute `M`, `L`, `Q`, `C`, and `Z` payloads
- VTG `rect`
- VTG `circle`
- VTG `ellipse`
- VTG `text`
- VTG `image` for retained PNG/JPEG placement
- VTG `capabilities?`
- VTG `canvas?`
- VTG `size?` fallback through `queryCurrentCanvas(...)`
- resize event enable/disable commands
- common ANSI screen, cursor, color, text-attribute, mouse, paste, and focus controls
- `setCursor(row:column:)` convenience alias for absolute ANSI cursor positioning
- `vectorPrint(id:x:y:height:value:stroke:width:)` for ASCII-subset vector text built on `draw`
- async VTG-native mouse events with pixel coordinates, terminal cell coordinates, mouse button, raw down/up, debounced click, drag, and scroll wheel data
- synchronous event polling with `readEvent(timeoutMilliseconds:)`
- `VectorTerminalSession` for scoped alternate screen, cursor, resize, mouse, raw-input, and cleanup management
- typed arrow-key events for `up`, `down`, `left`, and `right`
- terminal character-cell size queries with `queryTerminalCellSize()`
- small retained bitmap or vector sprites that can be uploaded once, moved, rotated, anchored, and scaled without resending payload data
- named VTG layer constants through `VTGLayer.textPlane`, `VTGLayer.defaultOverlay`, and `VTGLayer.overlay1...overlay4`
- retained-object layer reassignment with `setLayer(id:layer:)`
- overlay layer opacity with `setLayerAlpha(_:alpha:)`

Retained scene helpers, layout abstractions, and higher-level widgets are planned follow-ups.

The preferred input API should use Swift `AsyncSequence` event streams.

The first async event pass exposes keyboard bytes, VTG-native mouse events, fallback ANSI mouse events, resize events, and polled canvas updates through `VectorTerminalCanvas.events(...)`.

## VTGShowcase Gallery Demo

`VTGShowcase` teaches the protocol as it runs. It draws examples of VTG drawing commands, with the friendly SDK call shown beside or below the graphic and the raw escape sequence shown underneath.

The current version covers `pixel`, `line`, `draw`, `rect`, `circle`, `ellipse`, `text`, `vectorPrint`, `curve`, `triangle`, bitmap image upload, bitmap sprite move/rotate examples, first-pass vector sprites backed by constrained path payloads, layers, clipping, hit regions, and a playable tic-tac-toe tab.

The point of this demo is documentation by inspection: users should be able to run it, see the rendered result, see the Swift SDK call that produced it, and see the exact escape sequence that would produce the same command without the SDK.

## Additions From VectorTank Development

VectorTank pushed the SDK beyond one-shot drawing and mouse-click demos. The following SDK surface was added or hardened while building that demo:

- `TerminalCellSize`: a small value type for terminal rows/columns.
- `queryTerminalCellSize()`: reads the current terminal character grid through `ioctl(TIOCGWINSZ)`.
- `queryCurrentCanvas(timeoutMilliseconds:)`: asks `canvas?`, falls back to `size?`, then falls back to `capabilities?` canvas fields. This gives real-time demos one preferred way to learn their pixel canvas.
- `readEvent(timeoutMilliseconds:)`: a synchronous event-polling API for frame loops that want to drain input each tick.
- `VectorTerminalSession`: a scoped lifecycle helper for alternate screen, hidden cursor, resize/mouse subscriptions, optional raw input, idempotent cleanup, broad mouse-mode teardown, and a short pending-input drain before restoring cooked terminal mode.
- `ANSISpecialKey` and `.specialKey(...)`: typed arrow-key events for continuous movement controls.
- CSI/SS3 escape completion fixes: arrow keys now wait for the real final byte instead of treating `ESC [` as complete.
- SGR mouse escape completion fixes: `ESC [ < ... M/m` is treated as one complete mouse event.
- VTG APC envelope cleanup: query and event parsers strip the trailing `ESC \` before reading comma fields, preventing the final value from being polluted by the string terminator.
- Better VTG resize/canvas event parsing through the same event path used by game loops.

These APIs are intentionally still low-level. `VectorTerminalSession` now wraps common setup/teardown patterns such as alternate screen, raw input, hidden cursor, resize subscriptions, mouse subscriptions, and cleanup. On teardown it disables VTG-native mouse events plus common xterm mouse modes before briefly draining pending input, which keeps queued mouse-up/click bytes from leaking into the shell or the next app launch. A later frame-loop helper can build on top of it with a steady tick rate, input draining, and optional offscreen-frame coordination.

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
ESC _ VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=0.1,... ESC \
```

Important fields:

- `protocol=VTG`: identifies the graphics protocol.
- `schema=vtg.capabilities.v1`: identifies the shape of the capability response.
- `version=0.1`: identifies the VTG wire command version.
- `commands=...`: pipe-separated implemented command names.
- `planned=...`: pipe-separated documented command names that are not yet implemented.
- `events=mouse|resize`: host-published event streams.

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
- Filled polygon basics start with `triangle(...)`, with constrained `path(...)` support for absolute `M`, `L`, `Q`, `C`, and `Z` path payloads.
- Raster image placement starts with retained PNG/JPEG `image(...)` uploads. Small bitmap sprite helpers support upload/place/move/rotate/anchor/scale for icons, cursors, simple game objects, and other tiny raster assets where vector primitives would be awkward. Vector sprite helpers now upload one constrained path payload as a reusable sprite asset and use the same placement, normalized anchor, and transform model as bitmap sprites.
- Layer support starts with named constants in `VTGLayer`, `setDefaultLayer(_:)`, `setLayer(id:layer:)`, `scrollLayer(_:x:y:)`, `setLayerAlpha(_:alpha:)`, `clipLayer(_:x:y:width:height:)`, `clearLayerClip(_:)`, and optional `layer:` parameters on drawing helpers. The current terminal prototype orders overlay primitives by layer `0...4`, supports independent scroll offsets and opacity for layers `1...4`, and supports rectangular layer clips; true layer 0 text/graphics mingling, object-level clips, and non-rectangular clipping are planned for later renderer work.
- Hit regions start with rectangular `hitRegion(...)` registration and `clearHitRegions(...)`. VTG mouse events include `hitID` and optional `targetID` when a click, drag, raw mouse, or scroll event lands inside the topmost matching region.
- A retained-object scene API as a second phase.
- Off-screen rendering/composition support as part of the scene-graph phase.
- Layout helpers for panes, grids, and hit regions.
- Mouse and keyboard input wrappers exposed as async event streams.
- Higher-level frame-loop helpers built on top of `VectorTerminalSession`.

Widgets should live in a separate package rather than the core SDK. The likely split is:

- `VectorTerminalSDK`: canvas, session, protocol wrappers, async events.
- `VectorTerminalScene`: retained scene graph and off-screen composition.
- `VectorTerminalWidgets`: buttons, labels, logs, and simple controls.

The SDK should not replace the raw protocol documentation. It should sit above it.

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

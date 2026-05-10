# VectorTerminalSDK

VectorTerminalSDK is a Swift wrapper for VectorTerminal Graphics escape sequences.

The intent is conceptually similar to `ncurses`: application authors should be able to draw and interact with VectorTerminal graphics without hand-writing ANSI/APC escape codes.

This package is intentionally early. It exists so the project can eventually ship two examples:

- A raw VTG example that shows the protocol directly.
- An SDK example that shows the friendlier Swift API.

## Current Implemented Scope

The current Swift implementation wraps:

- VTG `clear`
- VTG `present`
- VTG `line`
- VTG `draw` for polyline point lists
- VTG `rect`
- VTG `circle`
- VTG `ellipse`
- VTG `text`
- VTG `capabilities?`
- VTG `canvas?`
- VTG `size?` fallback through `queryCurrentCanvas(...)`
- resize event enable/disable commands
- common ANSI screen, cursor, color, text-attribute, mouse, paste, and focus controls
- `setCursor(row:column:)` convenience alias for absolute ANSI cursor positioning
- `vectorPrint(id:x:y:height:value:stroke:width:)` for ASCII-subset vector text built on `draw`
- async VTG-native mouse events with pixel coordinates, terminal cell coordinates, mouse button, raw down/up, debounced click, drag, and scroll wheel data
- synchronous event polling with `readEvent(timeoutMilliseconds:)`
- typed arrow-key events for `up`, `down`, `left`, and `right`
- terminal character-cell size queries with `queryTerminalCellSize()`

Planned but not yet implemented in the SDK:

- VTG `curve` for quadratic and cubic Bezier segments
- VTG `triangle` with stroke and fill support

Retained scene helpers, layout abstractions, and higher-level widgets are planned follow-ups.

The preferred input API should use Swift `AsyncSequence` event streams.

The first async event pass exposes keyboard bytes, VTG-native mouse events, fallback ANSI mouse events, resize events, and polled canvas updates through `VectorTerminalCanvas.events(...)`.

## Additions From VectorTank Development

VectorTank pushed the SDK beyond one-shot drawing and mouse-click demos. The following SDK surface was added or hardened while building that demo:

- `TerminalCellSize`: a small value type for terminal rows/columns.
- `queryTerminalCellSize()`: reads the current terminal character grid through `ioctl(TIOCGWINSZ)`.
- `queryCurrentCanvas(timeoutMilliseconds:)`: asks `canvas?`, falls back to `size?`, then falls back to `capabilities?` canvas fields. This gives real-time demos one preferred way to learn their pixel canvas.
- `readEvent(timeoutMilliseconds:)`: a synchronous event-polling API for frame loops that want to drain input each tick.
- `ANSISpecialKey` and `.specialKey(...)`: typed arrow-key events for continuous movement controls.
- CSI/SS3 escape completion fixes: arrow keys now wait for the real final byte instead of treating `ESC [` as complete.
- SGR mouse escape completion fixes: `ESC [ < ... M/m` is treated as one complete mouse event.
- Better VTG resize/canvas event parsing through the same event path used by game loops.

These APIs are intentionally still low-level. A later `VectorTerminalSession` or frame-loop helper should wrap common setup/teardown patterns such as alternate screen, raw input, hidden cursor, resize subscriptions, `clear`, and `present`.

VTG mouse events use APC framing and include both coordinate systems:

```text
ESC _ VTG;mouse,type=down,button=0,x=412,y=318,cellX=42,cellY=17,mods=none ESC \
ESC _ VTG;mouse,type=click,button=0,x=412,y=318,cellX=42,cellY=17,mods=none ESC \
ESC _ VTG;mouse,type=scroll,button=5,x=412,y=318,cellX=42,cellY=17,scrollX=0,scrollY=-3,mods=none ESC \
```

`x`/`y` are graphics-canvas pixel coordinates. `cellX`/`cellY` are 1-based terminal cell coordinates. Gameplay-style code should usually act on `type=click`, which VectorTerminal synthesizes from a matching mouse-down/mouse-up pair.

## Example

```swift
import VectorTerminalSDK

let canvas = try VectorTerminalCanvas()
let size = canvas.queryCanvas()

canvas.clear()
canvas.rect(id: "border", x: 5, y: 5, width: 600, height: 400, stroke: .green)
canvas.line(id: "line", x1: 40, y1: 40, x2: 300, y2: 240, stroke: .blue, width: 4)
canvas.draw(id: "zig", points: [.init(x: 40, y: 80), .init(x: 90, y: 40), .init(x: 140, y: 80)], stroke: .cyan, width: 3)
canvas.vectorPrint(id: "arcade", x: 40, y: 120, height: 42, value: "GAME OVER", stroke: .green, width: 3)
canvas.text(id: "label", x: 40, y: 40, value: "Hello VTG", color: .white, size: 18)
canvas.present()
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
- Immediate drawing first.
- A polyline `draw(...)` primitive for batching connected line segments into one VTG command.
- Bezier curve primitives in the core canvas API, probably shaped as `quadraticCurve(...)` and `cubicCurve(...)` helpers over one VTG `curve` escape sequence.
- Filled polygon basics should start with `triangle(...)` before growing into arbitrary paths. This gives us enough surface area for icons, arrows, and simple vector art without drifting into a full shader or GPU material system.
- A retained-object scene API as a second phase.
- Off-screen rendering/composition support as part of the scene-graph phase.
- Layout helpers for panes, grids, and hit regions.
- Mouse and keyboard input wrappers exposed as async event streams.
- Automatic alternate-screen and cleanup helpers.

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

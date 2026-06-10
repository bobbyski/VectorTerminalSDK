/// Unified input/event type returned by the SDK event readers.
///
/// Real-time demos such as VectorTank use this to drain keyboard, resize, and
/// canvas events inside a frame loop without hand-parsing terminal escape
/// sequences.
public enum VectorTerminalEvent: Equatable {
    /// One raw keyboard byte that was not part of a recognized escape sequence.
    case key(UInt8)

    /// Typed ANSI special key such as an arrow key.
    case specialKey(ANSISpecialKey)

    /// VTG-native or ANSI fallback mouse event.
    case mouse(VTGMouseEvent)

    /// VTG resize event containing the new pixel canvas size.
    case resize(VTGCanvas)

    /// Polled canvas-size update from the SDK compatibility poller.
    case canvas(VTGCanvas)

    /// VTG offscreen-frame lifecycle event.
    case frame(VTGFrameEvent)
}

/// Small typed subset of ANSI special keys needed by current demos.
///
/// This was added for VectorTank movement so arrow keys could share the same
/// code path as `w`/`s`/`a`/`d`.
public enum ANSISpecialKey: Equatable {
    /// Up arrow key.
    case up

    /// Down arrow key.
    case down

    /// Right arrow key.
    case right

    /// Left arrow key.
    case left
}

/// Unified input/event type returned by the SDK event readers.
///
/// Real-time demos such as VectorTank use this to drain keyboard, resize, and
/// canvas events inside a frame loop without hand-parsing terminal escape
/// sequences.
public enum VectorTerminalEvent: Equatable {
    case key(UInt8)
    case specialKey(ANSISpecialKey)
    case mouse(VTGMouseEvent)
    case resize(VTGCanvas)
    case canvas(VTGCanvas)
    case frame(VTGFrameEvent)
}

/// Small typed subset of ANSI special keys needed by current demos.
///
/// This was added for VectorTank movement so arrow keys could share the same
/// code path as `w`/`s`/`a`/`d`.
public enum ANSISpecialKey: Equatable {
    case up
    case down
    case right
    case left
}

import Foundation

/// Lifecycle event emitted by graphics-only offscreen frames.
///
/// These events let an app distinguish "frame was accepted", "frame was
/// committed", "app canceled it", "the terminal watchdog timed it out", and
/// "the terminal rejected the request" without hand-parsing VTG APC responses.
public struct VTGFrameEvent: Equatable {
    /// Frame lifecycle type, such as `frameStarted` or `frameCommitted`.
    public var type: String

    /// App-provided frame id.
    public var id: String

    /// Optional terminal-provided reason for cancel/reject/timeout events.
    public var reason: String?

    /// Timeout value reported by frame-start events, when present.
    public var timeoutMilliseconds: Int?

    /// Raw VTG frame response for diagnostics.
    public var rawResponse: String

    public init(
        type: String,
        id: String,
        reason: String? = nil,
        timeoutMilliseconds: Int? = nil,
        rawResponse: String = ""
    ) {
        self.type = type
        self.id = id
        self.reason = reason
        self.timeoutMilliseconds = timeoutMilliseconds
        self.rawResponse = rawResponse
    }
}

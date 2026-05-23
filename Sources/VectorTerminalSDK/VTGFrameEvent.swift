import Foundation

/// Lifecycle event emitted by graphics-only offscreen frames.
///
/// These events let an app distinguish "frame was accepted", "frame was
/// committed", "app canceled it", "the terminal watchdog timed it out", and
/// "the terminal rejected the request" without hand-parsing VTG APC responses.
public struct VTGFrameEvent: Equatable {
    public var type: String
    public var id: String
    public var reason: String?
    public var timeoutMilliseconds: Int?
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

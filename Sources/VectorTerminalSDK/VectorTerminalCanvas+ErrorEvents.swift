import Foundation

/// A sprite command that was refused, and why.
///
/// Comes from the terminal as `commandRejected` once a program has called
/// ``VectorTerminalCanvas/enableErrorEvents()``, or from the SDK itself when it
/// refuses to send a command at all. Delivered through
/// ``VectorTerminalCanvas/commandRejectedHandler``.
public struct VTGCommandRejection: Equatable {
    /// The VTG command refused, such as `spriteUpload` or `sprite`.
    public var command: String
    /// The id the command named.
    public var id: String
    /// Why: `badId`, `limit`, `badData`, `badFormat`, `badSize`, `badPalette`
    /// or `unknownAsset`.
    public var reason: String
    /// True when the terminal refused it; false when the SDK refused to send it.
    public var fromTerminal: Bool

    public init(command: String, id: String, reason: String, fromTerminal: Bool) {
        self.command = command
        self.id = id
        self.reason = reason
        self.fromTerminal = fromTerminal
    }
}

/// Being told when a sprite command is refused, rather than finding the
/// picture missing.
extension VectorTerminalCanvas {
    /// Ask the terminal to answer each refused sprite command with
    /// `commandRejected`. Off by default, so a program that never reads
    /// replies never has one arrive on its input.
    public func enableErrorEvents() {
        send("errorEvents,enabled=1")
    }

    /// Stop the terminal's `commandRejected` replies.
    public func disableErrorEvents() {
        send("errorEvents,enabled=0")
    }

    /// The SDK refused to send `command`: says so through
    /// ``commandRejectedHandler``.
    func refuse(_ command: String, id: String, _ reason: String) {
        commandRejectedHandler?(VTGCommandRejection(command: command, id: id, reason: reason, fromTerminal: false))
    }

    /// Hands a `commandRejected` reply to ``commandRejectedHandler``.
    /// Returns whether the response was one.
    func dispatchCommandRejected(_ name: String, response: String) -> Bool {
        guard name == "commandRejected" else {
            return false
        }
        let fields = vtgFields(from: response)
        commandRejectedHandler?(VTGCommandRejection(
            command: fields["command"] ?? "",
            id: fields["id"] ?? "",
            reason: fields["reason"] ?? "",
            fromTerminal: true
        ))
        return true
    }
}

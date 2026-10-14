import Foundation

/// A key going down, repeating, or coming up, from a terminal that reports
/// them (`keyEvents`). Delivered through ``VectorTerminalCanvas/keyEventHandler``.
///
/// A terminal otherwise sends a key's press and repeats and never its release,
/// and macOS repeats only the newest key — so a game holding an arrow cannot
/// tell it is still held once another key is pressed. These say.
public struct VTGKeyEvent: Equatable {
    public enum Kind: String {
        case down, up, `repeat`
    }

    public var kind: Kind
    /// `LEFT`, `SPACE`, `SHIFT`, `F5`…, or `CHAR` for a key that types.
    public var key: String
    /// For `CHAR`: the character the key types unshifted.
    public var character: Character?
    /// On `down`: the character this press typed, when it differs.
    public var text: Character?
    /// `left` or `right`, for the modifiers.
    public var side: String?
    /// As mouse events: `none`, or `shift`/`ctrl`/`alt`/`cmd` joined by `|`.
    public var modifiers: String
    /// Released because the terminal lost focus.
    public var lostFocus: Bool
    public var rawResponse: String

    public init(
        kind: Kind,
        key: String,
        character: Character? = nil,
        text: Character? = nil,
        side: String? = nil,
        modifiers: String = "none",
        lostFocus: Bool = false,
        rawResponse: String = ""
    ) {
        self.kind = kind
        self.key = key
        self.character = character
        self.text = text
        self.side = side
        self.modifiers = modifiers
        self.lostFocus = lostFocus
        self.rawResponse = rawResponse
    }
}

/// Being told which keys are held.
extension VectorTerminalCanvas {
    /// Ask the terminal to report each key going down and coming up — and,
    /// with `repeats`, the auto-repeats in between. Check the capabilities for
    /// `keyEvents` first: a terminal without it sends nothing.
    public func enableKeyEvents(repeats: Bool = false) {
        send("keyEvents,enabled=1" + (repeats ? ",repeat=1" : ""))
    }

    /// Stop the key messages.
    public func disableKeyEvents() {
        send("keyEvents,enabled=0")
    }

    /// Hands a `key` message to ``keyEventHandler``. Returns whether the
    /// response was one.
    func dispatchKeyEvent(_ name: String, response: String) -> Bool {
        guard name == "key" else {
            return false
        }
        let fields = vtgFields(from: response)
        guard let kind = fields["type"].flatMap(VTGKeyEvent.Kind.init(rawValue:)),
              let key = fields["key"] else {
            return true
        }
        func character(_ field: String) -> Character? {
            fields[field].flatMap(UInt32.init).flatMap(Unicode.Scalar.init).map(Character.init)
        }
        keyEventHandler?(VTGKeyEvent(
            kind: kind,
            key: key,
            character: character("char"),
            text: character("text"),
            side: fields["side"],
            modifiers: fields["mods"] ?? "none",
            lostFocus: fields["reason"] == "focus",
            rawResponse: response
        ))
        return true
    }
}

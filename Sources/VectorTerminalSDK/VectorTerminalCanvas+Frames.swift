import Foundation

/// Graphics-only offscreen frame helpers.
extension VectorTerminalCanvas {
    /// Start buffering VTG scene mutations into an offscreen graphics frame.
    ///
    /// This first implementation is graphics-only: ANSI text still reaches the
    /// terminal immediately, while VTG drawing commands are applied to a pending
    /// retained scene until `endFrame(id:)` commits it. The terminal discards
    /// a pending frame automatically after `timeoutMilliseconds` to avoid
    /// leaving a stale hidden scene if an app crashes mid-frame.
    public func startFrame(id: String, timeoutMilliseconds: Int = 250) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        let timeout = max(1, timeoutMilliseconds)
        send("startFrame,id=\(id),timeout=\(timeout)")
    }

    /// Commit a pending offscreen graphics frame into the visible VTG scene.
    public func endFrame(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("endFrame,id=\(id)")
    }

    /// Discard a pending offscreen graphics frame and keep the visible scene.
    public func cancelFrame(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("cancelFrame,id=\(id)")
    }

    /// Execute a VTG drawing block inside an offscreen graphics frame.
    ///
    /// If `body` throws, the SDK sends `cancelFrame` before rethrowing. That
    /// mirrors the terminal-side timeout safety with an app-side cleanup path
    /// for ordinary Swift errors.
    public func withFrame<T>(
        id: String,
        timeoutMilliseconds: Int = 250,
        _ body: () throws -> T
    ) rethrows -> T {
        startFrame(id: id, timeoutMilliseconds: timeoutMilliseconds)
        do {
            let value = try body()
            endFrame(id: id)
            return value
        } catch {
            cancelFrame(id: id)
            throw error
        }
    }
}

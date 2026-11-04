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
    ///
    /// - Parameters:
    ///   - id: The frame id, ASCII letters, digits, `-` and `_`, up to 64
    ///     characters. An invalid id sends nothing.
    ///   - timeoutMilliseconds: How long the terminal keeps the pending frame;
    ///     values below 1 are raised to 1.
    public func startFrame(id: String, timeoutMilliseconds: Int = 250) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        let timeout = max(1, timeoutMilliseconds)
        send("startFrame,id=\(id),timeout=\(timeout)")
    }

    /// Tell the terminal the app is finished, so it stops replying.
    ///
    /// Call this last, before restoring the terminal and exiting. VTG replies
    /// — a frame acknowledgement, a capabilities answer — are only meaningful
    /// to the app that asked. Once the app is gone, anything still on its way
    /// is delivered to whatever owns the terminal next, which is the user's
    /// shell, and a shell treats what it is given as typed input:
    ///
    ///     ❯ myappVTG;frameStarted,id=chrome,timeout=250
    ///
    /// After this the terminal still *applies* what it is sent — a departing
    /// app's `clear()` still takes effect — it simply stops answering.
    ///
    /// A terminal cannot be told this by an app that was killed rather than
    /// asked to stop, so hosts also stop answering on their own once they see
    /// the program has gone. This is the polite half of that.
    public func detach() {
        send("detach")
    }

    /// Commit a pending offscreen graphics frame into the visible VTG scene.
    ///
    /// - Parameter id: The id passed to `startFrame(id:timeoutMilliseconds:)`.
    ///   An invalid id sends nothing.
    public func endFrame(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("endFrame,id=\(id)")
    }

    /// Discard a pending offscreen graphics frame and keep the visible scene.
    ///
    /// - Parameter id: The id passed to `startFrame(id:timeoutMilliseconds:)`.
    ///   An invalid id sends nothing.
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
    ///
    /// - Parameters:
    ///   - id: The frame id, ASCII letters, digits, `-` and `_`, up to 64
    ///     characters. An invalid id sends nothing.
    ///   - timeoutMilliseconds: How long the terminal keeps the pending frame;
    ///     values below 1 are raised to 1.
    ///   - body: The drawing to buffer. `endFrame` is sent when it returns.
    /// - Returns: The value `body` returns.
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

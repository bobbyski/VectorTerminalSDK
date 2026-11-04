/// Scoped execution helpers for `VectorTerminalSession`.
extension VectorTerminalSession {
    /// Run synchronous work inside a scoped terminal session.
    ///
    /// Calls `start()` before `body` and `end()` after it, even when it throws.
    ///
    /// - Parameters:
    ///   - canvas: The canvas the session draws through.
    ///   - options: Which terminal states to apply and restore. Defaults to `.init()`.
    ///   - body: The work to run, given the active session.
    /// - Returns: Whatever `body` returns.
    public static func run<T>(
        canvas: VectorTerminalCanvas,
        options: VectorTerminalSessionOptions = .init(),
        _ body: (VectorTerminalSession) throws -> T
    ) rethrows -> T {
        let session = VectorTerminalSession(canvas: canvas, options: options)
        session.start()
        defer { session.end() }
        return try body(session)
    }

    /// Run asynchronous work inside a scoped terminal session.
    ///
    /// Calls `start()` before `body` and `end()` after it, even when it throws.
    ///
    /// - Parameters:
    ///   - canvas: The canvas the session draws through.
    ///   - options: Which terminal states to apply and restore. Defaults to `.init()`.
    ///   - body: The asynchronous work to run, given the active session.
    /// - Returns: Whatever `body` returns.
    public static func run<T>(
        canvas: VectorTerminalCanvas,
        options: VectorTerminalSessionOptions = .init(),
        _ body: (VectorTerminalSession) async throws -> T
    ) async rethrows -> T {
        let session = VectorTerminalSession(canvas: canvas, options: options)
        session.start()
        defer { session.end() }
        return try await body(session)
    }
}

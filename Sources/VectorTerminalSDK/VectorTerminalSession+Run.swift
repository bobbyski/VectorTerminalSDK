/// Scoped execution helpers for `VectorTerminalSession`.
extension VectorTerminalSession {
    /// Run synchronous work inside a scoped terminal session.
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

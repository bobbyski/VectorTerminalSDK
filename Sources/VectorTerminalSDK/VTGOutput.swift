import Foundation

/// Destination for bytes emitted by `VectorTerminalCanvas`.
///
/// Process-hosted apps normally use `FileHandle.standardOutput`. Host-fed apps
/// such as BASICStudio can provide a closure that feeds bytes into a
/// `VectorTerminalView` instead. Keeping output behind this tiny protocol lets
/// the SDK generate the same VTG wire protocol in both cases.
public protocol VTGOutput: AnyObject {
    /// Write raw terminal bytes to the destination.
    func write(_ data: Data)
}

extension FileHandle: VTGOutput {}

/// Closure-backed `VTGOutput` for in-process hosts.
///
/// This is the bridge BASICStudio-style apps can use when there is no child
/// process and no stdout stream. The closure should deliver bytes to the host
/// terminal view exactly as if they had arrived from a process.
public final class ClosureVTGOutput: VTGOutput {
    private let writer: (Data) -> Void

    public init(_ writer: @escaping (Data) -> Void) {
        self.writer = writer
    }

    public func write(_ data: Data) {
        writer(data)
    }
}

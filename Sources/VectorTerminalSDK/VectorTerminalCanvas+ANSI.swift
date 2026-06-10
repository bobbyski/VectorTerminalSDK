import Foundation

/// ANSI convenience helpers exposed by the SDK.
///
/// These functions intentionally keep working even when VTG initialization
/// failed and the caller is using a no-op graphics canvas.
extension VectorTerminalCanvas {
    /// Emit an audible/visual terminal bell.
    public func bell() {
        writeANSI("\u{07}")
    }

    /// Write plain text after removing control bytes unsafe for VTG payloads.
    public func writeText(_ value: String) {
        output.write(Data(sanitizedPayload(value).utf8))
    }

}

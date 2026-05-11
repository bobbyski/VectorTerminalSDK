import Foundation

/// High-level Swift entry point for VectorTerminal Graphics.
///
/// The initializer performs a VTG capabilities query and throws when graphics
/// are not available. Apps can catch that error and fall back to normal ANSI
/// output, or use `noOp(...)` when they want drawing calls to silently do
/// nothing on traditional terminals.
public final class VectorTerminalCanvas {
    let output: FileHandle
    let input: FileHandle
    let esc = "\u{1B}"
    let isEnabled: Bool

    /// Optional hook used by demos to surface parser details during debugging.
    public var eventDebugHandler: ((String) -> Void)?

    /// Create a graphics-enabled VTG canvas after verifying terminal support.
    public init(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput,
        timeoutMilliseconds: Int = 750
    ) throws {
        self.input = input
        self.output = output
        self.isEnabled = true

        guard let response = query("capabilities?", timeoutMilliseconds: timeoutMilliseconds),
              response.contains("_VTG;capabilities") else {
            throw VectorTerminalSDKError.vectorTerminalNotDetected
        }
    }

    /// Create a canvas object whose VTG drawing commands are ignored.
    ///
    /// ANSI helper methods still write to `output`; only VTG graphics are gated.
    public static func noOp(
        input: FileHandle = .standardInput,
        output: FileHandle = .standardOutput
    ) -> VectorTerminalCanvas {
        VectorTerminalCanvas(input: input, output: output, isEnabled: false)
    }

    private init(input: FileHandle, output: FileHandle, isEnabled: Bool) {
        self.input = input
        self.output = output
        self.isEnabled = isEnabled
    }

    /// Send one private VTG APC command.
    func send(_ command: String, payload: String? = nil) {
        guard isEnabled else {
            return
        }
        let sequence: String
        if let payload {
            sequence = "\(esc)_VTG;\(command);\(payload)\(esc)\\"
        } else {
            sequence = "\(esc)_VTG;\(command)\(esc)\\"
        }
        output.write(Data(sequence.utf8))
    }

    /// Write a traditional ANSI sequence even if VTG graphics are disabled.
    func writeANSI(_ sequence: String) {
        output.write(Data(sequence.utf8))
    }

    /// Strip control characters that would terminate or corrupt an APC payload.
    func sanitizedPayload(_ value: String) -> String {
        value
            .replacingOccurrences(of: esc, with: "")
            .replacingOccurrences(of: "\u{07}", with: "")
    }

    /// Clamp an RGB channel for ANSI true-color helpers.
    func clampColor(_ value: Int) -> Int {
        min(255, max(0, value))
    }
}

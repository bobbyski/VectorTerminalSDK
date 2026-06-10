import Foundation

/// Shared wire-format helpers for VTG SDK commands.
extension VectorTerminalCanvas {
    /// VTG ids intentionally stay conservative so apps can embed them directly
    /// in comma-separated escape parameters without quoting rules.
    func isValidVTGIdentifier(_ value: String) -> Bool {
        guard value.isEmpty == false, value.count <= 64 else {
            return false
        }
        return value.allSatisfy { character in
            character.isASCII && (character.isLetter || character.isNumber)
        }
    }

    /// Compact floating-point parameters for transform-heavy sprite commands.
    func vtgNumber(_ value: Double) -> String {
        let rounded = value.rounded()
        if abs(value - rounded) < 0.001 {
            return String(Int(rounded))
        }
        return String(format: "%.3f", value)
    }

    /// Emit a layer parameter only when the caller asks for a supported layer.
    func layerParameter(_ layer: Int?) -> String {
        guard let layer, isSupportedVTGLayer(layer) else {
            return ""
        }
        return ",layer=\(layer)"
    }

    /// Emit optional stroke paint-style parameters.
    ///
    /// Omitting these fields preserves each terminal renderer's historical
    /// default for the primitive, while sending them gives apps deterministic
    /// cap/join behavior when artwork needs it.
    func strokeStyleParameters(lineCap: VTGLineCap? = nil, lineJoin: VTGLineJoin? = nil) -> String {
        var parameters = ""
        if let lineCap {
            parameters += ",lineCap=\(lineCap.rawValue)"
        }
        if let lineJoin {
            parameters += ",lineJoin=\(lineJoin.rawValue)"
        }
        return parameters
    }

    /// Emit an optional color parameter using the SDK's raw VTG color token.
    func colorParameter(_ name: String, _ color: VTGColor?) -> String {
        guard let color else {
            return ""
        }
        return ",\(name)=\(color.rawValue)"
    }

    /// Keep normalized protocol values inside their legal range.
    func clampedUnit(_ value: Double) -> Double {
        min(1, max(0, value))
    }

    /// Emit an optional normalized numeric parameter.
    func optionalUnitParameter(_ name: String, _ value: Double?) -> String {
        guard let value else {
            return ""
        }
        return ",\(name)=\(vtgNumber(clampedUnit(value)))"
    }

    /// Current prototype supports layer 0 plus four overlay layers.
    func isSupportedVTGLayer(_ layer: Int) -> Bool {
        VTGLayer.isSupported(layer)
    }
}

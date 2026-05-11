import Foundation

/// Return vector stroke definitions for one printable ASCII character.
///
/// Glyphs are encoded on a simple 5x7 grid. `vectorPrint(...)` scales these
/// points into pixel coordinates before emitting VTG `draw` commands.
func vectorGlyphStrokes(for ascii: Int) -> [[VTGPoint]] {
    let glyph = Character(UnicodeScalar(ascii >= 32 && ascii <= 126 ? ascii : 63)!).uppercased()
    switch glyph {
    case "A": return [p("0,7 0,2 2,0 4,2 4,7"), p("0,4 4,4")]
    case "B": return [p("0,0 0,7 3,7 4,6 4,4 3,3 0,3"), p("3,3 4,2 4,1 3,0 0,0")]
    case "C": return [p("4,1 3,0 1,0 0,1 0,6 1,7 3,7 4,6")]
    case "D": return [p("0,0 0,7 3,7 4,6 4,1 3,0 0,0")]
    case "E": return [p("4,0 0,0 0,7 4,7"), p("0,3 3,3")]
    case "F": return [p("0,7 0,0 4,0"), p("0,3 3,3")]
    case "G": return [p("4,1 3,0 1,0 0,1 0,6 1,7 4,7 4,4 2,4")]
    case "H": return [p("0,0 0,7"), p("4,0 4,7"), p("0,3 4,3")]
    case "I": return [p("0,0 4,0"), p("2,0 2,7"), p("0,7 4,7")]
    case "J": return [p("4,0 4,6 3,7 1,7 0,6")]
    case "K": return [p("0,0 0,7"), p("4,0 0,4 4,7")]
    case "L": return [p("0,0 0,7 4,7")]
    case "M": return [p("0,7 0,0 2,3 4,0 4,7")]
    case "N": return [p("0,7 0,0 4,7 4,0")]
    case "O": return [p("1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0")]
    case "P": return [p("0,7 0,0 3,0 4,1 4,3 3,4 0,4")]
    case "Q": return [p("1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0"), p("2,5 4,7")]
    case "R": return [p("0,7 0,0 3,0 4,1 4,3 3,4 0,4"), p("2,4 4,7")]
    case "S": return [p("4,1 3,0 1,0 0,1 0,3 4,4 4,6 3,7 1,7 0,6")]
    case "T": return [p("0,0 4,0"), p("2,0 2,7")]
    case "U": return [p("0,0 0,6 1,7 3,7 4,6 4,0")]
    case "V": return [p("0,0 2,7 4,0")]
    case "W": return [p("0,0 1,7 2,4 3,7 4,0")]
    case "X": return [p("0,0 4,7"), p("4,0 0,7")]
    case "Y": return [p("0,0 2,3 4,0"), p("2,3 2,7")]
    case "Z": return [p("0,0 4,0 0,7 4,7")]
    case "0": return [p("1,0 3,0 4,1 4,6 3,7 1,7 0,6 0,1 1,0"), p("1,6 3,1")]
    case "1": return [p("1,1 2,0 2,7"), p("0,7 4,7")]
    case "2": return [p("0,1 1,0 3,0 4,1 4,3 0,7 4,7")]
    case "3": return [p("0,0 4,0 2,3 4,4 4,6 3,7 1,7 0,6")]
    case "4": return [p("4,7 4,0 0,5 4,5")]
    case "5": return [p("4,0 0,0 0,3 3,3 4,4 4,6 3,7 1,7 0,6")]
    case "6": return [p("4,1 3,0 1,0 0,1 0,6 1,7 3,7 4,6 4,4 3,3 0,3")]
    case "7": return [p("0,0 4,0 1,7")]
    case "8": return [p("1,0 3,0 4,1 4,2 3,3 1,3 0,2 0,1 1,0"), p("1,3 3,3 4,4 4,6 3,7 1,7 0,6 0,4 1,3")]
    case "9": return [p("4,7 4,1 3,0 1,0 0,1 0,3 1,4 4,4")]
    case "-": return [p("0,3 4,3")]
    case ":": return [p("2,2 2,2"), p("2,5 2,5")]
    default: return [p("0,0 4,0 4,7 0,7 0,0")]
    }
}

/// Decode a compact `"x,y x,y"` stroke into SDK points.
private func p(_ encoded: String) -> [VTGPoint] {
    encoded.split(separator: " ").compactMap { pair in
        let values = pair.split(separator: ",", maxSplits: 1)
        guard values.count == 2,
              let x = Int(values[0]),
              let y = Int(values[1]) else {
            return nil
        }
        return VTGPoint(x: x, y: y)
    }
}

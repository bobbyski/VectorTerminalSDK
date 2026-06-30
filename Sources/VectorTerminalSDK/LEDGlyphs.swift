import Foundation

/// One filled segment in the SDK LED alphabet.
struct LEDGlyphSegment: Hashable {
    var name: String
    var points: [LEDPoint]
}

/// A normalized point in the LED glyph design grid.
struct LEDPoint: Hashable {
    var x: Double
    var y: Double
}

/// Original segmented LED alphabet used by `ledPrint(...)`.
///
/// Glyphs are designed on a 10x16 grid and rendered as filled VTG paths.
/// The shapes intentionally echo classic angular LED signage without copying
/// the supplied reference artwork.
enum LEDGlyphs {
    static let designWidth = 10.0
    static let designHeight = 16.0
    static let advance = 12.0

    static func segments(for ascii: Int) -> Set<String> {
        let glyph = Character(UnicodeScalar(ascii >= 32 && ascii <= 126 ? ascii : 63)!).uppercased()
        switch glyph {
        case "A": return s("abcefg")
        case "B": return s("cdefg")
        case "C": return s("adef")
        case "D": return s("bcdeg")
        case "E": return s("adefg")
        case "F": return s("aefg")
        case "G": return s("acdefg")
        case "H": return s("bcefg")
        case "I": return s("adhi")
        case "J": return s("bcde")
        case "K": return s("efkm")
        case "L": return s("def")
        case "M": return s("bcefjk")
        case "N": return s("bcefmj")
        case "O": return s("abcdef")
        case "P": return s("abefg")
        case "Q": return s("abcdefm")
        case "R": return s("abefgm")
        case "S": return s("acdfg")
        case "T": return s("ahi")
        case "U": return s("bcdef")
        case "V": return s("efkl")
        case "W": return s("efbclm")
        case "X": return s("jklm")
        case "Y": return s("jki")
        case "Z": return s("adkl")
        case "0": return s("abcdef")
        case "1": return s("bc")
        case "2": return s("abdeg")
        case "3": return s("abcdg")
        case "4": return s("bcfg")
        case "5": return s("acdfg")
        case "6": return s("acdefg")
        case "7": return s("abc")
        case "8": return s("abcdefg")
        case "9": return s("abcdfg")
        case "-": return s("g")
        case "_": return s("d")
        case "=": return s("dg")
        case ".": return s("o")
        case ":": return s("no")
        case "!": return s("ho")
        case "?": return s("abko")
        case "/": return s("kl")
        case "\\": return s("jm")
        default: return s("adfg")
        }
    }

    static let allSegments: [LEDGlyphSegment] = [
        segment("a", "2,0 8,0 9,1 8,2 2,2 1,1"),
        segment("b", "8,2 9,1 10,2 10,7 9,8 8,7"),
        segment("c", "8,9 9,8 10,9 10,14 9,15 8,14"),
        segment("d", "2,14 8,14 9,15 8,16 2,16 1,15"),
        segment("e", "0,9 1,8 2,9 2,14 1,15 0,14"),
        segment("f", "0,2 1,1 2,2 2,7 1,8 0,7"),
        segment("g", "2,7 8,7 9,8 8,9 2,9 1,8"),
        segment("h", "4.25,2 5.75,2 6.15,3 6.15,7 5,8 3.85,7 3.85,3"),
        segment("i", "3.85,9 5,8 6.15,9 6.15,13 5.75,14 4.25,14 3.85,13"),
        segment("j", "2,2 3.25,2 5,6.35 5,8 3.95,8 2,3.2"),
        segment("k", "6.75,2 8,2 8,3.2 6.05,8 5,8 5,6.35"),
        segment("l", "2,13.8 2,12.6 3.95,8 5,8 5,9.65 3.25,14"),
        segment("m", "8,13.8 6.75,14 5,9.65 5,8 6.05,8 8,12.6"),
        segment("n", "4.15,4.8 5.85,4.8 6.25,5.2 6.25,6.8 5.85,7.2 4.15,7.2 3.75,6.8 3.75,5.2"),
        segment("o", "4.15,10.8 5.85,10.8 6.25,11.2 6.25,12.8 5.85,13.2 4.15,13.2 3.75,12.8 3.75,11.2")
    ]

    private static func s(_ encoded: String) -> Set<String> {
        Set(encoded.map(String.init))
    }

    private static func segment(_ name: String, _ encoded: String) -> LEDGlyphSegment {
        LEDGlyphSegment(
            name: name,
            points: encoded.split(separator: " ").compactMap { pair in
                let values = pair.split(separator: ",", maxSplits: 1)
                guard values.count == 2,
                      let x = Double(values[0]),
                      let y = Double(values[1]) else {
                    return nil
                }
                return LEDPoint(x: x, y: y)
            }
        )
    }
}

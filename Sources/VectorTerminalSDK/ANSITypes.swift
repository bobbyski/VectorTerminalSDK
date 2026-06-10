import Foundation

/// Standard eight ANSI color slots used by SGR text helpers.
public enum ANSIColor: Int {
    /// ANSI black color slot.
    case black = 0

    /// ANSI red color slot.
    case red = 1

    /// ANSI green color slot.
    case green = 2

    /// ANSI yellow color slot.
    case yellow = 3

    /// ANSI blue color slot.
    case blue = 4

    /// ANSI magenta color slot.
    case magenta = 5

    /// ANSI cyan color slot.
    case cyan = 6

    /// ANSI white color slot.
    case white = 7
}

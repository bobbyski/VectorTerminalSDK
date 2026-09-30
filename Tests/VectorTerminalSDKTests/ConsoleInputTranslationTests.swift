import Testing
@testable import VectorTerminalSDK

/// A Windows console that does not honour VT input mode (Wine's, older
/// consoles) reports keys and the mouse as records; these must come out as the
/// bytes a pty sends, or TUIKit's parser never sees them.
struct ConsoleInputTranslationTests {
    private func key(_ virtualKey: UInt16, shift: Bool = false, alt: Bool = false, ctrl: Bool = false) -> String? {
        ConsoleInputTranslation.keySequence(virtualKey: virtualKey, shift: shift, alt: alt, ctrl: ctrl)
            .map { String(decoding: $0, as: UTF8.self) }
    }

    private func mouse(column: Int = 34, row: Int = 6, buttons: UInt32, previous: UInt32 = 0,
                       moved: Bool = false, wheel: Int? = nil, ctrl: Bool = false) -> String? {
        ConsoleInputTranslation.mouseSequence(
            column: column, row: row, buttons: buttons, previous: previous,
            moved: moved, wheel: wheel, shift: false, alt: false, ctrl: ctrl
        ).map { String(decoding: $0, as: UTF8.self) }
    }

    @Test func arrowsAndEditingKeysAreXtermSequences() {
        #expect(key(0x26) == "\u{1B}[A")
        #expect(key(0x28) == "\u{1B}[B")
        #expect(key(0x27) == "\u{1B}[C")
        #expect(key(0x25) == "\u{1B}[D")
        #expect(key(0x24) == "\u{1B}[H")
        #expect(key(0x23) == "\u{1B}[F")
        #expect(key(0x2E) == "\u{1B}[3~")
        #expect(key(0x21) == "\u{1B}[5~")
        #expect(key(0x22) == "\u{1B}[6~")
    }

    @Test func modifiersTakeXtermsParameter() {
        #expect(key(0x26, shift: true) == "\u{1B}[1;2A")
        #expect(key(0x25, ctrl: true) == "\u{1B}[1;5D")
        #expect(key(0x2E, alt: true) == "\u{1B}[3;3~")
        #expect(key(0x70, ctrl: true) == "\u{1B}[1;5P")
    }

    @Test func functionKeys() {
        #expect(key(0x70) == "\u{1B}OP")
        #expect(key(0x73) == "\u{1B}OS")
        #expect(key(0x74) == "\u{1B}[15~")
        #expect(key(0x7B) == "\u{1B}[24~")
    }

    @Test func keysATerminalDoesNotReportAreNil() {
        #expect(key(0x10) == nil)   // VK_SHIFT alone
        #expect(key(0x5B) == nil)   // VK_LWIN
    }

    @Test func aClickIsAnSGRPressThenRelease() {
        // The cell is 0-based in the window; SGR reports are 1-based.
        #expect(mouse(buttons: 0x1) == "\u{1B}[<0;35;7M")
        #expect(mouse(buttons: 0, previous: 0x1) == "\u{1B}[<0;35;7m")
        #expect(mouse(buttons: 0x2) == "\u{1B}[<2;35;7M")
        #expect(mouse(buttons: 0x4) == "\u{1B}[<1;35;7M")
    }

    @Test func dragsAreReportedAndBareMovementIsNot() {
        #expect(mouse(column: 40, buttons: 0x1, previous: 0x1, moved: true) == "\u{1B}[<32;41;7M")
        #expect(mouse(buttons: 0, moved: true) == nil)
    }

    @Test func theWheelAndModifiers() {
        #expect(mouse(buttons: 0, wheel: 1) == "\u{1B}[<64;35;7M")
        #expect(mouse(buttons: 0, wheel: -1) == "\u{1B}[<65;35;7M")
        #expect(mouse(buttons: 0x1, ctrl: true) == "\u{1B}[<16;35;7M")
    }

    @Test func aRecordThatChangesNoButtonIsNotReported() {
        #expect(mouse(buttons: 0x1, previous: 0x1) == nil)
    }
}

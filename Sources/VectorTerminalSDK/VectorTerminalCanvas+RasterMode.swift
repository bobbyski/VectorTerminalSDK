import Foundation

/// Raster mode — the way vintage machines drew.
///
/// ```text
///   retained (default)              raster mode
///   ─────────────────────────       ─────────────────────────
///   overlay layers 1…4              one plane, shared with the text
///   objects kept by id              pixels, kept by nobody
///   delete(id:) removes one         only a screen clear erases
///   scrolls independently           scrolls with the text
/// ```
///
/// **A compatibility mode, and the lesser one.** A simulated 8-bit machine has
/// one framebuffer: a plotted point is not an object, it is a lit pixel that the
/// text can overwrite and that scrolls away with the line it sits on. VTG's
/// retained scene cannot express that — a retained circle survives a scroll and
/// waits to be deleted by id — so a simulator drawing into it produces graphics
/// that float above the text they were meant to be part of.
///
/// **Nothing else about the protocol changes.** The same drawing commands are
/// sent, with the same parameters, ids included; the terminal simply paints them
/// into the text plane and forgets them. That is what makes this usable from an
/// existing program: turn it on, draw as before, turn it off.
///
/// **What the plain mode really does (WINDOW_PLAN.md, Findings A and B).** Plain
/// `enterRasterMode()` gives each drawing a fresh id and draws it on layer 0,
/// which terminals draw *over* the text, and keeps it until a clear. So text
/// written later does not hide the drawing, and a program that plots every frame
/// builds an ever-longer list. That behavior is kept exactly, for programs that
/// rely on it. `enterRasterMode(textErases: true)` asks for the framebuffer the
/// diagram above describes: text written over a drawing erases it cell by cell,
/// drawing scrolls with the text, and nothing is retained. Check
/// ``VTGCapabilities/rasterTextErases`` first.
///
/// What an application gives up while it is on:
///
/// - `delete(id:)` has nothing to delete, and redrawing an id paints again
///   rather than replacing. Erase by clearing the screen and redrawing.
/// - Layers, viewports, sprite transforms and hit regions have no retained
///   object to act on.
/// - Anything scrolled off the top is gone, as it is on the machine being
///   simulated.
///
/// Switching either way clears the retained scene, so nothing is left on screen
/// that can no longer be addressed.
extension VectorTerminalCanvas {
    /// Turn raster mode on: drawing paints into the text plane and is not retained.
    ///
    /// - Parameter textErases: Ask for real framebuffer behavior: text written
    ///   over a drawing erases it, cell by cell, and drawing scrolls with the
    ///   text. Sends `text=erases`; check ``VTGCapabilities/rasterTextErases``
    ///   first, since an older terminal ignores the option and keeps drawing
    ///   above the text. Defaults to false, which is raster mode as it was.
    public func enterRasterMode(textErases: Bool = false) {
        setRasterMode(true, textErases: textErases)
    }

    /// Turn raster mode off and return to the retained scene.
    public func leaveRasterMode() {
        setRasterMode(false)
    }

    /// Set raster mode directly, for code that carries the flag in a variable.
    ///
    /// Sends `rasterMode,enabled=1` or `0` and forgets tracked ids. Asking for
    /// the mode the canvas is already in sends nothing.
    ///
    /// - Parameters:
    ///   - enabled: True to turn raster mode on, false to turn it off.
    ///   - textErases: With `enabled`, ask that text erase the drawing under it
    ///     (`text=erases`). Ignored when turning raster mode off.
    public func setRasterMode(_ enabled: Bool, textErases: Bool = false) {
        guard enabled != isRasterMode else {
            return
        }
        isRasterMode = enabled
        send("rasterMode,enabled=\(enabled ? 1 : 0)" + (enabled && textErases ? ",text=erases" : ""))
        // The terminal clears its scene on the switch; the ids this canvas is
        // still tracking refer to objects that no longer exist either way.
        retainedStringObjectIDs.removeAll()
    }

    /// Whether raster mode is on, as far as this canvas has been told.
    public var isInRasterMode: Bool { isRasterMode }
}

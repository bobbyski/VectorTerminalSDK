import Foundation

/// VTG Page Mode.
///
/// A page is an off-screen document with its own size, background, layers, and
/// scroll position, floating above the terminal. Open one, draw into it with
/// the ordinary drawing calls while nobody can see it, then show it:
///
/// ```swift
/// try canvas.withPageMode(id: "doc") {
///     canvas.openPage(id: "p1", background: "#101018", height: .growable)
///     canvas.rect(id: "box", x: 20, y: 20, width: 200, height: 120, stroke: .cyan)
///     canvas.showPage()
///     // … event loop …
/// }
/// ```
///
/// Two buffers: a page opened while another is visible lands in the other
/// one, so one page can be on screen while the next is built. Check
/// ``VTGCapabilities/supportsPageMode`` first. Page events arrive through
/// ``pageEventHandler``.
extension VectorTerminalCanvas {
    // MARK: - Session

    /// Enter page mode. Nothing is drawn differently until ``openPage(id:background:width:height:maxWidth:maxHeight:padding:resize:)``.
    ///
    /// Sends `pageBegin,version=1,id=<id>,over=<all|text>`. An invalid id drops
    /// the command. The terminal rejects a nested `pageBegin`.
    ///
    /// - Parameters:
    ///   - id: The session id, echoed in every page event; defaults to `vpm`.
    ///   - stacking: Where the visible page composites; defaults to `.all`.
    public func beginPageMode(id: String = "vpm", stacking: VTGPageStacking = .all) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("pageBegin,version=1,id=\(id),over=\(stacking.rawValue)")
    }

    /// Leave page mode; both pages are freed and the terminal is uncovered.
    public func endPageMode() {
        send("pageEnd")
    }

    /// Run `body` in page mode, ending it however `body` exits.
    ///
    /// Calls ``beginPageMode(id:stacking:)``, runs `body`, then always calls
    /// ``endPageMode()``, even when `body` throws.
    ///
    /// - Parameters:
    ///   - id: The session id; defaults to `vpm`.
    ///   - stacking: Where the visible page composites; defaults to `.all`.
    ///   - body: The work to do in page mode.
    /// - Returns: Whatever `body` returns.
    public func withPageMode<T>(
        id: String = "vpm",
        stacking: VTGPageStacking = .all,
        _ body: () throws -> T
    ) rethrows -> T {
        beginPageMode(id: id, stacking: stacking)
        defer { endPageMode() }
        return try body()
    }

    /// Send drawing to the current page, or back to the ordinary scene
    /// without leaving page mode.
    ///
    /// Sends `pageTarget,scene=<page|base>`.
    ///
    /// - Parameter target: `.page` for the current page, `.base` for the
    ///   ordinary scene.
    public func setDrawTarget(_ target: VTGPageDrawTarget) {
        send("pageTarget,scene=\(target.rawValue)")
    }

    // MARK: - Pages

    /// Open a page off screen and make it the draw target.
    ///
    /// Sends `pageOpen,id=,bg=,…,grow=`. The page goes in the buffer slot
    /// that is not visible, replacing whatever page was there. An invalid id
    /// drops the command.
    ///
    /// - Parameters:
    ///   - id: The page id.
    ///   - background: The page color; `nil` or `.transparent` lets the
    ///     terminal show through.
    ///   - width: Defaults to the window, fixed.
    ///   - height: Defaults to growable: the page extends to fit.
    ///   - maxWidth: Growth limit for the width, in pixels; `nil` or a value
    ///     that is not positive uses the terminal's limit.
    ///   - maxHeight: Growth limit for the height, in pixels; `nil` or a value
    ///     that is not positive uses the terminal's limit.
    ///   - padding: Extra pixels added past drawn content when a growable axis
    ///     grows; `nil` or a value that is not positive means none.
    ///   - resize: What the page does when the window resizes; `nil` lets the
    ///     terminal use `.auto`.
    public func openPage(
        id: String,
        background: VTGColor? = nil,
        width: VTGPageExtent = .window,
        height: VTGPageExtent = .growable,
        maxWidth: Int? = nil,
        maxHeight: Int? = nil,
        padding: Int? = nil,
        resize: VTGPageResizePolicy? = nil
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        var command = "pageOpen,id=\(id),bg=\(background?.rawValue ?? "none")"
        command += extentParameter(width, pixelKey: "w", cellKey: "cols")
        command += extentParameter(height, pixelKey: "h", cellKey: "rows")
        switch (width, height) {
        case (.growable, .growable): command += ",grow=wh"
        case (.growable, _): command += ",grow=w"
        case (_, .growable): command += ",grow=h"
        default: command += ",grow=none"
        }
        if let maxWidth, maxWidth > 0 { command += ",maxW=\(maxWidth)" }
        if let maxHeight, maxHeight > 0 { command += ",maxH=\(maxHeight)" }
        if let padding, padding > 0 { command += ",padding=\(padding)" }
        if let resize { command += ",resize=\(resize.rawValue)" }
        send(command)
    }

    /// Display the draw target, or the named page. `select` also makes the
    /// named page the draw target.
    ///
    /// Sends `pageShow[,id=][,select=1]`.
    ///
    /// - Parameters:
    ///   - id: The page to show; `nil` shows the draw target. An invalid id is
    ///     silently dropped, so the draw target is shown instead.
    ///   - select: Also make the shown page the draw target; defaults to `false`.
    public func showPage(id: String? = nil, select: Bool = false) {
        send("pageShow\(pageParameter("id", id))\(select ? ",select=1" : "")")
    }

    /// Hide the visible page. Page mode stays active and the page keeps its
    /// content.
    public func hidePage() {
        send("pageHide")
    }

    /// Draw into a page without changing what is displayed.
    ///
    /// Sends `pageSelect,id=<id>`. An invalid id drops the command.
    ///
    /// - Parameter id: The page to make the draw target.
    public func selectPage(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("pageSelect,id=\(id)")
    }

    /// Free a page's buffer, hiding it first if it is visible.
    ///
    /// Sends `pageClose,id=<id>`. An invalid id drops the command.
    ///
    /// - Parameter id: The page to close.
    public func closePage(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("pageClose,id=\(id)")
    }

    /// Erase a page's content (or one layer's). `removeLayers` drops the
    /// layers themselves as well.
    ///
    /// Sends `pageClear[,id=][,layer=][,layers=1]`.
    ///
    /// - Parameters:
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    ///   - layer: Erase only this layer; `nil` (or an invalid id, silently
    ///     dropped) erases the whole page.
    ///   - removeLayers: Also remove the layers; defaults to `false`.
    public func clearPage(id: String? = nil, layer: String? = nil, removeLayers: Bool = false) {
        send("pageClear\(pageParameter("id", id))\(pageParameter("layer", layer))\(removeLayers ? ",layers=1" : "")")
    }

    /// Set a page's extent explicitly. The only way a page shrinks.
    ///
    /// Sends `pageResize[,id=][,w=][,h=]`. Content outside the new extent is
    /// clipped, not deleted.
    ///
    /// - Parameters:
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    ///   - width: The new width, in pixels; `nil` keeps the current width.
    ///   - height: The new height, in pixels; `nil` keeps the current height.
    public func resizePage(id: String? = nil, width: Int? = nil, height: Int? = nil) {
        var command = "pageResize\(pageParameter("id", id))"
        if let width { command += ",w=\(width)" }
        if let height { command += ",h=\(height)" }
        send(command)
    }

    /// Change a page's background color.
    ///
    /// Sends `pageBackground[,id=],bg=<color|none>`.
    ///
    /// - Parameters:
    ///   - background: The new color; `nil` makes the page transparent.
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageBackground(_ background: VTGColor?, id: String? = nil) {
        send("pageBackground\(pageParameter("id", id)),bg=\(background?.rawValue ?? "none")")
    }

    /// Fade a whole page, background included.
    ///
    /// Sends `pageAlpha[,id=],alpha=<0-1>`.
    ///
    /// - Parameters:
    ///   - alpha: Page opacity, clamped to `0...1`.
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageAlpha(_ alpha: Double, id: String? = nil) {
        send("pageAlpha\(pageParameter("id", id)),alpha=\(vtgNumber(clampedUnit(alpha)))")
    }

    /// Place the page's visible window in a rectangle of the canvas instead
    /// of filling it.
    ///
    /// Sends `pageViewport[,id=],x=,y=,w=,h=`.
    ///
    /// - Parameters:
    ///   - x: Left edge of the viewport on the canvas, in pixels.
    ///   - y: Top edge of the viewport on the canvas, in pixels.
    ///   - width: Viewport width, in pixels.
    ///   - height: Viewport height, in pixels.
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageViewport(x: Int, y: Int, width: Int, height: Int, id: String? = nil) {
        send("pageViewport\(pageParameter("id", id)),x=\(x),y=\(y),w=\(width),h=\(height)")
    }

    /// Let the page fill the canvas again.
    ///
    /// Sends `pageViewport[,id=],value=full`.
    ///
    /// - Parameter id: The page; `nil` (or an invalid id, silently dropped)
    ///   means the draw target.
    public func resetPageViewport(id: String? = nil) {
        send("pageViewport\(pageParameter("id", id)),value=full")
    }

    // MARK: - Scrolling

    /// Set a page's scroll origin.
    ///
    /// Sends `pageScroll[,id=][,x=][,y=]`. The terminal clamps the origin to
    /// the page extent.
    ///
    /// - Parameters:
    ///   - x: Horizontal origin, in page pixels; `nil` leaves it unchanged.
    ///   - y: Vertical origin, in page pixels; `nil` leaves it unchanged.
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func scrollPage(toX x: Int? = nil, y: Int? = nil, id: String? = nil) {
        var command = "pageScroll\(pageParameter("id", id))"
        if let x { command += ",x=\(x)" }
        if let y { command += ",y=\(y)" }
        send(command)
    }

    /// Scroll a page by a relative amount.
    ///
    /// Sends `pageScrollBy[,id=],dx=,dy=`.
    ///
    /// - Parameters:
    ///   - dx: Horizontal change, in page pixels; defaults to 0.
    ///   - dy: Vertical change, in page pixels; defaults to 0.
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func scrollPage(byX dx: Int = 0, y dy: Int = 0, id: String? = nil) {
        send("pageScrollBy\(pageParameter("id", id)),dx=\(dx),dy=\(dy)")
    }

    /// Scroll a page to one of its edges.
    ///
    /// Sends `pageScrollTo[,id=],anchor=<top|bottom|left|right>`. Only the
    /// axis that edge belongs to changes.
    ///
    /// - Parameters:
    ///   - edge: The edge to scroll to.
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func scrollPage(to edge: VTGPageEdge, id: String? = nil) {
        send("pageScrollTo\(pageParameter("id", id)),anchor=\(edge.rawValue)")
    }

    /// Let the user's wheel or trackpad scroll the visible page. While on,
    /// those gestures reach the app as `pageScrolled` events instead of mouse
    /// scroll events.
    ///
    /// Sends `pageScrollMode,user=<0|1>,axis=<both|x|y>`.
    ///
    /// - Parameters:
    ///   - enabled: `true` lets the user scroll the page.
    ///   - axis: Which axes the user may scroll; defaults to `.both`.
    public func setPageUserScrolling(_ enabled: Bool, axis: VTGPageScrollAxis = .both) {
        send("pageScrollMode,user=\(enabled ? 1 : 0),axis=\(axis.rawValue)")
    }

    // MARK: - Layers

    /// Create or reconfigure a named page layer. Any drawing call's `layer:`
    /// also creates a page layer named for that number, at that z.
    ///
    /// Sends `pageLayerAdd,id=[,page=]` plus only the settings given; `nil`
    /// leaves a setting unchanged (or at its default for a new layer). An
    /// invalid id drops the command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - z: Stacking order; a new layer defaults to creation order.
    ///   - alpha: Layer opacity, clamped to `0...1`; defaults to 1.
    ///   - visible: Whether the layer is drawn; defaults to `true`.
    ///   - x: Horizontal offset in page space, in pixels; defaults to 0.
    ///   - y: Vertical offset in page space, in pixels; defaults to 0.
    ///   - scroll: Whether the layer scrolls with the page; defaults to `.page`.
    ///   - cache: Ask the renderer to rasterize once and reuse; defaults to `false`.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func addPageLayer(
        id: String,
        z: Double? = nil,
        alpha: Double? = nil,
        visible: Bool? = nil,
        x: Int? = nil,
        y: Int? = nil,
        scroll: VTGPageLayerScrollMode? = nil,
        cache: Bool? = nil,
        page: String? = nil
    ) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        var command = "pageLayerAdd,id=\(id)\(pageParameter("page", page))"
        if let z { command += ",z=\(vtgNumber(z))" }
        if let alpha { command += ",alpha=\(vtgNumber(clampedUnit(alpha)))" }
        if let visible { command += ",visible=\(visible ? 1 : 0)" }
        if let x { command += ",x=\(x)" }
        if let y { command += ",y=\(y)" }
        if let scroll { command += ",scroll=\(scroll.rawValue)" }
        if let cache { command += ",cache=\(cache ? 1 : 0)" }
        send(command)
    }

    /// The page layer drawing calls without `layer:` go to.
    ///
    /// Sends `pageLayerSelect,id=[,page=]`. Before any select the default
    /// layer is `"1"`. An invalid id drops the command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func selectPageLayer(_ id: String, page: String? = nil) {
        pageLayerCommand("pageLayerSelect", id, page)
    }

    /// Remove a layer's content, keeping the layer and its settings.
    ///
    /// Sends `pageLayerClear,id=[,page=]`. An invalid id drops the command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func clearPageLayer(_ id: String, page: String? = nil) {
        pageLayerCommand("pageLayerClear", id, page)
    }

    /// Remove a page layer and its content.
    ///
    /// Sends `pageLayerRemove,id=[,page=]`. An invalid id drops the command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func removePageLayer(_ id: String, page: String? = nil) {
        pageLayerCommand("pageLayerRemove", id, page)
    }

    /// Restack a page layer.
    ///
    /// Sends `pageLayerOrder,id=[,page=],z=`. An invalid id drops the command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - z: The new stacking order; higher draws on top.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageLayerOrder(_ id: String, z: Double, page: String? = nil) {
        pageLayerCommand("pageLayerOrder", id, page, ",z=\(vtgNumber(z))")
    }

    /// Fade one page layer.
    ///
    /// Sends `pageLayerAlpha,id=[,page=],alpha=`. An invalid id drops the
    /// command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - alpha: Layer opacity, clamped to `0...1`.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageLayerAlpha(_ id: String, alpha: Double, page: String? = nil) {
        pageLayerCommand("pageLayerAlpha", id, page, ",alpha=\(vtgNumber(clampedUnit(alpha)))")
    }

    /// Show or hide one page layer.
    ///
    /// Sends `pageLayerVisible,id=[,page=],visible=<0|1>`. An invalid id drops
    /// the command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - visible: `true` shows the layer; `false` hides it.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageLayerVisible(_ id: String, _ visible: Bool, page: String? = nil) {
        pageLayerCommand("pageLayerVisible", id, page, ",visible=\(visible ? 1 : 0)")
    }

    /// Move a layer within the page — parallax without redrawing it.
    ///
    /// Sends `pageLayerOffset,id=[,page=],x=,y=`. An invalid id drops the
    /// command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - x: Horizontal offset in page space, in pixels.
    ///   - y: Vertical offset in page space, in pixels.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageLayerOffset(_ id: String, x: Int, y: Int, page: String? = nil) {
        pageLayerCommand("pageLayerOffset", id, page, ",x=\(x),y=\(y)")
    }

    /// Hint whether the renderer may rasterize a layer once and reuse it.
    ///
    /// Sends `pageLayerCache,id=[,page=],cache=<0|1>`. An invalid id drops the
    /// command.
    ///
    /// - Parameters:
    ///   - id: The layer id.
    ///   - cache: `true` asks the renderer to cache the layer.
    ///   - page: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    public func setPageLayerCache(_ id: String, _ cache: Bool, page: String? = nil) {
        pageLayerCommand("pageLayerCache", id, page, ",cache=\(cache ? 1 : 0)")
    }

    /// Bring a layer in from another page. By reference it is shared and
    /// read-only here — a background drawn once and reused by every frame.
    ///
    /// Sends `pageLayerCopy,id=[,page=],from=,mode=[,layer=][,z=]`. An invalid
    /// `id` or `sourcePage` drops the command.
    ///
    /// - Parameters:
    ///   - id: The id of the new layer in this page.
    ///   - sourcePage: The page that owns the layer.
    ///   - sourceLayer: The layer to bring in; `nil` (or an invalid id,
    ///     silently dropped) means the source layer with the same id as `id`.
    ///   - mode: `.reference` shares the content read-only; `.copy` takes an
    ///     editable snapshot. Defaults to `.reference`.
    ///   - z: Stacking order; `nil` keeps the source layer's z.
    ///   - page: The page receiving the layer; `nil` (or an invalid id,
    ///     silently dropped) means the draw target.
    public func copyPageLayer(
        _ id: String,
        from sourcePage: String,
        layer sourceLayer: String? = nil,
        mode: VTGPageLayerCopyMode = .reference,
        z: Double? = nil,
        page: String? = nil
    ) {
        guard isValidVTGIdentifier(sourcePage) else {
            return
        }
        var extra = ",from=\(sourcePage),mode=\(mode.rawValue)\(pageParameter("layer", sourceLayer))"
        if let z { extra += ",z=\(vtgNumber(z))" }
        pageLayerCommand("pageLayerCopy", id, page, extra)
    }

    // MARK: - Queries

    /// The real terminal canvas. While a page is open, ``queryCanvas(timeoutMilliseconds:)``
    /// reports the page's viewport instead.
    ///
    /// Sends `windowCanvas?` and waits for the `windowCanvas` answer. Page
    /// events read on the way go to ``pageEventHandler``.
    ///
    /// - Parameter timeoutMilliseconds: How long to wait for the answer;
    ///   defaults to 750.
    /// - Returns: The window canvas size, or `nil` if output is disabled, the
    ///   query timed out, or the answer could not be parsed.
    public func queryWindowCanvas(timeoutMilliseconds: Int = 750) -> VTGCanvas? {
        guard let response = queryNamed("windowCanvas?", responseName: "windowCanvas", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseWidthHeight(from: response, source: "windowCanvas?")
    }

    /// A page's size, scroll position, and layers.
    ///
    /// Sends `pageState?[,id=]` and waits for the `pageState` answer. Page
    /// events read on the way go to ``pageEventHandler``.
    ///
    /// - Parameters:
    ///   - id: The page; `nil` (or an invalid id, silently dropped) means the
    ///     draw target.
    ///   - timeoutMilliseconds: How long to wait for the answer; defaults to 750.
    /// - Returns: The page state, or `nil` if output is disabled, the query
    ///   timed out, or the answer lacked `id`, `w`, or `h`.
    public func queryPageState(id: String? = nil, timeoutMilliseconds: Int = 750) -> VTGPageState? {
        guard let response = queryNamed("pageState?\(pageParameter("id", id))", responseName: "pageState", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        let values = vtgFields(from: response)
        guard let pageID = values["id"],
              let width = values["w"].flatMap(Double.init),
              let height = values["h"].flatMap(Double.init) else {
            return nil
        }
        return VTGPageState(
            id: pageID,
            slot: values["slot"] ?? "",
            width: width,
            height: height,
            growsWidth: values["growW"] == "1",
            growsHeight: values["growH"] == "1",
            scrollX: values["scrollX"].flatMap(Double.init) ?? 0,
            scrollY: values["scrollY"].flatMap(Double.init) ?? 0,
            alpha: values["alpha"].flatMap(Double.init) ?? 1,
            background: values["bg"] ?? "none",
            isVisible: values["visible"] == "1",
            layers: values["layers"].map { $0.split(separator: "|").map(String.init) } ?? [],
            rawResponse: response
        )
    }

    /// Whether page mode is active, and which pages are drawn into and shown.
    ///
    /// Sends `page?` and waits for the `page` answer. Page events read on the
    /// way go to ``pageEventHandler``.
    ///
    /// - Parameter timeoutMilliseconds: How long to wait for the answer;
    ///   defaults to 750.
    /// - Returns: An event named `page` whose fields include `active`,
    ///   `session`, `target`, and `visible`, or `nil` if output is disabled or
    ///   the query timed out.
    public func queryPageMode(timeoutMilliseconds: Int = 750) -> VTGPageEvent? {
        guard let response = queryNamed("page?", responseName: "page", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return VTGPageEvent(name: "page", fields: vtgFields(from: response), rawResponse: response)
    }

    // MARK: - Helpers

    /// Send a query and wait for the response with this name.
    ///
    /// Page mode sends asynchronous events (`pageGrew`, `pageScrolled`) that
    /// can arrive ahead of an answer, so unlike the older single-response
    /// queries this skips to the named one and passes page events it meets on
    /// to ``pageEventHandler``.
    func queryNamed(
        _ command: String,
        payload: String? = nil,
        responseName: String,
        timeoutMilliseconds: Int
    ) -> String? {
        guard isEnabled else {
            return nil
        }
        let original = enableRawMode()
        defer { restoreMode(original) }
        send(command, payload: payload)
        let deadline = Date().addingTimeInterval(Double(timeoutMilliseconds) / 1000)
        while Date() < deadline {
            let remaining = max(1, Int(deadline.timeIntervalSinceNow * 1000))
            guard let bytes = readAPCResponse(timeoutMilliseconds: remaining, limit: 262_144),
                  let response = String(bytes: bytes, encoding: .utf8) else {
                return nil
            }
            guard let name = vtgResponseName(response) else {
                continue
            }
            if name == responseName {
                return response
            }
            if VTGPageEvent.isPageEventName(name) {
                pageEventHandler?(VTGPageEvent(name: name, fields: vtgFields(from: response), rawResponse: response))
            } else if !dispatchCommandRejected(name, response: response) {
                _ = dispatchKeyEvent(name, response: response)
            }
        }
        return nil
    }

    private func extentParameter(_ extent: VTGPageExtent, pixelKey: String, cellKey: String) -> String {
        switch extent {
        case .window:
            return ""
        case .growable:
            return ",\(pixelKey)=-1"
        case .pixels(let value):
            return value > 0 ? ",\(pixelKey)=\(value)" : ""
        case .cells(let value):
            return value > 0 ? ",\(cellKey)=\(value)" : ""
        }
    }

    /// `,key=value` for a valid id, nothing otherwise.
    func pageParameter(_ key: String, _ value: String?) -> String {
        guard let value, isValidVTGIdentifier(value) else {
            return ""
        }
        return ",\(key)=\(value)"
    }

    private func pageLayerCommand(_ name: String, _ id: String, _ page: String?, _ extra: String = "") {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("\(name),id=\(id)\(pageParameter("page", page))\(extra)")
    }
}

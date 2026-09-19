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
    public func setDrawTarget(_ target: VTGPageDrawTarget) {
        send("pageTarget,scene=\(target.rawValue)")
    }

    // MARK: - Pages

    /// Open a page off screen and make it the draw target.
    ///
    /// - Parameters:
    ///   - background: The page color; `nil` or `.transparent` lets the
    ///     terminal show through.
    ///   - width: Defaults to the window, fixed.
    ///   - height: Defaults to growable: the page extends to fit.
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
    public func showPage(id: String? = nil, select: Bool = false) {
        send("pageShow\(pageParameter("id", id))\(select ? ",select=1" : "")")
    }

    /// Hide the visible page. Page mode stays active and the page keeps its
    /// content.
    public func hidePage() {
        send("pageHide")
    }

    /// Draw into a page without changing what is displayed.
    public func selectPage(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("pageSelect,id=\(id)")
    }

    public func closePage(id: String) {
        guard isValidVTGIdentifier(id) else {
            return
        }
        send("pageClose,id=\(id)")
    }

    /// Erase a page's content (or one layer's). `removeLayers` drops the
    /// layers themselves as well.
    public func clearPage(id: String? = nil, layer: String? = nil, removeLayers: Bool = false) {
        send("pageClear\(pageParameter("id", id))\(pageParameter("layer", layer))\(removeLayers ? ",layers=1" : "")")
    }

    /// Set a page's extent explicitly. The only way a page shrinks.
    public func resizePage(id: String? = nil, width: Int? = nil, height: Int? = nil) {
        var command = "pageResize\(pageParameter("id", id))"
        if let width { command += ",w=\(width)" }
        if let height { command += ",h=\(height)" }
        send(command)
    }

    public func setPageBackground(_ background: VTGColor?, id: String? = nil) {
        send("pageBackground\(pageParameter("id", id)),bg=\(background?.rawValue ?? "none")")
    }

    public func setPageAlpha(_ alpha: Double, id: String? = nil) {
        send("pageAlpha\(pageParameter("id", id)),alpha=\(vtgNumber(clampedUnit(alpha)))")
    }

    /// Place the page's visible window in a rectangle of the canvas instead
    /// of filling it.
    public func setPageViewport(x: Int, y: Int, width: Int, height: Int, id: String? = nil) {
        send("pageViewport\(pageParameter("id", id)),x=\(x),y=\(y),w=\(width),h=\(height)")
    }

    /// Let the page fill the canvas again.
    public func resetPageViewport(id: String? = nil) {
        send("pageViewport\(pageParameter("id", id)),value=full")
    }

    // MARK: - Scrolling

    public func scrollPage(toX x: Int? = nil, y: Int? = nil, id: String? = nil) {
        var command = "pageScroll\(pageParameter("id", id))"
        if let x { command += ",x=\(x)" }
        if let y { command += ",y=\(y)" }
        send(command)
    }

    public func scrollPage(byX dx: Int = 0, y dy: Int = 0, id: String? = nil) {
        send("pageScrollBy\(pageParameter("id", id)),dx=\(dx),dy=\(dy)")
    }

    public func scrollPage(to edge: VTGPageEdge, id: String? = nil) {
        send("pageScrollTo\(pageParameter("id", id)),anchor=\(edge.rawValue)")
    }

    /// Let the user's wheel or trackpad scroll the visible page. While on,
    /// those gestures reach the app as `pageScrolled` events instead of mouse
    /// scroll events.
    public func setPageUserScrolling(_ enabled: Bool, axis: VTGPageScrollAxis = .both) {
        send("pageScrollMode,user=\(enabled ? 1 : 0),axis=\(axis.rawValue)")
    }

    // MARK: - Layers

    /// Create or reconfigure a named page layer. Any drawing call's `layer:`
    /// also creates a page layer named for that number, at that z.
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
    public func selectPageLayer(_ id: String, page: String? = nil) {
        pageLayerCommand("pageLayerSelect", id, page)
    }

    /// Remove a layer's content, keeping the layer and its settings.
    public func clearPageLayer(_ id: String, page: String? = nil) {
        pageLayerCommand("pageLayerClear", id, page)
    }

    public func removePageLayer(_ id: String, page: String? = nil) {
        pageLayerCommand("pageLayerRemove", id, page)
    }

    public func setPageLayerOrder(_ id: String, z: Double, page: String? = nil) {
        pageLayerCommand("pageLayerOrder", id, page, ",z=\(vtgNumber(z))")
    }

    public func setPageLayerAlpha(_ id: String, alpha: Double, page: String? = nil) {
        pageLayerCommand("pageLayerAlpha", id, page, ",alpha=\(vtgNumber(clampedUnit(alpha)))")
    }

    public func setPageLayerVisible(_ id: String, _ visible: Bool, page: String? = nil) {
        pageLayerCommand("pageLayerVisible", id, page, ",visible=\(visible ? 1 : 0)")
    }

    /// Move a layer within the page — parallax without redrawing it.
    public func setPageLayerOffset(_ id: String, x: Int, y: Int, page: String? = nil) {
        pageLayerCommand("pageLayerOffset", id, page, ",x=\(x),y=\(y)")
    }

    public func setPageLayerCache(_ id: String, _ cache: Bool, page: String? = nil) {
        pageLayerCommand("pageLayerCache", id, page, ",cache=\(cache ? 1 : 0)")
    }

    /// Bring a layer in from another page. By reference it is shared and
    /// read-only here — a background drawn once and reused by every frame.
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
    public func queryWindowCanvas(timeoutMilliseconds: Int = 750) -> VTGCanvas? {
        guard let response = queryNamed("windowCanvas?", responseName: "windowCanvas", timeoutMilliseconds: timeoutMilliseconds) else {
            return nil
        }
        return parseWidthHeight(from: response, source: "windowCanvas?")
    }

    /// A page's size, scroll position, and layers.
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

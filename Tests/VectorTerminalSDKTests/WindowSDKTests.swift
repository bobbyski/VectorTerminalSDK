//
//  WindowSDKTests.swift
//  VectorTerminalSDK — WINDOW_PLAN.md Phase 6 (6.1–6.3)
//
//  The SDK side of windows, occlusion and the raster option: exactly which
//  bytes each call sends, and that existing calls send what they always did.
//

import Foundation
import Testing
@testable import VectorTerminalSDK

struct WindowSDKTests {
    private let esc = "\u{1B}"
    private func vtg(_ body: String) -> String { "\(esc)_VTG;\(body)\(esc)\\" }

    @Test("6.2: setLayerOcclusion sends layerOcclude, and refuses a bad layer")
    func occlusion() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        canvas.setLayerOcclusion(1, by: .ink)
        canvas.setLayerOcclusion(0, by: .none)
        canvas.setLayerOcclusion(9, by: .ink)
        #expect(output.text == vtg("layerOcclude,layer=1,by=ink") + vtg("layerOcclude,layer=0,by=none"))
    }

    @Test("6.1: a window handle selects its window around each write and returns to the root")
    func windowHandle() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        let map = canvas.createWindow(id: "map", columns: 30, rows: 10, x: 40, y: 50, title: "Map, big")
        map?.write("hello")
        map?.draw { $0.setLayerOcclusion(1, by: .ink) }
        map?.raise()
        map?.move(x: 12, y: 8.5)
        map?.close()
        #expect(output.text == vtg("windowCreate,id=map,cols=30,rows=10,x=40,y=50,title=Map  big")
                 + vtg("windowSelect,id=map") + "hello" + vtg("windowSelect,id=root")
                 + vtg("windowSelect,id=map") + vtg("layerOcclude,layer=1,by=ink") + vtg("windowSelect,id=root")
                 + vtg("windowRaise,id=map") + vtg("windowMove,id=map,x=12,y=8.5") + vtg("windowClose,id=map"))
    }

    @Test("Bad window ids and sizes send nothing")
    func badWindows() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        #expect(canvas.createWindow(id: "root", columns: 4, rows: 4) == nil)
        #expect(canvas.createWindow(id: "bad id", columns: 4, rows: 4) == nil)
        #expect(canvas.createWindow(id: "big", columns: 501, rows: 4) == nil)
        #expect(output.text.isEmpty)
    }

    @Test("Without VTG, a window's text still reaches the screen")
    func degradesToPlainOutput() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.noOp(output: output)
        canvas.createWindow(id: "w", columns: 4, rows: 2)?.write("plain")
        #expect(output.text == "plain")
    }

    @Test("6.3: raster mode with textErases sends text=erases; the plain call is unchanged")
    func rasterOption() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        canvas.enterRasterMode(textErases: true)
        canvas.leaveRasterMode()
        canvas.enterRasterMode()
        #expect(output.text == vtg("rasterMode,enabled=1,text=erases") + vtg("rasterMode,enabled=0")
                 + vtg("rasterMode,enabled=1"))
    }

    @Test("Capabilities: occlusion, windows and the raster option are read from the reply")
    func capabilities() {
        let reply = "\u{1B}_VTG;capabilities,protocol=VTG,textPlane=reserved,text=style,occlusion=ink,windows=experimental,windowMax=16,windowText=1\u{1B}\\"
        let parsed = VTGCapabilities(rawResponse: reply)
        #expect(parsed.supportsTextOcclusion)
        #expect(parsed.supportsWindows)
        #expect(parsed.windows == "experimental")
        #expect(parsed.windowMax == 16)
        #expect(!parsed.rasterTextErases)
        let old = VTGCapabilities(rawResponse: "\u{1B}_VTG;capabilities,protocol=VTG,textPlane=reserved\u{1B}\\")
        #expect(!old.supportsTextOcclusion && !old.supportsWindows && old.windowMax == nil)
    }

    @Test("Window events: frame clicks reach windowEventHandler; window mouse events say which window")
    func windowEvents() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        canvas.enableWindowEvents()
        #expect(output.text == vtg("windowEvents,enabled=1"))
        var events: [VTGWindowEvent] = []
        canvas.windowEventHandler = { events.append($0) }
        let reply = Array(vtg("windowMouse,id=map,part=title,type=down,button=0,x=120,y=55,modifiers=").utf8)
        #expect(canvas.parseEscapeEvent(reply) == nil, "delivered on its own channel")
        #expect(events.first?.windowID == "map")
        #expect(events.first?.part == "title")
        #expect(events.first?.x == 120)
    }
}

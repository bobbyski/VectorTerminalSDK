import Foundation
import Testing
import VectorTerminalSDK

private let esc = "\u{1B}"

private func apc(_ body: String) -> String {
    "\(esc)_VTG;\(body)\(esc)\\"
}

struct PageModeDispatchTests {
    /// The older dispatch matched substrings, so a response merely *containing*
    /// `_VTG;resize` arrived as a window resize. Dispatch is now by exact name.
    @Test func eventsDispatchOnTheExactResponseName() {
        let harness = EventHarness()
        defer { harness.close() }
        var pageEvents: [VTGPageEvent] = []
        harness.canvas.pageEventHandler = { pageEvents.append($0) }

        harness.write(apc("resizePage,width=10,height=20"))
        harness.write(apc("resize,width=640,height=480"))
        let event = harness.canvas.readEvent(timeoutMilliseconds: 100)

        guard case .resize(let canvas) = event else {
            Issue.record("expected the real resize, got \(String(describing: event))")
            return
        }
        #expect(canvas.width == 640)
        #expect(pageEvents.isEmpty, "resizePage is not a page event either")
    }

    @Test func existingEventsStillParse() {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write(apc("canvas,width=100,height=50"))
        guard case .canvas(let canvas) = harness.canvas.readEvent(timeoutMilliseconds: 100) else {
            Issue.record("canvas")
            return
        }
        #expect(canvas.width == 100)

        harness.write(apc("size,width=7,height=8"))
        guard case .canvas(let size) = harness.canvas.readEvent(timeoutMilliseconds: 100) else {
            Issue.record("size")
            return
        }
        #expect(size.height == 8)

        harness.write(apc("frameCommitted,id=f1"))
        guard case .frame(let frame) = harness.canvas.readEvent(timeoutMilliseconds: 100) else {
            Issue.record("frame")
            return
        }
        #expect(frame.type == "frameCommitted")
    }

    /// Page events go to their own handler, never into `VectorTerminalEvent`,
    /// so existing exhaustive `switch` statements keep compiling.
    @Test func pageEventsReachTheHandlerAndNotTheEventStream() {
        let harness = EventHarness()
        defer { harness.close() }
        var pageEvents: [VTGPageEvent] = []
        harness.canvas.pageEventHandler = { pageEvents.append($0) }

        harness.write(apc("pageOpened,id=p1,slot=A,w=800,h=600,growW=0,growH=1,replaced=none"))
        harness.write(apc("pageGrew,id=p1,w=800,h=1600.50"))
        harness.write("q")

        #expect(harness.canvas.readEvent(timeoutMilliseconds: 100) == .key(UInt8(ascii: "q")))
        #expect(pageEvents.map(\.name) == ["pageOpened", "pageGrew"])
        #expect(pageEvents[0].slot == "A")
        #expect(pageEvents[0].width == 800)
        #expect(pageEvents[1].height == 1600.5)
    }
}

struct PageModeCommandTests {
    @Test func sessionAndPageCommands() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.withPageMode(id: "doc", stacking: .text) {
            canvas.openPage(id: "p1", background: "#101018")
            canvas.showPage()
            canvas.openPage(id: "p2", width: .pixels(640), height: .cells(20))
            canvas.showPage(id: "p1", select: true)
        }

        let text = output.text
        #expect(text.contains(apc("pageBegin,version=1,id=doc,over=text")))
        #expect(text.contains(apc("pageOpen,id=p1,bg=#101018,h=-1,grow=h")))
        #expect(text.contains(apc("pageShow")))
        #expect(text.contains(apc("pageOpen,id=p2,bg=none,w=640,rows=20,grow=none")))
        #expect(text.contains(apc("pageShow,id=p1,select=1")))
        #expect(text.hasSuffix(apc("pageEnd")))
    }

    @Test func layerScrollAndViewportCommands() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.addPageLayer(id: "hud", z: 10, alpha: 0.5, scroll: .fixed, cache: true)
        canvas.selectPageLayer("hud")
        canvas.copyPageLayer("bg", from: "p1", layer: "bg")
        canvas.setPageLayerOffset("bg", x: -4, y: 2)
        canvas.scrollPage(toX: nil, y: 200)
        canvas.scrollPage(to: .bottom)
        canvas.setPageUserScrolling(true, axis: .y)
        canvas.setPageViewport(x: 10, y: 20, width: 300, height: 200)
        canvas.setDrawTarget(.base)

        let text = output.text
        #expect(text.contains(apc("pageLayerAdd,id=hud,z=10,alpha=0.500,scroll=fixed,cache=1")))
        #expect(text.contains(apc("pageLayerSelect,id=hud")))
        #expect(text.contains(apc("pageLayerCopy,id=bg,from=p1,mode=reference,layer=bg")))
        #expect(text.contains(apc("pageLayerOffset,id=bg,x=-4,y=2")))
        #expect(text.contains(apc("pageScroll,y=200")))
        #expect(text.contains(apc("pageScrollTo,anchor=bottom")))
        #expect(text.contains(apc("pageScrollMode,user=1,axis=y")))
        #expect(text.contains(apc("pageViewport,x=10,y=20,w=300,h=200")))
        #expect(text.contains(apc("pageTarget,scene=base")))
    }

    @Test func invalidIdentifiersSendNothing() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)
        canvas.openPage(id: "bad id")
        canvas.addPageLayer(id: "no,commas")
        canvas.closePage(id: "")
        #expect(output.text.isEmpty)
    }

    @Test func capabilitiesExposePageAndTextFeatures() {
        let withPages = VTGCapabilities(rawResponse: apc("capabilities,protocol=VTG,colors=hex-rgb,page=buffers2|layers|scroll,pageMaxLayers=32,text=style|styled|attr"))
        #expect(withPages.supportsPageMode)
        #expect(withPages.supportsRichText)
        #expect(withPages.pageFeatures == ["buffers2", "layers", "scroll"])
        #expect(withPages.textFeatures == ["style", "styled", "attr"])

        let older = VTGCapabilities(rawResponse: apc("capabilities,protocol=VTG,version=1.5.7"))
        #expect(!older.supportsPageMode)
        #expect(!older.supportsRichText)
    }
}

struct RichTextCommandTests {
    @Test func attributedTextEncodesLengthPrefixedRuns() {
        let text = VTGAttributedText()
            .append("Chapter 1", style: "h1")
            .newline()
            .append("café; a,b=c", style: nil)
            .append("two\nlines", style: "em")
        #expect(text.encoded == "h1:9:Chapter 1NL:0:-:12:café; a,b=cem:3:twoNL:0:em:5:lines")
    }

    @Test func invalidStyleNamesFallBackToTheBaseStyle() {
        #expect(VTGAttributedText("x", style: "bad style").encoded == "-:1:x")
        #expect(VTGAttributedText("x", style: "NL").encoded == "-:1:x")
    }

    @Test func richTextCommands() {
        let output = CapturingOutput()
        let canvas = VectorTerminalCanvas.hostValidated(output: output)

        canvas.defineTextStyle(VTGTextStyle(id: "h1", inherit: "base", font: "Georgia", size: 28, weight: 700, italic: true, color: .white))
        canvas.styledText(id: "title", x: 10, y: 20, value: "Hello, VTG", style: VTGTextStyle(size: 32), align: .center)
        canvas.attributedText(id: "a", x: 0, y: 0, text: VTGAttributedText("Hi", style: "h1"), maxWidth: 200)
        canvas.textBox(id: "b", x: 5, y: 6, width: 300, text: VTGAttributedText("Body"), style: VTGTextStyle(id: "h1"), overflow: .ellipsis, inset: 8)

        let text = output.text
        #expect(text.contains(apc("textStyle,id=h1,inherit=base,font=Georgia,size=28,weight=700,slant=italic,color=#f8fafc")))
        #expect(text.contains(apc("styledText,id=title,x=10,y=20,size=32,align=center;Hello, VTG")))
        #expect(text.contains(apc("attrText,id=a,x=0,y=0,maxWidth=200;h1:2:Hi")))
        #expect(text.contains(apc("textBox,id=b,x=5,y=6,w=300,h=-1,style=h1,overflow=ellipsis,inset=8;-:4:Body")))
    }

    @Test func measureTextSkipsPageEventsToItsAnswer() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }
        var pageEvents: [String] = []
        harness.canvas.pageEventHandler = { pageEvents.append($0.name) }

        harness.writeInput(apc("pageGrew,id=p1,w=800,h=900"))
        harness.writeInput(apc("textMeasure,id=measure,w=120,h=34,lines=2,firstBaseline=13,lastBaseline=30,truncated=0,fontResolved=Helvetica"))
        let measurement = try #require(harness.canvas.measureText(VTGAttributedText("hello world"), width: 120, timeoutMilliseconds: 200))

        #expect(measurement.width == 120)
        #expect(measurement.lineCount == 2)
        #expect(measurement.resolvedFonts == ["Helvetica"])
        #expect(pageEvents == ["pageGrew"])
        #expect(harness.output().contains(apc("textMeasure?,id=measure,kind=textBox,w=120,h=-1;-:11:hello world")))
    }

    @Test func pageStateQueryParses() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }
        harness.writeInput(apc("pageState,id=p1,slot=A,w=800,h=1600,growW=0,growH=1,scrollX=0,scrollY=200,alpha=1,bg=#101018ff,visible=1,layers=bg|1|hud"))
        let state = try #require(harness.canvas.queryPageState(timeoutMilliseconds: 200))
        #expect(state.id == "p1")
        #expect(state.height == 1600)
        #expect(state.growsHeight)
        #expect(state.scrollY == 200)
        #expect(state.isVisible)
        #expect(state.layers == ["bg", "1", "hud"])
    }
}

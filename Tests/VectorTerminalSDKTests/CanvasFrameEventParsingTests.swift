import Testing
import VectorTerminalSDK

struct CanvasFrameEventParsingTests {
    private let esc = "\u{1B}"

    @Test func readEventParsesCanvasResponses() throws {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write("\(esc)_VTG;resize,width=1200,height=900\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .resize(VTGCanvas(
            width: 1200,
            height: 900,
            source: "resize",
            rawResponse: "\(esc)_VTG;resize,width=1200,height=900\(esc)\\"
        )))

        harness.write("\(esc)_VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=0.1,canvasWidth=1440,canvasHeight=1000\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .canvas(VTGCanvas(
            width: 1440,
            height: 1000,
            source: "capabilities",
            rawResponse: "\(esc)_VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=0.1,canvasWidth=1440,canvasHeight=1000\(esc)\\"
        )))
    }

    @Test func readEventParsesFrameLifecycleResponses() throws {
        let harness = EventHarness()
        defer { harness.close() }

        harness.write("\(esc)_VTG;frameStarted,id=demo,timeout=500\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .frame(VTGFrameEvent(
            type: "frameStarted",
            id: "demo",
            timeoutMilliseconds: 500,
            rawResponse: "\(esc)_VTG;frameStarted,id=demo,timeout=500\(esc)\\"
        )))

        harness.write("\(esc)_VTG;frameCommitted,id=demo\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .frame(VTGFrameEvent(
            type: "frameCommitted",
            id: "demo",
            rawResponse: "\(esc)_VTG;frameCommitted,id=demo\(esc)\\"
        )))

        harness.write("\(esc)_VTG;frameCanceled,id=demo,reason=app\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .frame(VTGFrameEvent(
            type: "frameCanceled",
            id: "demo",
            reason: "app",
            rawResponse: "\(esc)_VTG;frameCanceled,id=demo,reason=app\(esc)\\"
        )))

        harness.write("\(esc)_VTG;frameTimeout,id=demo,reason=timeout\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .frame(VTGFrameEvent(
            type: "frameTimeout",
            id: "demo",
            reason: "timeout",
            rawResponse: "\(esc)_VTG;frameTimeout,id=demo,reason=timeout\(esc)\\"
        )))

        harness.write("\(esc)_VTG;frameRejected,id=demo2,reason=nested\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .frame(VTGFrameEvent(
            type: "frameRejected",
            id: "demo2",
            reason: "nested",
            rawResponse: "\(esc)_VTG;frameRejected,id=demo2,reason=nested\(esc)\\"
        )))

        harness.write("\(esc)_VTG;frameRejected,id=wrong,reason=idMismatch\(esc)\\")
        #expect(harness.canvas.readEvent(timeoutMilliseconds: 50) == .frame(VTGFrameEvent(
            type: "frameRejected",
            id: "wrong",
            reason: "idMismatch",
            rawResponse: "\(esc)_VTG;frameRejected,id=wrong,reason=idMismatch\(esc)\\"
        )))
    }
}

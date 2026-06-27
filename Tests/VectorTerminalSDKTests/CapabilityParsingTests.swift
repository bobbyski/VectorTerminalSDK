import Testing
import VectorTerminalSDK

struct CapabilityParsingTests {
    private let esc = "\u{1B}"

    @Test func queryCapabilityInfoParsesUnderTextSubset() throws {
        let harness = try EnabledCanvasHarness()
        defer { harness.close() }

        let response = "\(esc)_VTG;capabilities,protocol=VTG,schema=vtg.capabilities.v1,version=1.5.3,renderer=metal,canvasWidth=1440,canvasHeight=900,commands=line|rect|text,planned=,primitives=line|rect|text|image|sprite,underText=line|rect,formats=png|jpeg,raster=image|filter,sprites=bitmap|indexed,layers=-1-4,defaultLayer=1,textPlane=reserved,layerScroll=true,layerAlpha=1-4,clip=layer-rect,hit=rect-layered,events=mouse|resize|frame,colors=hex-rgb|hex-rgba\(esc)\\"
        harness.writeInput(response)

        let capabilities = harness.canvas.queryCapabilityInfo(timeoutMilliseconds: 50)

        #expect(capabilities?.protocolName == "VTG")
        #expect(capabilities?.schema == "vtg.capabilities.v1")
        #expect(capabilities?.renderer == "metal")
        #expect(capabilities?.canvas?.width == 1440)
        #expect(capabilities?.canvas?.height == 900)
        #expect(capabilities?.commands == ["line", "rect", "text"])
        #expect(capabilities?.primitives == ["line", "rect", "text", "image", "sprite"])
        #expect(capabilities?.underTextPrimitives == ["line", "rect"])
        #expect(capabilities?.formats == ["png", "jpeg"])
        #expect(capabilities?.raster == ["image", "filter"])
        #expect(capabilities?.sprites == ["bitmap", "indexed"])
        #expect(capabilities?.layers == "-1-4")
        #expect(capabilities?.defaultLayer == 1)
        #expect(capabilities?.textPlane == "reserved")
        #expect(capabilities?.textPlaneStatus == .reserved)
        #expect(capabilities?.textPlaneStatus.isReserved == true)
        #expect(capabilities?.layerScroll == true)
        #expect(capabilities?.layerAlpha == "1-4")
        #expect(capabilities?.clip == "layer-rect")
        #expect(capabilities?.hit == "rect-layered")
        #expect(capabilities?.events == ["mouse", "resize", "frame"])
        #expect(capabilities?.colors == ["hex-rgb", "hex-rgba"])
        #expect(harness.output().contains("\(esc)_VTG;capabilities?\(esc)\\"))
    }

    @Test func textPlaneStatusPreservesFutureValues() {
        #expect(VTGTextPlaneStatus("reserved") == .reserved)
        #expect(VTGTextPlaneStatus("RESERVED") == .reserved)
        #expect(VTGTextPlaneStatus("vector-v1") == .other("vector-v1"))
        #expect(VTGTextPlaneStatus(nil) == .other(""))
        #expect(VTGTextPlaneStatus("vector-v1").rawValue == "vector-v1")
        #expect(!VTGTextPlaneStatus("vector-v1").isReserved)
    }
}

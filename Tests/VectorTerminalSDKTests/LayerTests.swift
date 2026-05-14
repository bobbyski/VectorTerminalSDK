import Testing
import VectorTerminalSDK

struct LayerTests {
    @Test func layerConstantsMatchCurrentVTGContract() {
        #expect(VTGLayer.textPlane == 0)
        #expect(VTGLayer.defaultOverlay == 1)
        #expect(VTGLayer.overlayRange == 1...4)
        #expect(VTGLayer.advertisedRange == "0-4")
    }

    @Test func layerValidationSeparatesTextPlaneFromScrollableOverlays() {
        #expect(VTGLayer.isSupported(VTGLayer.textPlane))
        #expect(!VTGLayer.isScrollable(VTGLayer.textPlane))
        #expect(VTGLayer.isScrollable(VTGLayer.overlay4))
        #expect(!VTGLayer.isSupported(5))
    }

    @Test func layerClampingKeepsValuesInProtocolRange() {
        #expect(VTGLayer.clamped(-20) == VTGLayer.textPlane)
        #expect(VTGLayer.clamped(2) == VTGLayer.overlay2)
        #expect(VTGLayer.clamped(99) == VTGLayer.overlay4)
    }
}

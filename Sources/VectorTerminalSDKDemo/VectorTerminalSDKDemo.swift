import Foundation
import VectorTerminalSDK

@main
@MainActor
enum VectorTerminalSDKDemo {
    static func main() {
        let canvas: VectorTerminalCanvas
        do {
            canvas = try VectorTerminalCanvas()
        } catch {
            print("VectorTerminalSDKDemo requires a VTG-capable VectorTerminal session.")
            print("Graphics disabled: \(error.localizedDescription)")
            exit(1)
        }

        guard let size = canvas.queryCanvas() else {
            print("VectorTerminalSDKDemo requires a VTG-capable VectorTerminal session.")
            exit(1)
        }

        canvas.clear()
        canvas.rect(
            id: "sdk-border",
            x: 12,
            y: 12,
            width: size.width - 24,
            height: size.height - 24,
            stroke: .green,
            fill: nil,
            lineWidth: 2
        )
        canvas.line(
            id: "sdk-diagonal-a",
            x1: 80,
            y1: 80,
            x2: size.width - 80,
            y2: size.height - 80,
            stroke: .blue,
            width: 5
        )
        canvas.circle(
            id: "sdk-circle",
            cx: size.width / 2,
            cy: size.height / 2,
            radius: min(size.width, size.height) / 5,
            stroke: .cyan,
            fill: nil,
            lineWidth: 6
        )
        canvas.text(
            id: "sdk-title",
            x: 36,
            y: 36,
            value: "VectorTerminalSDK demo",
            color: .white,
            size: 22
        )
        canvas.present()

        print("Drew VectorTerminalSDK demo on \(size.width)x\(size.height). Press Return to clear.")
        _ = readLine()
        canvas.clear()
        canvas.present()
    }
}

import AppKit
import CoreGraphics

// Renders the Sudokuno app icon: a 3x3 box of rounded cells, the centre cell is a flame.
// Usage: swift icon.swift <outDir>

let size: CGFloat = 1024
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

enum Variant { case light, dark, tinted }

func flamePath(in r: CGRect) -> CGPath {
    let p = CGMutablePath()
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
    // y = 0 bottom, y = 1 top (CoreGraphics)
    p.move(to: pt(0.50, 0.00))
    p.addCurve(to: pt(0.90, 0.40), control1: pt(0.74, 0.00), control2: pt(0.90, 0.18))
    p.addCurve(to: pt(0.70, 0.80), control1: pt(0.90, 0.58), control2: pt(0.80, 0.70))
    p.addCurve(to: pt(0.60, 0.62), control1: pt(0.70, 0.72), control2: pt(0.66, 0.66))
    p.addCurve(to: pt(0.46, 1.00), control1: pt(0.62, 0.80), control2: pt(0.56, 0.92))
    p.addCurve(to: pt(0.10, 0.40), control1: pt(0.24, 0.84), control2: pt(0.10, 0.62))
    p.addCurve(to: pt(0.50, 0.00), control1: pt(0.10, 0.18), control2: pt(0.26, 0.00))
    p.closeSubpath()
    return p
}

func innerFlame(in r: CGRect) -> CGPath {
    let p = CGMutablePath()
    func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: r.minX + x * r.width, y: r.minY + y * r.height) }
    p.move(to: pt(0.50, 0.10))
    p.addCurve(to: pt(0.72, 0.32), control1: pt(0.63, 0.10), control2: pt(0.72, 0.19))
    p.addCurve(to: pt(0.50, 0.66), control1: pt(0.72, 0.46), control2: pt(0.60, 0.56))
    p.addCurve(to: pt(0.28, 0.32), control1: pt(0.40, 0.56), control2: pt(0.28, 0.46))
    p.addCurve(to: pt(0.50, 0.10), control1: pt(0.28, 0.19), control2: pt(0.37, 0.10))
    p.closeSubpath()
    return p
}

func render(_ v: Variant) -> CGImage {
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                        space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    let full = CGRect(x: 0, y: 0, width: size, height: size)

    // Background
    switch v {
    case .light:
        let g = CGGradient(colorsSpace: cs, colors: [color(0x2B2F8F), color(0x5B3FD9)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    case .dark:
        let g = CGGradient(colorsSpace: cs, colors: [color(0x14152E), color(0x1E1A3D)] as CFArray, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    case .tinted:
        ctx.setFillColor(color(0x000000)); ctx.fill(full)
    }

    // 3x3 grid of cells
    let gridSide: CGFloat = 700
    let gap: CGFloat = 26
    let cell = (gridSide - 2 * gap) / 3
    let origin = (size - gridSide) / 2
    let radius: CGFloat = 46
    for row in 0..<3 {
        for col in 0..<3 {
            let rect = CGRect(x: origin + CGFloat(col) * (cell + gap), y: origin + CGFloat(row) * (cell + gap),
                              width: cell, height: cell)
            let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
            if row == 1 && col == 1 {
                ctx.saveGState()
                ctx.addPath(path); ctx.clip()
                switch v {
                case .tinted:
                    ctx.setFillColor(color(0xFFFFFF)); ctx.fill(rect)
                default:
                    let g = CGGradient(colorsSpace: cs, colors: [color(0xFF4D2E), color(0xFFB23F)] as CFArray, locations: [0, 1])!
                    ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
                }
                ctx.restoreGState()
                // flame
                let fr = rect.insetBy(dx: cell * 0.18, dy: cell * 0.12)
                ctx.addPath(flamePath(in: fr))
                ctx.setFillColor(v == .tinted ? color(0x000000, 0.85) : color(0xFFFFFF))
                ctx.fillPath()
                if v != .tinted {
                    ctx.addPath(innerFlame(in: fr))
                    ctx.setFillColor(color(0xFFB23F))
                    ctx.fillPath()
                }
            } else {
                let alpha: CGFloat
                switch v {
                case .light: alpha = (row + col) % 2 == 0 ? 0.92 : 0.70
                case .dark: alpha = (row + col) % 2 == 0 ? 0.26 : 0.16
                case .tinted: alpha = (row + col) % 2 == 0 ? 0.55 : 0.35
                }
                ctx.addPath(path)
                ctx.setFillColor(color(0xFFFFFF, alpha))
                ctx.fillPath()
            }
        }
    }
    return ctx.makeImage()!
}

for (v, name) in [(Variant.light, "AppIcon.png"), (.dark, "AppIcon-Dark.png"), (.tinted, "AppIcon-Tinted.png")] {
    let img = render(v)
    let rep = NSBitmapImageRep(cgImage: img)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: outDir).appendingPathComponent(name))
    print("wrote", name)
}

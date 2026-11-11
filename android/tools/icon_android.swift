import AppKit
import CoreGraphics

// Icône adaptative Android : premier plan (grille + flamme) et version monochrome, fond transparent.
// Usage : swift tools/icon_android.swift <dossier res>
let resDir = CommandLine.arguments[1]

func color(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

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


/// size = 108 dp en pixels ; la grille occupe 52 dp au centre (zone visible sûre).
func render(size: Int, monochrome: Bool) -> CGImage {
    let s = CGFloat(size)
    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let gridSide = s * 52 / 108
    let gap = gridSide * 26 / 700
    let cell = (gridSide - 2 * gap) / 3
    let origin = (s - gridSide) / 2
    let radius = cell * 0.24
    for row in 0..<3 {
        for col in 0..<3 {
            let rect = CGRect(x: origin + CGFloat(col) * (cell + gap), y: origin + CGFloat(row) * (cell + gap), width: cell, height: cell)
            let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
            if row == 1 && col == 1 {
                ctx.saveGState()
                ctx.addPath(path); ctx.clip()
                if monochrome {
                    ctx.setFillColor(color(0xFFFFFF)); ctx.fill(rect)
                } else {
                    let g = CGGradient(colorsSpace: cs, colors: [color(0xFF4D2E), color(0xFFB23F)] as CFArray, locations: [0, 1])!
                    ctx.drawLinearGradient(g, start: CGPoint(x: rect.midX, y: rect.minY), end: CGPoint(x: rect.midX, y: rect.maxY), options: [])
                }
                ctx.restoreGState()
                let fr = rect.insetBy(dx: cell * 0.18, dy: cell * 0.12)
                ctx.addPath(flamePath(in: fr))
                if monochrome {
                    ctx.setBlendMode(.clear)
                    ctx.fillPath()
                    ctx.setBlendMode(.normal)
                } else {
                    ctx.setFillColor(color(0xFFFFFF)); ctx.fillPath()
                    ctx.addPath(innerFlame(in: fr)); ctx.setFillColor(color(0xFFB23F)); ctx.fillPath()
                }
            } else {
                ctx.addPath(path)
                ctx.setFillColor(color(0xFFFFFF, monochrome ? 1 : ((row + col) % 2 == 0 ? 0.92 : 0.70)))
                ctx.fillPath()
            }
        }
    }
    return ctx.makeImage()!
}

let densities: [(String, Int)] = [("mdpi", 108), ("hdpi", 162), ("xhdpi", 216), ("xxhdpi", 324), ("xxxhdpi", 432)]
for (d, px) in densities {
    let dir = URL(fileURLWithPath: resDir).appendingPathComponent("mipmap-\(d)")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    for (name, mono) in [("ic_launcher_foreground.png", false), ("ic_launcher_monochrome.png", true)] {
        let rep = NSBitmapImageRep(cgImage: render(size: px, monochrome: mono))
        try! rep.representation(using: .png, properties: [:])!.write(to: dir.appendingPathComponent(name))
    }
}
// Icône 512 px pour la fiche Google Play (fond compris)
let size = 512
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
let g = CGGradient(colorsSpace: cs, colors: [color(0x2B2F8F), color(0x5B3FD9)] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: 512), end: CGPoint(x: 512, y: 0), options: [])
let fg = render(size: 744, monochrome: false) // 108 dp → grille agrandie pour remplir l'icône Play
ctx.draw(fg, in: CGRect(x: -116, y: -116, width: 744, height: 744))
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: resDir).appendingPathComponent("../../../../docs/play-icon-512.png"))
print("ok")

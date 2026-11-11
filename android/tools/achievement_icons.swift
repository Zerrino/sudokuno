// Icônes des succès (512 × 512 PNG), pour Google Play Jeux et Game Center.
//   swift android/tools/achievement_icons.swift [police.ttf]
// Formes dessinées à la main (pas de SF Symbols : réservés aux plateformes Apple).
// Chiffres : Lato (SIL Open Font License 1.1), par défaut celle livrée avec rdoc dans Homebrew.
import AppKit
import CoreText

let size: CGFloat = 512
let outDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../docs/achievements").standardized
let fontPath = CommandLine.arguments.dropFirst().first
    ?? "/opt/homebrew/lib/ruby/gems/4.0.0/gems/rdoc-7.0.4/lib/rdoc/generator/template/darkfish/fonts/Lato-Regular.ttf"
guard let provider = CGDataProvider(url: URL(fileURLWithPath: fontPath) as CFURL), let cgFont = CGFont(provider) else {
    fatalError("Police introuvable : \(fontPath)")
}
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func rgb(_ hex: UInt32) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}
let white = CGColor(gray: 1, alpha: 1)

func render(_ name: String, _ top: UInt32, _ bottom: UInt32, _ draw: (CGContext) -> Void) {
    let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // Fond : dégradé diagonal + grille de Sudoku en filigrane.
    let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!, colors: [rgb(top), rgb(bottom)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 0.08))
    for k in 1..<9 {
        let v = size * CGFloat(k) / 9
        ctx.setLineWidth(k % 3 == 0 ? 6 : 2)
        ctx.move(to: CGPoint(x: v, y: 0)); ctx.addLine(to: CGPoint(x: v, y: size))
        ctx.move(to: CGPoint(x: 0, y: v)); ctx.addLine(to: CGPoint(x: size, y: v))
        ctx.strokePath()
    }
    ctx.setFillColor(white)
    ctx.setStrokeColor(white)
    draw(ctx)
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    try! rep.representation(using: .png, properties: [:])!.write(to: outDir.appendingPathComponent("\(name).png"))
    print("✓ \(name).png")
}

/// Texte centré en (cx, cy), épaissi par un contour.
func text(_ ctx: CGContext, _ s: String, cx: CGFloat, cy: CGFloat, size fontSize: CGFloat, color: CGColor = white) {
    let font = CTFontCreateWithGraphicsFont(cgFont, fontSize, nil, nil)
    let attr = NSAttributedString(string: s, attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font,
                                                          NSAttributedString.Key(kCTForegroundColorAttributeName as String): color])
    let line = CTLineCreateWithAttributedString(attr)
    let b = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
    ctx.saveGState()
    ctx.setStrokeColor(color)
    ctx.setLineWidth(fontSize * 0.07)
    ctx.setLineJoin(.round)
    ctx.setTextDrawingMode(.fillStroke)
    ctx.textPosition = CGPoint(x: cx - b.midX, y: cy - b.midY)
    CTLineDraw(line, ctx)
    ctx.restoreGState()
}

func flame(_ ctx: CGContext, cx: CGFloat, base: CGFloat, h: CGFloat) {
    let w = h * 0.78
    let p = CGMutablePath()
    p.move(to: CGPoint(x: cx, y: base))
    p.addCurve(to: CGPoint(x: cx - w / 2, y: base + h * 0.38), control1: CGPoint(x: cx - w * 0.36, y: base), control2: CGPoint(x: cx - w / 2, y: base + h * 0.16))
    p.addCurve(to: CGPoint(x: cx - w * 0.12, y: base + h * 0.86), control1: CGPoint(x: cx - w / 2, y: base + h * 0.62), control2: CGPoint(x: cx - w * 0.28, y: base + h * 0.72))
    p.addCurve(to: CGPoint(x: cx + w * 0.06, y: base + h), control1: CGPoint(x: cx - w * 0.06, y: base + h * 0.93), control2: CGPoint(x: cx, y: base + h * 0.98))
    p.addCurve(to: CGPoint(x: cx + w * 0.2, y: base + h * 0.62), control1: CGPoint(x: cx + w * 0.06, y: base + h * 0.84), control2: CGPoint(x: cx + w * 0.12, y: base + h * 0.7))
    p.addCurve(to: CGPoint(x: cx + w * 0.3, y: base + h * 0.74), control1: CGPoint(x: cx + w * 0.26, y: base + h * 0.66), control2: CGPoint(x: cx + w * 0.3, y: base + h * 0.7))
    p.addCurve(to: CGPoint(x: cx + w / 2, y: base + h * 0.36), control1: CGPoint(x: cx + w * 0.44, y: base + h * 0.62), control2: CGPoint(x: cx + w / 2, y: base + h * 0.52))
    p.addCurve(to: CGPoint(x: cx, y: base), control1: CGPoint(x: cx + w / 2, y: base + h * 0.14), control2: CGPoint(x: cx + w * 0.34, y: base))
    ctx.addPath(p)
    ctx.fillPath()
}

func miniGrid(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, cell: CGFloat, filled: Int) {
    let gap = cell * 0.18
    let total = cell * 3 + gap * 2
    for k in 0..<9 {
        let r = 2 - k / 3, c = k % 3
        let rect = CGRect(x: cx - total / 2 + CGFloat(c) * (cell + gap), y: cy - total / 2 + CGFloat(r) * (cell + gap), width: cell, height: cell)
        ctx.setFillColor(CGColor(gray: 1, alpha: k < filled ? 1 : 0.28))
        ctx.addPath(CGPath(roundedRect: rect, cornerWidth: cell * 0.22, cornerHeight: cell * 0.22, transform: nil))
        ctx.fillPath()
    }
    ctx.setFillColor(white)
}

// --- Séries ---
for days in [7, 30, 100, 365, 1000] {
    render("streak_\(days)", 0xFFA21F, 0xE0360C) { ctx in
        flame(ctx, cx: 256, base: 96, h: 330)
        text(ctx, "\(days)", cx: 256, cy: 196, size: days >= 1000 ? 92 : days >= 100 ? 112 : 136, color: rgb(0xE8480F))
    }
}

// --- Niveaux débloqués : plus le niveau est dur, plus la grille est remplie ---
let levels: [(String, UInt32, UInt32, Int)] = [("M", 0x5DB8FF, 0x1F6FC0, 3), ("D", 0xA996FF, 0x5B3FD9, 5),
                                               ("E", 0xFFC14D, 0xD27800, 7), ("X", 0xFF6B70, 0xB0222A, 9)]
for (letter, top, bottom, filled) in levels {
    render("unlock_\(letter)", top, bottom) { ctx in miniGrid(ctx, cx: 256, cy: 256, cell: 92, filled: filled) }
}

// --- Parfait : coche dans un cercle ---
render("perfect", 0x4ADE80, 0x13703B) { ctx in
    ctx.setLineWidth(30)
    ctx.strokeEllipse(in: CGRect(x: 106, y: 106, width: 300, height: 300))
    ctx.setLineWidth(40); ctx.setLineCap(.round); ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: 182, y: 262)); ctx.addLine(to: CGPoint(x: 236, y: 206)); ctx.addLine(to: CGPoint(x: 334, y: 318))
    ctx.strokePath()
}

// --- Première Diabolique : deux maillons de chaîne ---
render("diabolique_first", 0xFF6B70, 0x8E1B22) { ctx in
    ctx.setLineWidth(34)
    for (dx, dy) in [(-62.0, -62.0), (62.0, 62.0)] {
        ctx.saveGState()
        ctx.translateBy(x: 256 + dx, y: 256 + dy)
        ctx.rotate(by: .pi / 4)
        ctx.addPath(CGPath(roundedRect: CGRect(x: -120, y: -58, width: 240, height: 116), cornerWidth: 58, cornerHeight: 58, transform: nil))
        ctx.strokePath()
        ctx.restoreGState()
    }
}

// --- Défi gagné : coupe ---
render("challenge_won", 0x5DB8FF, 0x5B3FD9) { ctx in
    let cup = CGMutablePath()
    cup.move(to: CGPoint(x: 166, y: 390))
    cup.addLine(to: CGPoint(x: 346, y: 390))
    cup.addCurve(to: CGPoint(x: 256, y: 222), control1: CGPoint(x: 346, y: 280), control2: CGPoint(x: 316, y: 222))
    cup.addCurve(to: CGPoint(x: 166, y: 390), control1: CGPoint(x: 196, y: 222), control2: CGPoint(x: 166, y: 280))
    ctx.addPath(cup); ctx.fillPath()
    ctx.setLineWidth(22)
    ctx.strokeEllipse(in: CGRect(x: 112, y: 290, width: 92, height: 80))
    ctx.strokeEllipse(in: CGRect(x: 308, y: 290, width: 92, height: 80))
    ctx.fill(CGRect(x: 240, y: 160, width: 32, height: 70))
    ctx.addPath(CGPath(roundedRect: CGRect(x: 176, y: 116, width: 160, height: 48), cornerWidth: 14, cornerHeight: 14, transform: nil))
    ctx.fillPath()
}

// --- 100 grilles résolues ---
render("solved_100", 0x7C7DF5, 0x3A2BB0) { ctx in
    miniGrid(ctx, cx: 256, cy: 330, cell: 40, filled: 9)
    text(ctx, "100", cx: 256, cy: 186, size: 150)
}

// --- Grilles créées (créateur) : crayon + nombre ---
func pencil(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, length: CGFloat, thickness: CGFloat, color: CGColor) {
    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.rotate(by: -.pi / 9)
    ctx.setFillColor(color)
    let body = length * 0.72, tip = length * 0.2, cap = length * 0.08
    ctx.addPath(CGPath(roundedRect: CGRect(x: -length / 2, y: -thickness / 2, width: cap, height: thickness),
                       cornerWidth: thickness * 0.25, cornerHeight: thickness * 0.25, transform: nil))
    ctx.fillPath()
    ctx.fill(CGRect(x: -length / 2 + cap + 8, y: -thickness / 2, width: body - 8, height: thickness))
    ctx.move(to: CGPoint(x: -length / 2 + cap + body + 8, y: -thickness / 2))
    ctx.addLine(to: CGPoint(x: length / 2, y: 0))
    ctx.addLine(to: CGPoint(x: -length / 2 + cap + body + 8, y: thickness / 2))
    ctx.closePath()
    ctx.fillPath()
    ctx.restoreGState()
}
for n in [1, 5, 10, 25, 50, 100] {
    render("created_\(n)", 0x2DD4BF, 0x0F766E) { ctx in
        text(ctx, "\(n)", cx: 256, cy: 300, size: n >= 100 ? 150 : 170)
        pencil(ctx, cx: 256, cy: 140, length: 300, thickness: 50, color: white)
    }
}

import AppKit

// Visuels Google Play : captures élargies au format ≤ 2:1 et image de présentation 1024 × 500.
// Usage : swift tools/play_assets.swift <captures brutes (dossiers fr/, en/)> <sortie docs/PlayStore>
let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1]), output = URL(fileURLWithPath: args[2])
let fm = FileManager.default

func png(_ rep: NSBitmapImageRep, _ url: URL) { try! rep.representation(using: .png, properties: [:])!.write(to: url) }

func canvas(_ w: Int, _ h: Int, _ draw: (CGContext) -> Void) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw(NSGraphicsContext.current!.cgContext)
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

for lang in ["fr", "en"] {
    let src = input.appendingPathComponent(lang)
    let dst = output.appendingPathComponent("screenshots/\(lang)")
    try? fm.createDirectory(at: dst, withIntermediateDirectories: true)
    for name in (try? fm.contentsOfDirectory(atPath: src.path))?.sorted() ?? [] where name.hasSuffix(".png") {
        guard let img = NSImage(contentsOf: src.appendingPathComponent(name)),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
        let h = cg.height, w = max(cg.width, Int((Double(h) / 1.98).rounded(.up)))
        let dark = name.contains("sombre")
        let rep = canvas(w, h) { ctx in
            ctx.setFillColor(dark ? CGColor(red: 0.06, green: 0.06, blue: 0.09, alpha: 1) : CGColor(red: 0.953, green: 0.949, blue: 0.98, alpha: 1))
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
            ctx.draw(cg, in: CGRect(x: (w - cg.width) / 2, y: 0, width: cg.width, height: h))
        }
        png(rep, dst.appendingPathComponent(name))
    }
}

let icon = NSImage(contentsOf: output.appendingPathComponent("../play-icon-512.png"))!
for (lang, tagline) in [("fr", "Le Sudoku du jour, sans pub"), ("en", "Daily Sudoku, no ads")] {
    let rep = canvas(1024, 500) { ctx in
        let g = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                           colors: [CGColor(red: 0.17, green: 0.18, blue: 0.56, alpha: 1), CGColor(red: 0.36, green: 0.25, blue: 0.85, alpha: 1)] as CFArray,
                           locations: [0, 1])!
        ctx.drawLinearGradient(g, start: .zero, end: CGPoint(x: 1024, y: 500), options: [])
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(roundedRect: NSRect(x: 70, y: 80, width: 340, height: 340), xRadius: 76, yRadius: 76).addClip()
        icon.draw(in: NSRect(x: 70, y: 80, width: 340, height: 340))
        NSGraphicsContext.restoreGraphicsState()
        let title = NSAttributedString(string: "Sudokuno", attributes: [.font: NSFont.systemFont(ofSize: 92, weight: .heavy), .foregroundColor: NSColor.white])
        title.draw(at: NSPoint(x: 450, y: 250))
        let sub = NSAttributedString(string: tagline, attributes: [.font: NSFont.systemFont(ofSize: 40, weight: .semibold), .foregroundColor: NSColor(white: 1, alpha: 0.85)])
        sub.draw(at: NSPoint(x: 455, y: 180))
    }
    png(rep, output.appendingPathComponent("feature-graphic-\(lang).png"))
}
print("ok")

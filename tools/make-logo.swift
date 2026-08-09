// Derives every logo asset from the master artwork.
//   swift tools/make-logo.swift <master.jpg> <outdir>
// macOS only, no dependencies. See README.

import AppKit
import Foundation

let src = URL(fileURLWithPath: CommandLine.arguments[1])
let outDir = URL(fileURLWithPath: CommandLine.arguments[2])

guard let img = NSImage(contentsOf: src),
      let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let cg = rep.cgImage else { fatalError("cannot read \(src.path)") }

let w = rep.pixelsWide, h = rep.pixelsHigh

// ── find the artwork inside the uniform cream field ──────────────────────
func rgb(_ x: Int, _ y: Int) -> (Int, Int, Int) {
  guard let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { return (0, 0, 0) }
  return (Int(c.redComponent * 255), Int(c.greenComponent * 255), Int(c.blueComponent * 255))
}
let bg = rgb(4, 4)
func isBackground(_ c: (Int, Int, Int)) -> Bool {
  abs(c.0 - bg.0) <= 10 && abs(c.1 - bg.1) <= 10 && abs(c.2 - bg.2) <= 10
}

var minX = w, minY = h, maxX = -1, maxY = -1
for y in stride(from: 0, to: h, by: 2) {
  for x in stride(from: 0, to: w, by: 2) where !isBackground(rgb(x, y)) {
    if x < minX { minX = x }; if x > maxX { maxX = x }
    if y < minY { minY = y }; if y > maxY { maxY = y }
  }
}
// colorAt uses a top-left origin; CoreGraphics draws from the bottom-left.
let cx = Double(minX + maxX) / 2
let cyTop = Double(minY + maxY) / 2

// The artwork is a ring with leaves poking out at the lower left, so the
// bounding box understates its reach. Measure the true radius instead.
var maxR = 0.0
for y in stride(from: 0, to: h, by: 2) {
  for x in stride(from: 0, to: w, by: 2) where !isBackground(rgb(x, y)) {
    let d = ((Double(x) - cx) * (Double(x) - cx) + (Double(y) - cyTop) * (Double(y) - cyTop)).squareRoot()
    if d > maxR { maxR = d }
  }
}
print("artwork: bbox \(maxX - minX)x\(maxY - minY), centre (\(Int(cx)),\(Int(cyTop))), rayon \(Int(maxR))")

let cream = NSColor(srgbRed: Double(bg.0) / 255, green: Double(bg.1) / 255, blue: Double(bg.2) / 255, alpha: 1)
let cyBottom = Double(h) - cyTop   // same centre, bottom-left origin

func context(_ size: Int) -> CGContext {
  let c = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  c.interpolationQuality = .high
  return c
}

/// Draws the artwork scaled so its outermost pixel lands `inset` from the edge.
func place(_ c: CGContext, size: Int, inset: Double) {
  let target = (Double(size) / 2) - inset
  let scale = target / maxR
  let dw = Double(w) * scale, dh = Double(h) * scale
  // put the artwork centre at the canvas centre
  let x = Double(size) / 2 - cx * scale
  let y = Double(size) / 2 - cyBottom * scale
  c.draw(cg, in: CGRect(x: x, y: y, width: dw, height: dh))
}

func writePNG(_ img: CGImage, _ name: String) {
  let r = NSBitmapImageRep(cgImage: img)
  let data = r.representation(using: .png, properties: [.compressionFactor: 1.0])!
  try! data.write(to: outDir.appendingPathComponent(name))
  print("  \(name)  \(img.width)x\(img.height)  \(data.count / 1024) kB")
}

// ── 1. round badge, transparent outside the disc — the header mark ───────
// Below ~56px the illustration turns to mush, so small sizes get the
// simplified ring instead (see part 3).
for (size, name) in [(256, "logo.png"), (192, "favicon-192.png")] {
  let c = context(size)
  let disc = CGRect(x: 0, y: 0, width: Double(size), height: Double(size))
  c.saveGState()
  c.addEllipse(in: disc)
  c.clip()
  c.setFillColor(cream.cgColor)
  c.fill(disc)
  place(c, size: size, inset: Double(size) * 0.035)
  c.restoreGState()
  writePNG(c.makeImage()!, name)
}

// ── 2. iOS home-screen icon: opaque square, iOS rounds it itself ─────────
do {
  let size = 180
  let c = context(size)
  c.setFillColor(cream.cgColor)
  c.fill(CGRect(x: 0, y: 0, width: Double(size), height: Double(size)))
  place(c, size: size, inset: Double(size) * 0.07)
  writePNG(c.makeImage()!, "apple-touch-icon.png")
}

// ── 3. the small mark: the logo's tricolour ring, nothing else ────────────
// A favicon's job is to be TELLABLE APART in a tab strip, and at 16-32px the
// full illustration is a brown smudge. The ring is the artwork's outer
// identity and survives the size. Colours sampled off the master.
let arcs: [(NSColor, Double, Double)] = [
  (NSColor(srgbRed: 0xE8 / 255, green: 0xA5 / 255, blue: 0x26 / 255, alpha: 1), 10, 108),   // amber, upper right
  (NSColor(srgbRed: 0xB1 / 255, green: 0x41 / 255, blue: 0x10 / 255, alpha: 1), 118, 186),  // rust, upper left
  (NSColor(srgbRed: 0x44 / 255, green: 0x69 / 255, blue: 0x1A / 255, alpha: 1), 200, 356)   // green, along the bottom
]

for (size, name) in [(48, "favicon-48.png"), (32, "favicon-32.png")] {
  let c = context(size)
  let s = Double(size)
  let box = CGRect(x: 0, y: 0, width: s, height: s)
  c.saveGState()
  c.addEllipse(in: box)
  c.clip()
  c.setFillColor(cream.cgColor)
  c.fill(box)
  c.restoreGState()

  let stroke = s * 0.135
  let radius = s / 2 - s * 0.055 - stroke / 2
  c.setLineWidth(stroke)
  c.setLineCap(.butt)
  for (colour, from, to) in arcs {
    c.setStrokeColor(colour.cgColor)
    c.beginPath()
    c.addArc(center: CGPoint(x: s / 2, y: s / 2), radius: radius,
             startAngle: from * .pi / 180, endAngle: to * .pi / 180, clockwise: false)
    c.strokePath()
  }
  writePNG(c.makeImage()!, name)
}

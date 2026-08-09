// Derives the hero image and the social card from one master artwork.
//   swift tools/make-images.swift <master.png> <outdir> <fontdir>
// macOS only, no dependencies. See README.

import AppKit
import CoreText
import Foundation

let master = URL(fileURLWithPath: CommandLine.arguments[1])
let outDir = URL(fileURLWithPath: CommandLine.arguments[2])
let fontDir = URL(fileURLWithPath: CommandLine.arguments[3])

func register(_ name: String) {
  CTFontManagerRegisterFontsForURL(fontDir.appendingPathComponent(name) as CFURL, .process, nil)
}
register("Bricolage800.ttf")
register("PlexMono600.ttf")

func font(_ name: String, _ size: CGFloat) -> NSFont {
  NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: .heavy)
}

let cream = NSColor(srgbRed: 0xF7 / 255, green: 0xF2 / 255, blue: 0xE8 / 255, alpha: 1)
let amber = NSColor(srgbRed: 0xE8 / 255, green: 0xA3 / 255, blue: 0x3D / 255, alpha: 1)
let ink = NSColor(srgbRed: 0x12 / 255, green: 0x10 / 255, blue: 0x0D / 255, alpha: 1)

guard let image = NSImage(contentsOf: master),
      let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let source = rep.cgImage else { fatalError("cannot read \(master.path)") }

let sw = CGFloat(source.width), sh = CGFloat(source.height)
print("master: \(Int(sw))x\(Int(sh))")

func ctx(_ w: Int, _ h: Int) -> CGContext {
  let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  c.interpolationQuality = .high
  return c
}
func writeJPEG(_ img: CGImage, _ name: String, _ q: CGFloat) {
  let r = NSBitmapImageRep(cgImage: img)
  let data = r.representation(using: .jpeg, properties: [.compressionFactor: q])!
  try! data.write(to: outDir.appendingPathComponent(name))
  print("  \(name)  \(img.width)x\(img.height)  \(data.count / 1024) kB")
}
func draw(_ s: String, _ f: NSFont, _ colour: NSColor, kern: CGFloat, at p: CGPoint, in c: CGContext) {
  let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: colour, .kern: kern]
  c.textPosition = p
  CTLineDraw(CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs)), c)
}

// ── 1. hero.jpg — the master, re-encoded. A 4 MB PNG is not a hero image.
// 0.58 rather than 0.75: the page lays a heavy dark scrim over this image,
// which hides JPEG artefacts, and 150 kB saved matters more on a phone.
writeJPEG(source, "hero.jpg", 0.58)

// ── 2. og.jpg — 1200x630 social card
// The master is portrait, so a cover crop keeps a horizontal band of it.
// 0.42 from the top lands on the waiting customers' faces, which is the
// whole point of the picture.
let ogW = 1200, ogH = 630
let c = ctx(ogW, ogH)
let scale = max(CGFloat(ogW) / sw, CGFloat(ogH) / sh)
let dw = sw * scale, dh = sh * scale
let focus: CGFloat = 0.42
c.draw(source, in: CGRect(x: (CGFloat(ogW) - dw) / 2,
                          y: CGFloat(ogH) - dh + (dh - CGFloat(ogH)) * (1 - focus),
                          width: dw, height: dh))

let space = CGColorSpace(name: CGColorSpace.sRGB)!
let vertical = CGGradient(colorsSpace: space,
                          colors: [ink.withAlphaComponent(0.97).cgColor,
                                   ink.withAlphaComponent(0.60).cgColor,
                                   ink.withAlphaComponent(0.0).cgColor] as CFArray,
                          locations: [0.0, 0.44, 1.0])!
c.drawLinearGradient(vertical, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 560), options: [])
let horizontal = CGGradient(colorsSpace: space,
                            colors: [ink.withAlphaComponent(0.84).cgColor,
                                     ink.withAlphaComponent(0.0).cgColor] as CFArray,
                            locations: [0.0, 1.0])!
c.drawLinearGradient(horizontal, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 760, y: 0), options: [])

// wordmark, top-left — reads assets/logo.png, so run make-logo.swift first
let side: CGFloat = 86
let badge = CGRect(x: 60, y: CGFloat(ogH) - 44 - side, width: side, height: side)
if let logo = NSImage(contentsOf: outDir.appendingPathComponent("logo.png")),
   let logoTiff = logo.tiffRepresentation,
   let logoCG = NSBitmapImageRep(data: logoTiff)?.cgImage {
  c.draw(logoCG, in: badge)
} else {
  FileHandle.standardError.write("logo.png absent — run make-logo.swift first\n".data(using: .utf8)!)
  c.setFillColor(amber.cgColor)
  c.fillEllipse(in: badge)
}
draw("TASTE OF AFRICA", font("BricolageGrotesque-ExtraBold", 21), cream, kern: 2.4,
     at: CGPoint(x: badge.maxX + 16, y: badge.midY - 7), in: c)

draw("Table 4 is", font("BricolageGrotesque-ExtraBold", 86), cream, kern: -2.4,
     at: CGPoint(x: 62, y: 232), in: c)
draw("still waiting.", font("BricolageGrotesque-ExtraBold", 86), cream, kern: -2.4,
     at: CGPoint(x: 62, y: 138), in: c)
draw("A MOBILE COOKING GAME · COMING SOON", font("IBMPlexMono-SemiBold", 19), amber, kern: 2.6,
     at: CGPoint(x: 64, y: 76), in: c)

writeJPEG(c.makeImage()!, "og.jpg", 0.84)

// The favicon and apple-touch-icon derive from the logo, not from here.
// See tools/make-logo.swift.

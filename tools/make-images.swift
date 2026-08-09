import AVFoundation
import AppKit
import CoreText
import Foundation

// ---- args: <video> <outdir> <fontdir>
let video = URL(fileURLWithPath: CommandLine.arguments[1])
let outDir = URL(fileURLWithPath: CommandLine.arguments[2])
let fontDir = URL(fileURLWithPath: CommandLine.arguments[3])

func register(_ name: String) {
  let u = fontDir.appendingPathComponent(name)
  CTFontManagerRegisterFontsForURL(u as CFURL, .process, nil)
}
register("Bricolage800.ttf")
register("PlexMono600.ttf")

func font(_ name: String, _ size: CGFloat) -> NSFont {
  NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size, weight: .heavy)
}

let cream = NSColor(srgbRed: 0xF7 / 255, green: 0xF2 / 255, blue: 0xE8 / 255, alpha: 1)
let amber = NSColor(srgbRed: 0xE8 / 255, green: 0xA3 / 255, blue: 0x3D / 255, alpha: 1)
let ink = NSColor(srgbRed: 0x12 / 255, green: 0x10 / 255, blue: 0x0D / 255, alpha: 1)

// ---- grab a frame
let asset = AVURLAsset(url: video)
let gen = AVAssetImageGenerator(asset: asset)
gen.appliesPreferredTrackTransform = true
gen.requestedTimeToleranceBefore = .zero
gen.requestedTimeToleranceAfter = .zero
let frame = try! gen.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil)
let fw = CGFloat(frame.width), fh = CGFloat(frame.height)

func writeJPEG(_ img: CGImage, _ name: String, _ q: CGFloat) {
  let rep = NSBitmapImageRep(cgImage: img)
  let data = rep.representation(using: .jpeg, properties: [.compressionFactor: q])!
  try! data.write(to: outDir.appendingPathComponent(name))
  print(name, "\(img.width)x\(img.height)", "\(data.count / 1024)kB")
}
func writePNG(_ img: CGImage, _ name: String) {
  let rep = NSBitmapImageRep(cgImage: img)
  let data = rep.representation(using: .png, properties: [:])!
  try! data.write(to: outDir.appendingPathComponent(name))
  print(name, "\(img.width)x\(img.height)", "\(data.count / 1024)kB")
}
func ctx(_ w: Int, _ h: Int) -> CGContext {
  let c = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
  c.interpolationQuality = .high
  return c
}
func draw(_ s: String, _ f: NSFont, _ color: NSColor, kern: CGFloat, at p: CGPoint, in c: CGContext) {
  let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: color, .kern: kern]
  let line = CTLineCreateWithAttributedString(NSAttributedString(string: s, attributes: attrs))
  c.textPosition = p
  CTLineDraw(line, c)
}

// ---- 1. poster.jpg (native size, light compression)
writeJPEG(frame, "poster.jpg", 0.62)

// ---- 2. og.jpg — 1200x630 social card
let ogW = 1200, ogH = 630
let c = ctx(ogW, ogH)
// cover-crop the frame to 1200x630
let scale = max(CGFloat(ogW) / fw, CGFloat(ogH) / fh)
let dw = fw * scale, dh = fh * scale
c.draw(frame, in: CGRect(x: (CGFloat(ogW) - dw) / 2, y: (CGFloat(ogH) - dh) / 2, width: dw, height: dh))
// scrim: dark from bottom + a left wash so the type always reads
let sp = CGColorSpace(name: CGColorSpace.sRGB)!
let vg = CGGradient(colorsSpace: sp,
                    colors: [ink.withAlphaComponent(0.97).cgColor, ink.withAlphaComponent(0.62).cgColor,
                             ink.withAlphaComponent(0.0).cgColor] as CFArray,
                    locations: [0.0, 0.42, 1.0])!
c.drawLinearGradient(vg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 560), options: [])
let hg = CGGradient(colorsSpace: sp,
                    colors: [ink.withAlphaComponent(0.82).cgColor, ink.withAlphaComponent(0.0).cgColor] as CFArray,
                    locations: [0.0, 1.0])!
c.drawLinearGradient(hg, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 720, y: 0), options: [])

// wordmark, top-left — the real logo badge, so shares look branded.
// Run tools/make-logo.swift first; this reads the logo.png it writes.
let logoSide: CGFloat = 86
let logoRect = CGRect(x: 60, y: CGFloat(ogH) - 44 - logoSide, width: logoSide, height: logoSide)
if let logo = NSImage(contentsOf: outDir.appendingPathComponent("logo.png")),
   let logoTiff = logo.tiffRepresentation,
   let logoCG = NSBitmapImageRep(data: logoTiff)?.cgImage {
  c.draw(logoCG, in: logoRect)
} else {
  FileHandle.standardError.write("logo.png introuvable — run make-logo.swift first\n".data(using: .utf8)!)
  c.setFillColor(amber.cgColor)
  c.fillEllipse(in: logoRect)
}
draw("TASTE OF AFRICA", font("BricolageGrotesque-ExtraBold", 21), cream, kern: 2.4,
     at: CGPoint(x: logoRect.maxX + 16, y: logoRect.midY - 7), in: c)

// headline, bottom-left
draw("Table 4 is", font("BricolageGrotesque-ExtraBold", 86), cream, kern: -2.4, at: CGPoint(x: 62, y: 232), in: c)
draw("still waiting.", font("BricolageGrotesque-ExtraBold", 86), cream, kern: -2.4, at: CGPoint(x: 62, y: 138), in: c)
draw("A MOBILE COOKING GAME · SOFT LAUNCH 2027", font("IBMPlexMono-SemiBold", 19), amber, kern: 2.6,
     at: CGPoint(x: 64, y: 76), in: c)
writeJPEG(c.makeImage()!, "og.jpg", 0.84)

// The favicon and apple-touch-icon are no longer generated here: they derive
// from the logo artwork now. See tools/make-logo.swift.

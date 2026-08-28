#!/usr/bin/env swift
import AppKit
import CoreGraphics

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let s = size / 1024.0

    // 1. App Icon Squircle Background (with macOS continuous corner curvature)
    let inset: CGFloat = 40.0 * s
    let squircleRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius: CGFloat = 224.0 * s
    let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18 * s), blur: 36 * s, color: CGColor(gray: 0, alpha: 0.65))
    ctx.addPath(squirclePath)
    ctx.setFillColor(CGColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Base Gradient
    ctx.saveGState()
    ctx.addPath(squirclePath)
    ctx.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        CGColor(red: 0.14, green: 0.13, blue: 0.12, alpha: 1.0),
        CGColor(red: 0.07, green: 0.06, blue: 0.05, alpha: 1.0)
    ] as CFArray
    let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(bgGradient, start: CGPoint(x: 512 * s, y: 1024 * s), end: CGPoint(x: 512 * s, y: 0), options: [])

    // Ambient glow spots
    ctx.saveGState()
    let mintGlow = CGColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.25)
    ctx.setFillColor(mintGlow)
    ctx.fillEllipse(in: CGRect(x: 180 * s, y: 220 * s, width: 400 * s, height: 400 * s))
    
    let amberGlow = CGColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 0.22)
    ctx.setFillColor(amberGlow)
    ctx.fillEllipse(in: CGRect(x: 460 * s, y: 440 * s, width: 380 * s, height: 380 * s))
    ctx.restoreGState()

    // Inner Hairline Border
    ctx.addPath(squirclePath)
    ctx.setLineWidth(2.5 * s)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 0.12))
    ctx.strokePath()

    // 2. Dual-Orbit Rings (Mint & Amber)
    ctx.saveGState()
    ctx.setLineWidth(14.0 * s)
    ctx.setLineCap(.round)

    // Mint Ring (Left/Bottom Arc)
    let center = CGPoint(x: 512 * s, y: 512 * s)
    let ringRadius: CGFloat = 260.0 * s
    ctx.setStrokeColor(CGColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 0.9))
    ctx.addArc(center: center, radius: ringRadius, startAngle: .pi * 0.7, endAngle: .pi * 1.8, clockwise: false)
    ctx.strokePath()

    // Amber Ring (Right/Top Arc)
    ctx.setStrokeColor(CGColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 0.9))
    ctx.addArc(center: center, radius: ringRadius + 18 * s, startAngle: .pi * 1.7, endAngle: .pi * 0.8, clockwise: false)
    ctx.strokePath()
    ctx.restoreGState()

    // 3. Central Geometric Cursor Mark
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -6 * s), blur: 14 * s, color: CGColor(gray: 0, alpha: 0.5))
    
    let cursorPath = CGMutablePath()
    cursorPath.move(to: CGPoint(x: 390 * s, y: 680 * s))
    cursorPath.addLine(to: CGPoint(x: 390 * s, y: 340 * s))
    cursorPath.addLine(to: CGPoint(x: 640 * s, y: 490 * s))
    cursorPath.addLine(to: CGPoint(x: 510 * s, y: 530 * s))
    cursorPath.closeSubpath()

    // Cursor Fill Gradient (Crisp White to Off-White)
    ctx.addPath(cursorPath)
    ctx.clip()
    let cursorColors = [
        CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0),
        CGColor(red: 0.92, green: 0.90, blue: 0.88, alpha: 1.0)
    ] as CFArray
    let cursorGradient = CGGradient(colorsSpace: colorSpace, colors: cursorColors, locations: [0.0, 1.0])!
    ctx.drawLinearGradient(cursorGradient, start: CGPoint(x: 390 * s, y: 680 * s), end: CGPoint(x: 640 * s, y: 340 * s), options: [])
    ctx.restoreGState()

    ctx.restoreGState() // Clip squircle

    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        return
    }
    try? png.write(to: URL(fileURLWithPath: path))
}

let fm = FileManager.default
let iconsetDir = "AppIcon.iconset"
let resourcesDir = "Resources"
try? fm.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)
try? fm.createDirectory(atPath: resourcesDir, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

print("==> Generating multi-resolution icon assets...")
for (name, size) in sizes {
    let img = drawIcon(size: size)
    savePNG(image: img, path: "\(iconsetDir)/\(name)")
}

// Master 1024x1024 AppIcon.png
let master = drawIcon(size: 1024)
savePNG(image: master, path: "\(resourcesDir)/AppIcon.png")

print("==> Icon generation complete.")

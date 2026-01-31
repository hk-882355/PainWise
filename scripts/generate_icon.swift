#!/usr/bin/swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Icon size
let size = 1024

// Create bitmap context
guard let context = CGContext(
    data: nil,
    width: size,
    height: size,
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

let rect = CGRect(x: 0, y: 0, width: size, height: size)

// Colors
let primaryGreen = CGColor(red: 0.075, green: 0.925, blue: 0.502, alpha: 1.0) // #13ec80
let darkGreen = CGColor(red: 0.039, green: 0.467, blue: 0.251, alpha: 1.0)    // #0a7740
let lightGreen = CGColor(red: 0.298, green: 0.957, blue: 0.631, alpha: 1.0)   // #4cf4a1

// Background gradient
let gradientColors = [lightGreen, primaryGreen, darkGreen] as CFArray
let gradientLocations: [CGFloat] = [0.0, 0.5, 1.0]
guard let gradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: gradientColors,
    locations: gradientLocations
) else {
    print("Failed to create gradient")
    exit(1)
}

// Draw gradient background
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// Draw wave pattern (heart rate style)
context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.3))
context.setLineWidth(8)
context.setLineCap(.round)
context.setLineJoin(.round)

// Wave 1 (upper)
context.beginPath()
let wave1Y = Double(size) * 0.35
context.move(to: CGPoint(x: 0, y: wave1Y))
for x in stride(from: 0, to: size, by: 4) {
    let normalizedX = Double(x) / Double(size)
    let y = wave1Y + sin(normalizedX * .pi * 4) * 30
    context.addLine(to: CGPoint(x: Double(x), y: y))
}
context.strokePath()

// Wave 2 (middle - heartbeat style)
context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.2))
context.setLineWidth(6)
context.beginPath()
let wave2Y = Double(size) * 0.5
context.move(to: CGPoint(x: 0, y: wave2Y))

// Flat line
context.addLine(to: CGPoint(x: Double(size) * 0.2, y: wave2Y))
// Small bump
context.addLine(to: CGPoint(x: Double(size) * 0.25, y: wave2Y - 20))
context.addLine(to: CGPoint(x: Double(size) * 0.28, y: wave2Y))
// Flat
context.addLine(to: CGPoint(x: Double(size) * 0.35, y: wave2Y))
// Big spike (QRS complex)
context.addLine(to: CGPoint(x: Double(size) * 0.38, y: wave2Y + 30))
context.addLine(to: CGPoint(x: Double(size) * 0.42, y: wave2Y - 80))
context.addLine(to: CGPoint(x: Double(size) * 0.46, y: wave2Y + 40))
context.addLine(to: CGPoint(x: Double(size) * 0.50, y: wave2Y))
// Flat
context.addLine(to: CGPoint(x: Double(size) * 0.58, y: wave2Y))
// T wave
context.addLine(to: CGPoint(x: Double(size) * 0.62, y: wave2Y - 25))
context.addLine(to: CGPoint(x: Double(size) * 0.68, y: wave2Y))
// Flat to end
context.addLine(to: CGPoint(x: Double(size), y: wave2Y))
context.strokePath()

// Wave 3 (lower)
context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.15))
context.setLineWidth(4)
context.beginPath()
let wave3Y = Double(size) * 0.65
context.move(to: CGPoint(x: 0, y: wave3Y))
for x in stride(from: 0, to: size, by: 4) {
    let normalizedX = Double(x) / Double(size)
    let y = wave3Y + sin(normalizedX * .pi * 3 + 1) * 25
    context.addLine(to: CGPoint(x: Double(x), y: y))
}
context.strokePath()

// Draw human silhouette (centered)
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))

let centerX = Double(size) / 2
let silhouetteScale = 0.55

// Head
let headRadius = Double(size) * 0.08 * silhouetteScale
let headY = Double(size) * 0.28
let headRect = CGRect(
    x: centerX - headRadius,
    y: Double(size) - headY - headRadius * 2,
    width: headRadius * 2,
    height: headRadius * 2
)
context.fillEllipse(in: headRect)

// Neck
let neckWidth = Double(size) * 0.04 * silhouetteScale
let neckHeight = Double(size) * 0.04 * silhouetteScale
let neckY = headY + headRadius * 2
context.fill(CGRect(
    x: centerX - neckWidth / 2,
    y: Double(size) - neckY - neckHeight,
    width: neckWidth,
    height: neckHeight
))

// Body (torso) - rounded rectangle shape
let torsoWidth = Double(size) * 0.18 * silhouetteScale
let torsoHeight = Double(size) * 0.22 * silhouetteScale
let torsoY = neckY + neckHeight

// Draw torso as path with rounded shoulders
context.beginPath()
let shoulderWidth = torsoWidth * 1.3
let torsoTopY = Double(size) - torsoY
let torsoBottomY = Double(size) - torsoY - torsoHeight

// Start from left hip
context.move(to: CGPoint(x: centerX - torsoWidth / 2, y: torsoBottomY))
// Left side up
context.addLine(to: CGPoint(x: centerX - torsoWidth / 2, y: torsoTopY - torsoHeight * 0.3))
// Left shoulder curve
context.addQuadCurve(
    to: CGPoint(x: centerX - shoulderWidth / 2, y: torsoTopY),
    control: CGPoint(x: centerX - shoulderWidth / 2, y: torsoTopY - torsoHeight * 0.15)
)
// Shoulder line
context.addLine(to: CGPoint(x: centerX + shoulderWidth / 2, y: torsoTopY))
// Right shoulder curve
context.addQuadCurve(
    to: CGPoint(x: centerX + torsoWidth / 2, y: torsoTopY - torsoHeight * 0.3),
    control: CGPoint(x: centerX + shoulderWidth / 2, y: torsoTopY - torsoHeight * 0.15)
)
// Right side down
context.addLine(to: CGPoint(x: centerX + torsoWidth / 2, y: torsoBottomY))
context.closePath()
context.fillPath()

// Arms
let armWidth = Double(size) * 0.035 * silhouetteScale
let armLength = Double(size) * 0.18 * silhouetteScale
let armY = torsoY + torsoHeight * 0.1

// Left arm
context.beginPath()
context.move(to: CGPoint(x: centerX - shoulderWidth / 2, y: Double(size) - armY))
context.addLine(to: CGPoint(x: centerX - shoulderWidth / 2 - armLength * 0.5, y: Double(size) - armY - armLength))
context.setLineWidth(armWidth)
context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
context.strokePath()

// Right arm
context.beginPath()
context.move(to: CGPoint(x: centerX + shoulderWidth / 2, y: Double(size) - armY))
context.addLine(to: CGPoint(x: centerX + shoulderWidth / 2 + armLength * 0.5, y: Double(size) - armY - armLength))
context.strokePath()

// Legs
let legWidth = Double(size) * 0.045 * silhouetteScale
let legLength = Double(size) * 0.25 * silhouetteScale
let legY = torsoY + torsoHeight
let legSpacing = Double(size) * 0.04 * silhouetteScale

// Left leg
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
context.fill(CGRect(
    x: centerX - legSpacing - legWidth,
    y: Double(size) - legY - legLength,
    width: legWidth,
    height: legLength
))

// Right leg
context.fill(CGRect(
    x: centerX + legSpacing,
    y: Double(size) - legY - legLength,
    width: legWidth,
    height: legLength
))

// Create image from context
guard let cgImage = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

// Save to file
let outputPath = "PainWise/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let outputURL = URL(fileURLWithPath: outputPath)

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    print("Failed to create image destination")
    exit(1)
}

CGImageDestinationAddImage(destination, cgImage, nil)

if CGImageDestinationFinalize(destination) {
    print("✅ App icon created: \(outputPath)")
} else {
    print("Failed to save image")
    exit(1)
}

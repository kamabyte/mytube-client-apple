#!/usr/bin/env swift
//
//  GenerateBrandAssets.swift
//  MyTube — tvOS
//
//  Renders every asset inside `MyTube/Assets.xcassets/Brand Assets.brandassets` from code.
//
//  The MyTube mark is defined as vector source on the Android TV client
//  (`app/src/main/res/drawable/ic_launcher_*.xml`). tvOS has no vector equivalent for brand
//  assets — the layered app icon and the top shelf images must be shipped as PNGs at fixed
//  sizes — so this script is the tvOS counterpart of those XML files: the mark lives here as
//  geometry, and the PNGs in the asset catalog are build output that can be regenerated.
//
//  Run from the client root:
//
//      swift Tools/GenerateBrandAssets.swift
//
//  The mark: a rounded tile carrying the sunset gradient (magenta bottom-left → pink →
//  coral top-right), a white wedge cutting the bottom-right corner, a diagonal sheen, and a
//  white play glyph — with the "MyTube" wordmark set alongside it, exactly as on the Android
//  TV banner. On tvOS the lockup is split across the three parallax layers of an image stack:
//  backdrop on Back, tile on Middle, glyph and wordmark on Front.
//

import AppKit
import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

// MARK: - Brand palette

func srgb(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
        green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255,
        alpha: alpha
    )
}

enum Brand {
    /// Sunset gradient, running bottom-left → top-right across the tile.
    static let magenta = srgb(0xB4_22_9A)
    static let pink = srgb(0xFF_3E_6E)
    static let coral = srgb(0xFF_7E_45)

    /// Backdrop, matching the dark plum of the Android TV banner.
    static let backdropTop = srgb(0x1B_15_26)
    static let backdropBottom = srgb(0x0C_0A_12)

    static let wordmark = "MyTube"
}

// MARK: - Layout

/// Proportions of the mark + wordmark lockup, all expressed as a fraction of the canvas height
/// so a single description renders at every required pixel size.
struct LockupStyle {
    var tileSide: CGFloat
    var gap: CGFloat
    var fontSize: CGFloat

    /// App icon: the lockup nearly fills the 5:3 canvas.
    static let appIcon = LockupStyle(tileSide: 0.46, gap: 0.09, fontSize: 0.225)
    /// Top shelf: a much wider canvas, so the lockup sits smaller and centred.
    static let topShelf = LockupStyle(tileSide: 0.40, gap: 0.075, fontSize: 0.195)
}

/// Which parallax layer of an image stack is being drawn (`flat` composites all three).
enum Layer {
    case back, middle, front, flat

    var drawsBackdrop: Bool { self == .back || self == .flat }
    var drawsTile: Bool { self == .middle || self == .flat }
    var drawsForeground: Bool { self == .front || self == .flat }
}

// MARK: - Geometry helpers

func roundedRectPath(_ rect: CGRect, radius: CGFloat) -> CGPath {
    CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
}

/// Triangle with softened corners — used for the play glyph so it matches the tile's rounding.
func roundedTrianglePath(_ points: [CGPoint], radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let start = CGPoint(
        x: (points[0].x + points[1].x) / 2,
        y: (points[0].y + points[1].y) / 2
    )
    path.move(to: start)
    path.addArc(tangent1End: points[1], tangent2End: points[2], radius: radius)
    path.addArc(tangent1End: points[2], tangent2End: points[0], radius: radius)
    path.addArc(tangent1End: points[0], tangent2End: points[1], radius: radius)
    path.closeSubpath()
    return path
}

func gradient(_ colors: [CGColor], _ locations: [CGFloat]) -> CGGradient {
    CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        colors: colors as CFArray,
        locations: locations
    )!
}

// MARK: - Drawing

/// Full-bleed plum backdrop plus a soft brand glow sitting under the tile.
func drawBackdrop(in ctx: CGContext, canvas: CGRect, tile: CGRect) {
    ctx.saveGState()
    ctx.clip(to: canvas)
    ctx.drawLinearGradient(
        gradient([Brand.backdropBottom, Brand.backdropTop], [0, 1]),
        start: CGPoint(x: canvas.maxX, y: canvas.minY),
        end: CGPoint(x: canvas.minX, y: canvas.maxY),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )

    let glowCenter = CGPoint(x: tile.midX, y: tile.midY)
    ctx.drawRadialGradient(
        gradient(
            [
                Brand.pink.copy(alpha: 0.22)!,
                Brand.magenta.copy(alpha: 0.10)!,
                Brand.magenta.copy(alpha: 0)!,
            ],
            [0, 0.55, 1]
        ),
        startCenter: glowCenter,
        startRadius: 0,
        endCenter: glowCenter,
        endRadius: tile.width * 1.15,
        options: []
    )
    ctx.restoreGState()
}

/// The gradient tile: sunset fill, white corner wedge, diagonal sheen — no glyph.
func drawTile(in ctx: CGContext, tile: CGRect) {
    let side = tile.width
    let corner = side * 0.225
    let shape = roundedRectPath(tile, radius: corner)

    // Drop the tile onto the backdrop before painting it, so the shadow never tints the fill.
    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -side * 0.05),
        blur: side * 0.14,
        color: srgb(0x00_00_00, alpha: 0.5)
    )
    ctx.addPath(shape)
    ctx.setFillColor(srgb(0x00_00_00))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(shape)
    ctx.clip()

    // Sunset gradient, bottom-left → top-right.
    ctx.drawLinearGradient(
        gradient([Brand.magenta, Brand.pink, Brand.coral], [0, 0.48, 1]),
        start: CGPoint(x: tile.minX, y: tile.minY),
        end: CGPoint(x: tile.maxX, y: tile.maxY),
        options: []
    )

    // White wedge slicing the bottom-right corner.
    let wedge = CGMutablePath()
    wedge.move(to: CGPoint(x: tile.minX + side * 0.44, y: tile.minY))
    wedge.addLine(to: CGPoint(x: tile.maxX, y: tile.minY))
    wedge.addLine(to: CGPoint(x: tile.maxX, y: tile.minY + side * 0.56))
    wedge.closeSubpath()
    ctx.addPath(wedge)
    ctx.setFillColor(srgb(0xFF_FF_FF))
    ctx.fillPath()

    // Sheen over the half above the top-left → bottom-right diagonal, for depth.
    ctx.saveGState()
    let sheen = CGMutablePath()
    sheen.move(to: CGPoint(x: tile.minX, y: tile.maxY))
    sheen.addLine(to: CGPoint(x: tile.maxX, y: tile.maxY))
    sheen.addLine(to: CGPoint(x: tile.maxX, y: tile.minY))
    sheen.closeSubpath()
    ctx.addPath(sheen)
    ctx.clip()
    ctx.drawLinearGradient(
        gradient(
            [srgb(0xFF_FF_FF, alpha: 0), srgb(0xFF_FF_FF, alpha: 0.16)],
            [0.5, 1]
        ),
        start: CGPoint(x: tile.minX, y: tile.minY),
        end: CGPoint(x: tile.maxX, y: tile.maxY),
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
    ctx.restoreGState()

    ctx.restoreGState()
}

/// White play glyph, positioned relative to the tile it belongs to (it lives on the Front
/// layer, so parallax slides it across the tile on focus).
func drawPlayGlyph(in ctx: CGContext, tile: CGRect) {
    let side = tile.width
    let left = tile.minX + side * 0.385
    let right = tile.minX + side * 0.685
    let top = tile.minY + side * 0.665
    let bottom = tile.minY + side * 0.335

    let glyph = roundedTrianglePath(
        [
            CGPoint(x: left, y: top),
            CGPoint(x: right, y: tile.midY),
            CGPoint(x: left, y: bottom),
        ],
        radius: side * 0.035
    )

    ctx.saveGState()
    ctx.setShadow(
        offset: CGSize(width: 0, height: -side * 0.012),
        blur: side * 0.05,
        color: srgb(0x00_00_00, alpha: 0.28)
    )
    ctx.addPath(glyph)
    ctx.setFillColor(srgb(0xFF_FF_FF))
    ctx.fillPath()
    ctx.restoreGState()
}

func wordmarkLine(fontSize: CGFloat) -> CTLine {
    // SF Pro Display Bold is the Apple counterpart of the Roboto Bold wordmark on Android TV.
    let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
    let attributed = NSAttributedString(
        string: Brand.wordmark,
        attributes: [
            .font: font,
            .foregroundColor: NSColor.white,
            .kern: -fontSize * 0.022,
        ]
    )
    return CTLineCreateWithAttributedString(attributed)
}

func wordmarkBounds(_ line: CTLine) -> CGRect {
    CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
}

/// Renders one layer of the lockup at `size`.
func renderLayer(_ layer: Layer, size: CGSize, style: LockupStyle) -> CGImage {
    guard
        let ctx = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    else {
        fatalError("Could not create a \(Int(size.width))×\(Int(size.height)) bitmap context")
    }

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)
    ctx.interpolationQuality = .high
    ctx.textMatrix = .identity

    let canvas = CGRect(origin: .zero, size: size)

    // Lay the mark and the wordmark out as one horizontally centred group.
    let tileSide = size.height * style.tileSide
    let gap = size.height * style.gap
    let line = wordmarkLine(fontSize: size.height * style.fontSize)
    let textBounds = wordmarkBounds(line)

    let groupWidth = tileSide + gap + textBounds.width
    let originX = (size.width - groupWidth) / 2
    let tile = CGRect(
        x: originX,
        y: (size.height - tileSide) / 2,
        width: tileSide,
        height: tileSide
    )

    if layer.drawsBackdrop {
        drawBackdrop(in: ctx, canvas: canvas, tile: tile)
    }
    if layer.drawsTile {
        drawTile(in: ctx, tile: tile)
    }
    if layer.drawsForeground {
        drawPlayGlyph(in: ctx, tile: tile)

        // Optically centre the wordmark's glyph box on the tile, not its typographic line box.
        ctx.textPosition = CGPoint(
            x: tile.maxX + gap - textBounds.minX,
            y: tile.midY - textBounds.midY
        )
        CTLineDraw(line, ctx)
    }

    guard let image = ctx.makeImage() else {
        fatalError("Could not snapshot the \(Int(size.width))×\(Int(size.height)) context")
    }
    return image
}

// MARK: - Output

func writePNG(_ image: CGImage, to url: URL) {
    try? FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard
        let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        )
    else {
        fatalError("Could not open \(url.path) for writing")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not finalise \(url.path)")
    }
}

struct Output {
    var path: String
    var size: CGSize
    var layer: Layer
    var style: LockupStyle
}

let brandAssets = "MyTube/Assets.xcassets/Brand Assets.brandassets"
let appIconStack = "\(brandAssets)/App Icon.imagestack"
let appStoreStack = "\(brandAssets)/App Icon - App Store.imagestack"

/// App icon layers: 400×240 @1x / 800×480 @2x, and the 1280×768 App Store stack.
func appIconOutputs() -> [Output] {
    let layers: [(Layer, String)] = [(.back, "back"), (.middle, "middle"), (.front, "front")]
    var outputs: [Output] = []

    for (layer, name) in layers {
        let folder = "\(appIconStack)/\(name.capitalized).imagestacklayer/Content.imageset"
        outputs.append(
            Output(
                path: "\(folder)/icon-\(name).png",
                size: CGSize(width: 400, height: 240),
                layer: layer,
                style: .appIcon
            )
        )
        outputs.append(
            Output(
                path: "\(folder)/icon-\(name)@2x.png",
                size: CGSize(width: 800, height: 480),
                layer: layer,
                style: .appIcon
            )
        )

        let storeFolder = "\(appStoreStack)/\(name.capitalized).imagestacklayer/Content.imageset"
        outputs.append(
            Output(
                path: "\(storeFolder)/appstore-\(name).png",
                size: CGSize(width: 1280, height: 768),
                layer: layer,
                style: .appIcon
            )
        )
    }
    return outputs
}

/// Top shelf images are flat — no parallax — so all three layers are composited.
func topShelfOutputs() -> [Output] {
    [
        Output(
            path: "\(brandAssets)/Top Shelf Image.imageset/top-shelf.png",
            size: CGSize(width: 1920, height: 720),
            layer: .flat,
            style: .topShelf
        ),
        Output(
            path: "\(brandAssets)/Top Shelf Image.imageset/top-shelf@2x.png",
            size: CGSize(width: 3840, height: 1440),
            layer: .flat,
            style: .topShelf
        ),
        Output(
            path: "\(brandAssets)/Top Shelf Image Wide.imageset/top-shelf-wide.png",
            size: CGSize(width: 2320, height: 720),
            layer: .flat,
            style: .topShelf
        ),
        Output(
            path: "\(brandAssets)/Top Shelf Image Wide.imageset/top-shelf-wide@2x.png",
            size: CGSize(width: 4640, height: 1440),
            layer: .flat,
            style: .topShelf
        ),
    ]
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
guard FileManager.default.fileExists(atPath: root.appendingPathComponent(brandAssets).path) else {
    FileHandle.standardError.write(
        Data("Run this from the client root (the folder containing MyTube.xcodeproj).\n".utf8)
    )
    exit(1)
}

for output in appIconOutputs() + topShelfOutputs() {
    let image = renderLayer(output.layer, size: output.size, style: output.style)
    writePNG(image, to: root.appendingPathComponent(output.path))
    print("• \(output.path) — \(Int(output.size.width))×\(Int(output.size.height))")
}

import SpriteKit
import AppKit

final class GameScene: SKScene {

    // MARK: - Config
    // R scales with scene size so hexes look right in both preview and fullscreen
    private var R: CGFloat { min(size.width, size.height) / 10.0 }
    private let gap: CGFloat = 1.0

    private var drawR:   CGFloat { R - gap / sqrt(3.0) }
    private var colStep: CGFloat { sqrt(3.0) * R }
    private var rowStep: CGFloat { 1.5 * R }

    private let growMin:  Double = 0.2;  private let growMax:  Double = 3.5
    private let holdMin:  Double = 3.0;  private let holdMax:  Double = 8.0
    private let fadeMin:  Double = 0.3;  private let fadeMax:  Double = 2.5
    private let spawnMin: Double = 0.02; private let spawnMax: Double = 0.6

    private let fallbackPalette: [NSColor] = [
        NSColor(red: 0.55, green: 0.82, blue: 0.95, alpha: 1),
        NSColor(red: 0.65, green: 0.88, blue: 0.98, alpha: 1),
        NSColor(red: 0.80, green: 0.93, blue: 1.00, alpha: 1),
        NSColor(red: 0.90, green: 0.96, blue: 1.00, alpha: 1),
        NSColor(red: 0.40, green: 0.72, blue: 0.90, alpha: 1),
        NSColor(red: 0.30, green: 0.58, blue: 0.80, alpha: 1),
    ]

    private var stickerTextures: [SKTexture] = []
    private var gridCells:       [CGPoint]   = []
    private var occupiedCells:   Set<Int>    = []

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        anchorPoint = .zero
        backgroundColor = NSColor(red: 0.090, green: 0.129, blue: 0.169, alpha: 1)
        loadStickerTextures()
        buildGrid()
        addGradientBackground()
        spawnDust(count: 55)
        scheduleNextHex()
    }

    // MARK: - Sticker Loading
    //
    // HOW TO ADD THE STICKERS FOLDER IN XCODE:
    //
    //   1. In Xcode's Project Navigator, right-click your target group
    //      and choose "Add Files to <project>…"
    //   2. Select your 'stickers' folder.
    //   3. IMPORTANT: in the dialog, choose "Create folder reference" (blue folder).
    //      Do NOT choose "Create groups" (yellow folder) — that loses the folder name.
    //   4. Tick "Copy items if needed" and your app target.
    //   5. Clean build (⇧⌘K) and run.
    //
    // The stickers folder can also be a subfolder anywhere on disk — just point
    // `customStickersPath` below to its absolute path for development.
    //
    private let customStickersPath: String? = nil  // e.g. "/Users/you/Desktop/stickers"

    private func loadStickerTextures() {
        let urls = findStickerURLs()
        guard !urls.isEmpty else {
                return
        }
        for url in urls {
            guard let image = NSImage(contentsOf: url) else { continue }
            let masked = hexMaskedImage(image, radius: drawR)
            stickerTextures.append(SKTexture(image: masked))
        }
    }

    private func findStickerURLs() -> [URL] {
        let bundle = Bundle(for: GameScene.self)

        // 1. Custom absolute path override
        if let custom = customStickersPath {
            let found = pngURLs(in: URL(fileURLWithPath: custom))
            if !found.isEmpty { return found }
        }

        // 2. Flat PNGs in Resources/ (Xcode group — most common screensaver layout)
        let flat = bundle.urls(forResourcesWithExtension: "png", subdirectory: nil) ?? []
        if !flat.isEmpty { return flat }

        // 3. PNGs inside a "stickers" subfolder
        let inStickers = bundle.urls(forResourcesWithExtension: "png", subdirectory: "stickers") ?? []
        if !inStickers.isEmpty { return inStickers }

        // 4. FileManager scan of resourcePath
        if let resourcePath = bundle.resourcePath {
            let found = pngURLs(in: URL(fileURLWithPath: resourcePath))
            if !found.isEmpty { return found }
        }

        return []
    }

    private func pngURLs(in directory: URL) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ))?.filter { $0.pathExtension.lowercased() == "png" } ?? []
    }

    /// Clips image to a flat-top hex shape centred in a (2R × 2R) canvas.
    private func hexMaskedImage(_ source: NSImage, radius: CGFloat) -> NSImage {
        let size   = CGSize(width: radius * 2, height: radius * 2)
        let result = NSImage(size: size)
        result.lockFocus()
        defer { result.unlockFocus() }
        guard let ctx = NSGraphicsContext.current?.cgContext else { return source }

        let cx = radius, cy = radius
        ctx.beginPath()
        for i in 0..<6 {
            let a  = CGFloat(i) * .pi / 3.0 + .pi / 6.0  // +30° = pointy-top
            let pt = CGPoint(x: cx + radius * cos(a), y: cy + radius * sin(a))
            i == 0 ? ctx.move(to: pt) : ctx.addLine(to: pt)
        }
        ctx.closePath()
        ctx.clip()

        source.draw(in: CGRect(origin: .zero, size: size),
                    from: .zero, operation: .sourceOver, fraction: 1.0)
        return result
    }

    // MARK: - Grid (column-based flat-top)
    private func buildGrid() {
        gridCells.removeAll()
        occupiedCells.removeAll()
        // Pointy-top hex: row-based layout
        //   col step x = sqrt(3) * R
        //   row step y = 1.5 * R
        //   odd rows offset x by sqrt(3)/2 * R
        var row = 0
        var y   = R
        while y < size.height + R {
            let xOff = (row % 2 == 1) ? colStep / 2.0 : 0.0
            var x    = R + xOff
            while x < size.width + R {
                gridCells.append(CGPoint(x: x, y: y))
                x += colStep
            }
            y   += rowStep
            row += 1
        }
    }

    // MARK: - Background
    private func addGradientBackground() {
        let colors: [CGColor] = [
            NSColor(red: 0.06, green: 0.10, blue: 0.14, alpha: 1).cgColor,
            NSColor(red: 0.09, green: 0.13, blue: 0.17, alpha: 1).cgColor,
            NSColor(red: 0.12, green: 0.17, blue: 0.22, alpha: 1).cgColor,
        ]
        guard let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors as CFArray,
                                    locations: [0, 0.45, 1]) else { return }
        let img = NSImage(size: size)
        img.lockFocus()
        NSGraphicsContext.current?.cgContext.drawLinearGradient(
            grad, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        img.unlockFocus()
        let bg       = SKSpriteNode(texture: SKTexture(image: img))
        bg.position  = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.size      = size
        bg.zPosition = -10
        addChild(bg)
    }

    // MARK: - Dust
    private func spawnDust(count: Int) {
        for _ in 0..<count {
            let dot         = SKShapeNode(circleOfRadius: .random(in: 0.8...2.5))
            dot.fillColor   = .white
            dot.strokeColor = .clear
            dot.alpha       = 0
            dot.position    = randomPoint()
            dot.zPosition   = 6
            addChild(dot)
            loopDust(dot)
        }
    }

    private func loopDust(_ node: SKShapeNode) {
        let dur  = Double.random(in: 8...22)
        let dest = CGPoint(x: node.position.x + .random(in: -60...60),
                           y: node.position.y + .random(in: 20...120))
        node.run(.sequence([
            .group([
                .move(to: dest, duration: dur),
                .sequence([
                    .fadeAlpha(to: .random(in: 0.2...0.6), duration: dur * 0.3),
                    .wait(forDuration: dur * 0.4),
                    .fadeOut(withDuration: dur * 0.3)
                ])
            ]),
            .run { [weak self, weak node] in
                guard let self, let node else { return }
                node.position = self.randomPoint()
                self.loopDust(node)
            }
        ]))
    }

    // MARK: - Spawning
    private func scheduleNextHex() {
        run(.sequence([
            .wait(forDuration: .random(in: spawnMin...spawnMax)),
            .run { [weak self] in
                self?.trySpawn()
                self?.scheduleNextHex()
            }
        ]))
    }

    private func trySpawn() {
        let free = gridCells.indices.filter { !occupiedCells.contains($0) }
        guard let idx = free.randomElement() else { return }
        occupiedCells.insert(idx)
        spawnHex(at: gridCells[idx], idx: idx)
    }

    private func spawnHex(at center: CGPoint, idx: Int) {
        let alpha = CGFloat.random(in: 0.55...1.0)
        let node: SKNode

        if !stickerTextures.isEmpty {
            let texture  = stickerTextures.randomElement()!
            let sprite   = SKSpriteNode(texture: texture)
            sprite.size  = CGSize(width: drawR * 2, height: drawR * 2)
            sprite.alpha = alpha
            let border   = makeHexBorder(radius: drawR)
            border.zPosition = 1
            sprite.addChild(border)
            node = sprite
        } else {
            node = makeHexShape(radius: drawR,
                                color: fallbackPalette.randomElement()!,
                                alpha: alpha)
        }

        node.position  = center
        node.zPosition = 1
        node.setScale(0.01)
        node.alpha     = 0
        addChild(node)

        let gDur = Double.random(in: growMin...growMax)
        let hDur = Double.random(in: holdMin...holdMax)
        let fDur = Double.random(in: fadeMin...fadeMax)
        let grow = SKAction.scale(to: 1.0, duration: gDur)
        grow.timingMode = .easeOut

        node.run(.sequence([
            .group([grow, .fadeAlpha(to: alpha, duration: gDur * 0.7)]),
            .wait(forDuration: hDur),
            .fadeOut(withDuration: fDur),
            .run { [weak self] in self?.occupiedCells.remove(idx) },
            .removeFromParent()
        ]))
    }

    // MARK: - Hex helpers
    private func makeHexShape(radius: CGFloat, color: NSColor, alpha: CGFloat) -> SKShapeNode {
        let path = hexPath(radius: radius)
        let node         = SKShapeNode(path: path)
        node.fillColor   = color.withAlphaComponent(alpha)
        node.strokeColor = color.withAlphaComponent(min(alpha + 0.3, 1.0))
        node.lineWidth   = 2.0
        node.glowWidth   = 0
        return node
    }

    private func makeHexBorder(radius: CGFloat) -> SKShapeNode {
        let node         = SKShapeNode(path: hexPath(radius: radius))
        node.fillColor   = .clear
        node.strokeColor = NSColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 0.85)
        node.lineWidth   = 2.0
        node.glowWidth   = 0
        return node
    }

    private func hexPath(radius: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            let a  = CGFloat(i) * .pi / 3.0 + .pi / 6.0  // +30° = pointy-top
            let pt = CGPoint(x: radius * cos(a), y: radius * sin(a))
            i == 0 ? path.move(to: pt) : path.addLine(to: pt)
        }
        path.closeSubpath()
        return path
    }

    private func randomPoint() -> CGPoint {
        CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height))
    }
}

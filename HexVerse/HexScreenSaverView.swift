import ScreenSaver
import SpriteKit

final class HexScreenSaverView: ScreenSaverView {

    private var skView: SKView?
    private var presented = false

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 0.09, green: 0.13, blue: 0.17, alpha: 1).cgColor

        let v = SKView(frame: bounds)
        v.autoresizingMask = [.width, .height]
        v.ignoresSiblingOrder = true
        v.showsFPS = false
        v.showsNodeCount = false
        addSubview(v)
        skView = v
    }

    private func presentSceneIfNeeded() {
        guard !presented else { return }
        guard let sv = skView, sv.bounds.width > 0, sv.bounds.height > 0 else {
                return
        }
        presented = true
        let scene = GameScene(size: sv.bounds.size)
        scene.scaleMode = .resizeFill
        sv.presentScene(scene)

    }

    override func startAnimation() {
        super.startAnimation()
        presentSceneIfNeeded()
    }

    override func stopAnimation() {
        super.stopAnimation()
        presented = false
        skView?.presentScene(nil)
    }

    override func animateOneFrame() {
        if !presented { presentSceneIfNeeded() }
    }

    override func viewDidMoveToWindow() {
        presentSceneIfNeeded()
    }

    override func layout() {
        super.layout()
        presentSceneIfNeeded()
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }

}

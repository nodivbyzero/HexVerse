import SpriteKit
import AppKit

/// SKView subclass that presents a fresh GameScene once it has a valid size,
/// and re-presents on window resize (debounced 150ms).
/// Used by both the app (via ParticleBackgroundView) and the screensaver.
final class LayoutSKView: SKView {

    private var lastSize: CGSize = .zero
    private var resizeTimer: Timer?

    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        showsFPS        = false
        showsNodeCount  = false
        ignoresSiblingOrder = true
    }

    override func layout() {
        super.layout()
        guard bounds.width > 0, bounds.height > 0 else { return }

        if lastSize == .zero {
            lastSize = bounds.size
            presentNewScene(size: bounds.size)
            return
        }

        guard bounds.size != lastSize else { return }
        resizeTimer?.invalidate()
        resizeTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.lastSize = self.bounds.size
            self.presentNewScene(size: self.bounds.size)
        }
    }

    private func presentNewScene(size: CGSize) {
        let scene = GameScene(size: size)
        scene.scaleMode = .resizeFill
        presentScene(scene, transition: SKTransition.fade(withDuration: 0.25))
    }
}

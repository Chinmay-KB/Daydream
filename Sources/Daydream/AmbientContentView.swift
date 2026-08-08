import AppKit

final class AmbientContentView: NSView {
    var onDismiss: (() -> Void)?

    private let titleLabel = NSTextField(labelWithString: "Daydream")
    private let subtitleLabel = NSTextField(labelWithString: "Click or Esc to dismiss · Click this display's menu bar icon to toggle")
    private let clockLabel = NSTextField(labelWithString: "")
    private var clockTimer: Timer?
    private let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE d MMM  HH:mm:ss"
        return formatter
    }()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        configureLabels()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start() {
        updateClock()
        clockTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateClock()
        }
    }

    func stop() {
        clockTimer?.invalidate()
        clockTimer = nil
    }

    override func layout() {
        super.layout()

        let width = bounds.width
        let height = bounds.height
        let centerY = height * 0.5

        titleLabel.frame = NSRect(x: 0, y: centerY + 12, width: width, height: 44)
        subtitleLabel.frame = NSRect(x: 0, y: centerY - 24, width: width, height: 24)
        clockLabel.frame = NSRect(x: 0, y: centerY - 72, width: width, height: 28)
    }

    override func mouseDown(with event: NSEvent) {
        onDismiss?()
    }

    private func configureLabels() {
        for label in [titleLabel, subtitleLabel, clockLabel] {
            label.alignment = .center
            label.textColor = .white
            label.backgroundColor = .clear
            label.isBezeled = false
            label.isEditable = false
            label.isSelectable = false
            addSubview(label)
        }

        titleLabel.font = NSFont.systemFont(ofSize: 36, weight: .medium)
        subtitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        subtitleLabel.textColor = NSColor.white.withAlphaComponent(0.65)
        clockLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .regular)
        clockLabel.textColor = NSColor.white.withAlphaComponent(0.85)
    }

    private func updateClock() {
        clockLabel.stringValue = clockFormatter.string(from: Date())
    }
}

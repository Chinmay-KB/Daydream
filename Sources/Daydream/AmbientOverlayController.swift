import AppKit
import CoreGraphics

final class AmbientWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AmbientOverlayController {
    var onStateChange: (() -> Void)?

    private var window: NSWindow?
    private var escapeMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    var isEnabled: Bool { window != nil }

    func enable() {
        guard window == nil else { return }

        guard let screen = builtinScreen() else {
            presentAlert(
                title: "No Built-in Display",
                message: "Daydream could not find the MacBook built-in screen. Is the lid closed?"
            )
            return
        }

        let contentView = AmbientContentView(frame: screen.frame)
        contentView.onDismiss = { [weak self] in
            self?.disable()
        }

        let overlayWindow = AmbientWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        overlayWindow.isOpaque = true
        overlayWindow.backgroundColor = .black
        overlayWindow.level = .screenSaver
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        overlayWindow.isReleasedWhenClosed = false
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.contentView = contentView
        overlayWindow.setFrame(screen.frame, display: true)
        overlayWindow.makeKeyAndOrderFront(nil)

        window = overlayWindow
        contentView.start()
        installEscapeMonitor()
        observeScreenChanges()
        onStateChange?()
    }

    func disable() {
        guard let window else { return }

        if let contentView = window.contentView as? AmbientContentView {
            contentView.stop()
        }
        window.orderOut(nil)
        self.window = nil
        removeEscapeMonitor()
        removeScreenObserver()
        onStateChange?()
    }

    private func builtinScreen() -> NSScreen? {
        NSScreen.screens.first { screen in
            guard
                let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            else {
                return false
            }
            return CGDisplayIsBuiltin(displayID.uint32Value) != 0
        }
    }

    private func installEscapeMonitor() {
        removeEscapeMonitor()
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.disable()
                return nil
            }
            return event
        }
    }

    private func removeEscapeMonitor() {
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
    }

    private func observeScreenChanges() {
        removeScreenObserver()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleScreenChange()
        }
    }

    private func removeScreenObserver() {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
    }

    private func handleScreenChange() {
        guard let window else { return }

        guard let screen = builtinScreen() else {
            disable()
            return
        }

        window.setFrame(screen.frame, display: true)
    }

    private func presentAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.runModal()
    }
}

import AppKit

final class AmbientWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class AmbientOverlayController {
    private struct Session {
        let window: AmbientWindow
        let contentView: AmbientContentView
        let displayID: CGDirectDisplayID
    }

    var onStateChange: (() -> Void)?

    private var session: Session?
    private var escapeMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    var isEnabled: Bool { session != nil }

    func toggle(on screen: NSScreen) {
        guard let displayID = screen.displayID else { return }

        if session?.displayID == displayID {
            disable()
            return
        }

        if let session {
            move(session, to: screen, displayID: displayID)
            return
        }

        present(on: screen, displayID: displayID)
    }

    func disable() {
        guard let session else { return }

        session.contentView.stop()
        session.window.orderOut(nil)
        self.session = nil
        removeEscapeMonitor()
        removeScreenObserver()
        onStateChange?()
    }

    private func present(on screen: NSScreen, displayID: CGDirectDisplayID) {
        let frame = screen.visibleFrame
        let contentView = AmbientContentView(frame: NSRect(origin: .zero, size: frame.size))
        contentView.autoresizingMask = [.width, .height]
        contentView.onDismiss = { [weak self] in
            self?.disable()
        }

        let overlayWindow = AmbientWindow(
            contentRect: frame,
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
        overlayWindow.setFrame(frame, display: true)
        overlayWindow.makeKeyAndOrderFront(nil)

        session = Session(window: overlayWindow, contentView: contentView, displayID: displayID)
        contentView.start()
        installEscapeMonitor()
        observeScreenChanges()
        onStateChange?()
    }

    private func move(_ session: Session, to screen: NSScreen, displayID: CGDirectDisplayID) {
        session.window.setFrame(screen.visibleFrame, display: true)
        self.session = Session(
            window: session.window,
            contentView: session.contentView,
            displayID: displayID
        )
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
        guard let session else { return }

        guard let screen = NSScreen.screens.first(where: { $0.displayID == session.displayID }) else {
            disable()
            return
        }

        session.window.setFrame(screen.visibleFrame, display: true)
    }
}

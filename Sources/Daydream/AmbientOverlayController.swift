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

    private var sessions: [CGDirectDisplayID: Session] = [:]
    private var escapeMonitor: Any?
    private var screenObserver: NSObjectProtocol?

    var isEnabled: Bool { !sessions.isEmpty }

    func toggle(on screen: NSScreen) {
        guard let displayID = screen.displayID else { return }

        if sessions[displayID] != nil {
            disable(displayID: displayID)
            return
        }

        present(on: screen, displayID: displayID)
    }

    func disable() {
        let displayIDs = Array(sessions.keys)
        guard !displayIDs.isEmpty else { return }

        for displayID in displayIDs {
            tearDownSession(displayID: displayID)
        }
        removeEscapeMonitor()
        removeScreenObserver()
        onStateChange?()
    }

    private func disable(displayID: CGDirectDisplayID) {
        guard sessions[displayID] != nil else { return }

        tearDownSession(displayID: displayID)
        if sessions.isEmpty {
            removeEscapeMonitor()
            removeScreenObserver()
        }
        onStateChange?()
    }

    private func tearDownSession(displayID: CGDirectDisplayID) {
        guard let session = sessions.removeValue(forKey: displayID) else { return }
        session.contentView.onDismiss = nil
        session.contentView.stop()
        session.window.orderOut(nil)
        session.window.close()
    }

    private func present(on screen: NSScreen, displayID: CGDirectDisplayID) {
        let frame = screen.visibleFrame
        let contentView = AmbientContentView(frame: NSRect(origin: .zero, size: frame.size))
        contentView.autoresizingMask = [.width, .height]
        contentView.onDismiss = { [weak self] in
            self?.disable(displayID: displayID)
        }

        let overlayWindow = AmbientWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        overlayWindow.isOpaque = false
        overlayWindow.backgroundColor = .clear
        overlayWindow.hasShadow = false
        overlayWindow.level = .screenSaver
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        overlayWindow.isReleasedWhenClosed = false
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.contentView = contentView
        overlayWindow.setFrame(frame, display: true)
        overlayWindow.makeKeyAndOrderFront(nil)

        sessions[displayID] = Session(
            window: overlayWindow,
            contentView: contentView,
            displayID: displayID
        )
        contentView.start()
        installEscapeMonitor()
        observeScreenChanges()
        onStateChange?()
    }

    private func installEscapeMonitor() {
        guard escapeMonitor == nil else { return }

        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.disableKeySession()
                return nil
            }
            return event
        }
    }

    private func disableKeySession() {
        if let keyWindow = NSApp.keyWindow as? AmbientWindow,
           let displayID = sessions.first(where: { $0.value.window === keyWindow })?.key {
            disable(displayID: displayID)
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }),
           let displayID = screen.displayID,
           sessions[displayID] != nil {
            disable(displayID: displayID)
        }
    }

    private func removeEscapeMonitor() {
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
    }

    private func observeScreenChanges() {
        guard screenObserver == nil else { return }

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
        let activeDisplayIDs = Set(NSScreen.screens.compactMap(\.displayID))
        let missingDisplayIDs = sessions.keys.filter { !activeDisplayIDs.contains($0) }

        for displayID in missingDisplayIDs {
            tearDownSession(displayID: displayID)
        }

        for (displayID, session) in sessions {
            guard let screen = NSScreen.screens.first(where: { $0.displayID == displayID }) else {
                continue
            }
            session.window.setFrame(screen.visibleFrame, display: true)
        }

        if sessions.isEmpty {
            removeEscapeMonitor()
            removeScreenObserver()
        }

        if !missingDisplayIDs.isEmpty {
            onStateChange?()
        }
    }
}

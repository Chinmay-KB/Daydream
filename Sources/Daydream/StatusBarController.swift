import AppKit

final class StatusBarController {
    private let overlayController: AmbientOverlayController
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    init(overlayController: AmbientOverlayController) {
        self.overlayController = overlayController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let quitItem = NSMenuItem(
            title: "Quit Daydream",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "moon.zzz",
                accessibilityDescription: "Daydream"
            )
            button.toolTip = "Click a display's menu bar icon to Daydream that screen"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        overlayController.onStateChange = { [weak self] in
            self?.refreshIcon()
        }
        refreshIcon()
    }

    @objc
    private func statusItemClicked(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
            return
        }

        guard let screen = statusItem.button?.window?.screen else { return }
        overlayController.toggle(on: screen)
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }

    private func showMenu() {
        guard let button = statusItem.button else { return }
        let location = NSPoint(x: 0, y: button.bounds.height + 2)
        menu.popUp(positioning: nil, at: location, in: button)
    }

    private func refreshIcon() {
        let symbolName = overlayController.isEnabled ? "moon.zzz.fill" : "moon.zzz"
        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: "Daydream"
        )
    }
}

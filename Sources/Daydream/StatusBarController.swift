import AppKit

final class StatusBarController {
    private let overlayController: AmbientOverlayController
    private let statusItem: NSStatusItem
    private let toggleItem = NSMenuItem()

    init(overlayController: AmbientOverlayController) {
        self.overlayController = overlayController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "moon.zzz",
                accessibilityDescription: "Daydream"
            )
        }

        let menu = NSMenu()
        toggleItem.target = self
        toggleItem.action = #selector(toggleDaydream)
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Daydream",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        overlayController.onStateChange = { [weak self] in
            self?.refreshMenuTitle()
        }
        refreshMenuTitle()
    }

    @objc
    private func toggleDaydream() {
        if overlayController.isEnabled {
            overlayController.disable()
        } else {
            overlayController.enable()
        }
    }

    @objc
    private func quit() {
        NSApp.terminate(nil)
    }

    private func refreshMenuTitle() {
        toggleItem.title = overlayController.isEnabled ? "Turn Off Daydream" : "Turn On Daydream"
    }
}

import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlayController = AmbientOverlayController()
    private var statusBarController: StatusBarController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(overlayController: overlayController)
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayController.disable()
    }
}

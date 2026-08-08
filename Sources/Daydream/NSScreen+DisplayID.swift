import AppKit
import CoreGraphics

extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            preconditionFailure("NSScreen is missing NSScreenNumber")
        }
        return number.uint32Value
    }
}

//
//  UIWindow+nsWindow.swift
//  EP Diagram
//
//  Created by David Mann on 5/14/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

#if targetEnvironment(macCatalyst)
import UIKit
import Dynamic

extension UIWindow {
    var nsWindow: NSObject? {
        var nsWindow = Dynamic.NSApplication.sharedApplication.delegate.hostWindowForUIWindow(self)
        if #available(macOS 11, *) {
            nsWindow = nsWindow.attachedWindow
        }
        return nsWindow.asObject
    }
}
#endif

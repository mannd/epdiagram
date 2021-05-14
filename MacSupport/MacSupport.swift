//
//  MacSupport.swift
//  MacSupport
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import AppKit

class MacSupport: NSObject, SharedProtocol {
    required override init() {}

    var openPanel: NSPanel?


    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(windowClosing), name: NSWindow.willCloseNotification, object: nil)
    }


    func sayHello() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Hello from AppKit!"
        alert.informativeText = "It Works!"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // FIXME: This substitutes for the catalyst open recent menu, but with the same problems.
    // Still getting sandbox type errors.
    func loadRecentMenu() {
        for menu in NSApp.mainMenu!.items {
            for submenu in menu.submenu!.items {
                if submenu.title == "Open Recent" {
                    let openRecentMenu = NSMenu(title: "Open Recent")
                    openRecentMenu.perform(NSSelectorFromString("_setMenuName:"), with: "NSRecentDocumentsMenu")
                    submenu.submenu = openRecentMenu
                    break
                }
            }
        }
        NSDocumentController.shared.value(forKey: "_installOpenRecentMenus")
    }

    func printMainWindow(_ sender: Any) {
        let mw = NSApplication.shared.mainWindow
        print("*****mainWindow", mw as Any)
        let kw = NSApplication.shared.keyWindow
        print("*****keyWindow", kw as Any)
        let windows = NSApplication.shared.windows
        for w in windows {
            print("*****window", w as Any)
            w.close()
        }
        print("***********************")
    }

    @objc
    func closeWindows(_ sender: Any) {
        for window in NSApplication.shared.windows {
            window.standardWindowButton(.closeButton)?.isHidden = true
        }
    }

    @objc
    func windowClosing() {
        print("$$$$window closing")
    }

}

//class WindowController: NSWindowController {
//    override var shouldCloseDocument: Bool {
//        return true
//    }
//}

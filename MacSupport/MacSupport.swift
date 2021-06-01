//
//  MacSupport.swift
//  MacSupport
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import AppKit

class MacSupport: NSObject, SharedAppKitProtocol {
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

    // Note used
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

    @objc
    func closeWindows(_ sender: Any) {
        for window in NSApplication.shared.windows {
            window.standardWindowButton(.closeButton)?.isHidden = true
        }
    }

    @objc
    func disableCloseButton(nsWindow: AnyObject) {
        if let nsWindow = nsWindow as? NSWindow {
            nsWindow.standardWindowButton(.closeButton)?.isHidden = true
        }
    }

    @objc
    func windowClosing() {
        print("$$$$window closing")
    }

    @objc func getDirectory(nsWindow: AnyObject, startingURL: URL?, completion: ((URL)->Void)?) {
        guard let nsWindow = nsWindow as? NSWindow else { return }
        let panel = NSOpenPanel()
        panel.prompt = ("Select")
        if let startingURL = startingURL  {
            panel.message = "EP Diagram needs permission to access the \(startingURL.lastPathComponent) folder.  It should be already selected and all you need to do is tap the Select button."
        } else {
            panel.message = "Please select a folder to add to the App Sandbox"
        }
        panel.canChooseFiles = false
        panel.allowedFileTypes = ["N/A"]
        panel.allowsOtherFileTypes = false
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        if let startingURL = startingURL {
            panel.directoryURL = startingURL
            print("panel.directoryURL", panel.directoryURL as Any)
        }

        panel.beginSheetModal(for: nsWindow, completionHandler: { response in
            if let url: URL = panel.urls.first {
                print("url = \(url)")
                if let completion = completion {
                    completion(url)
                }
            }
        })
    }
}

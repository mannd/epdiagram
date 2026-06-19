//
//  MacSupport.swift
//  MacSupport
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import AppKit
import UniformTypeIdentifiers

class MacSupport: NSObject, SharedAppKitProtocol {
    required override init() {}


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
    func windowClosing() {
        print("window closing")
    }

    @objc func showHelp() {
        NSApp.showHelp(nil)
    }

    @objc func getDirectory(nsWindow: AnyObject, startingURL: URL?, completion: ((URL)->Void)?) {
        guard let nsWindow = nsWindow as? NSWindow else { return }
        let panel = NSOpenPanel()
        panel.prompt = ("Select")
        if let startingURL = startingURL  {
            panel.message = "EP Diagram needs permission to access the \(startingURL.lastPathComponent) folder.  It should be already selected and all you need to do is click the Select button."
        } else {
            panel.message = "Please select a folder that you would like EP Diagram to have access to."
        }
        panel.canChooseFiles = false
        panel.allowedContentTypes = [.folder]
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

    @objc func getDiagram(nsWindow: AnyObject?, startingURL: URL?, completion: ((URL)->Void)?) {
        print("getDiagram - MacSupport startingURL", startingURL?.path ?? "nil")
        let panel = NSOpenPanel()
        panel.prompt = "Open"
        panel.message = "Select an EP Diagram file."
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType(exportedAs: "org.epstudios.diagram")]
        panel.allowsOtherFileTypes = false
        panel.allowsMultipleSelection = false
        if let startingURL = startingURL {
            panel.directoryURL = startingURL
        }

        let handleResponse: (NSApplication.ModalResponse) -> Void = { response in
            print("getDiagram - MacSupport response", response.rawValue)
            guard response == .OK, let url = panel.urls.first else {
                print("getDiagram - MacSupport cancelled or no URL")
                return
            }
            print("getDiagram - MacSupport selected URL", url.path)
            completion?(url)
        }

        if let nsWindow = nsWindow as? NSWindow {
            panel.beginSheetModal(for: nsWindow, completionHandler: handleResponse)
        } else {
            print("getDiagram - MacSupport using app-modal open panel")
            handleResponse(panel.runModal())
        }
    }
}

//
//  MacPlugin.swift
//  EP-DiagramMacSupportBundle
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import AppKit

class MacPlugin: NSObject, Plugin {
    required override init() {}

    func sayHello() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Hello from AppKit Land!"
        alert.informativeText = "It works!"
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

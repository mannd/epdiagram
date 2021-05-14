//
//  SharedProtocol.swift
//  MacSupport
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import AppKit

@objc(SharedProtocol)
protocol SharedProtocol: NSObjectProtocol {
    init()

    func sayHello()  // for testing
    func loadRecentMenu()
    func printMainWindow(_ sender: Any)
    func closeWindows(_ sender: Any)
    func setupNotifications()
    func disableCloseButton()
    func disableCloseButton(nsWindow: AnyObject)
}

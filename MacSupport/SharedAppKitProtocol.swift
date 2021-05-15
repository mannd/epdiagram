//
//  SharedAppKitProtocol.swift
//  MacSupport
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import Foundation

@objc(SharedAppKitProtocol)
protocol SharedAppKitProtocol: NSObjectProtocol {
    init()

    func sayHello()  // for testing
    func loadRecentMenu()
    func closeWindows(_ sender: Any)
    func setupNotifications()
    func disableCloseButton(nsWindow: AnyObject)
}

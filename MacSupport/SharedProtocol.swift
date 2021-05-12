//
//  SharedProtocol.swift
//  MacSupport
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import Foundation

@objc(SharedProtocol)
protocol SharedProtocol: NSObjectProtocol {
    init()

    func sayHello()  // for testing
    func loadRecentMenu()
}

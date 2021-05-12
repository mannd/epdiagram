//
//  Plugin.swift
//  EP Diagram
//
//  Created by David Mann on 5/11/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import Foundation

@objc(Plugin)
protocol Plugin: NSObjectProtocol {
    init()

    func sayHello()
}

//
//  Interval.swift
//  EP Diagram
//
//  Created by David Mann on 6/30/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

protocol Interval {
    var value: CGFloat { get set }
    var units: String { get set }

    func calibratedValue() -> CGFloat
    func calibratedInterval() -> String
}

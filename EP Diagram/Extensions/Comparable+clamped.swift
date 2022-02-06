//
//  Comparable+clamped.swift
//  EP Diagram
//
//  Created by David Mann on 2/6/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

import Foundation

// See https://stackoverflow.com/questions/36110620/standard-way-to-clamp-a-number-between-two-values-in-swift
extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

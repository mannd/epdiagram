//
//  NSLayoutConstraint+setMultiplier.swift
//  EP Diagram
//
//  Created by David Mann on 2/6/22.
//  Copyright © 2022 EP Studios. All rights reserved.
//

// From https://stackoverflow.com/questions/19593641/can-i-change-multiplier-property-for-nslayoutconstraint
import UIKit

// In order to change the multiplier of a constraint, the constraint must be recreated.
extension NSLayoutConstraint {
    /**
     Change multiplier constraint

     - parameter multiplier: CGFloat
     - returns: NSLayoutConstraint
    */
    func setMultiplier(multiplier: CGFloat) -> NSLayoutConstraint {

        NSLayoutConstraint.deactivate([self])

        let newConstraint = NSLayoutConstraint(
            item: firstItem as Any,
            attribute: firstAttribute,
            relatedBy: relation,
            toItem: secondItem,
            attribute: secondAttribute,
            multiplier: multiplier,
            constant: constant)

        newConstraint.priority = priority
        newConstraint.shouldBeArchived = self.shouldBeArchived
        newConstraint.identifier = self.identifier

        NSLayoutConstraint.activate([newConstraint])
        return newConstraint
    }
}

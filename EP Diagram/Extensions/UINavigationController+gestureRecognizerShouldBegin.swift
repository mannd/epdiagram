//
//  UINavigationController+gestureRecognizerShouldBegin.swift
//  EP Diagram
//
//  Created by David Mann on 10/18/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// See https://stackoverflow.com/questions/59921239/hide-navigation-bar-without-losing-swipe-back-gesture-in-swiftui
// This allows swipe back when using custom back button in SwiftUI
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}


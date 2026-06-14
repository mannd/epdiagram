//
//  GestureNavigationController.swift
//  EP Diagram
//
//  Created by David Mann on 6/13/26.
//  Copyright © 2026 EP Studios. All rights reserved.
//

import UIKit

final class GestureNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}

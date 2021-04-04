//
//  UIView+findViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/5/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
}

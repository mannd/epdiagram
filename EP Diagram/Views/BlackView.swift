//
//  BlackView.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class BlackView: UIView, UIGestureRecognizerDelegate {
    var delegate: HamburgerTableDelegate?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(gestureTap))
        tapGestureRecognizer.isEnabled = true
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc
    func gestureTap() {
        if let delegate = delegate, delegate.hamburgerMenuIsOpen {
            delegate.hideHamburgerMenu()
        }

    }
}

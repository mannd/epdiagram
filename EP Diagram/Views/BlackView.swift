//
//  BlackView.swift
//  EP Diagram
//
//  Created by David Mann on 4/15/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

final class BlackView: UIView, UIGestureRecognizerDelegate {
    weak var delegate: HamburgerTableDelegate?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(gestureTap))
        tapGestureRecognizer.isEnabled = true
        tapGestureRecognizer.delegate = self
        self.addGestureRecognizer(tapGestureRecognizer)
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gesturePan))
        panGestureRecognizer.isEnabled = true
        panGestureRecognizer.delegate = self
        self.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    func gestureTap() {
        if let delegate = delegate, delegate.hamburgerMenuIsOpen {
            delegate.hideHamburgerMenu()
        }
    }

    @objc func gesturePan(sender: UIPanGestureRecognizer) {
        guard let delegate = delegate else { return }
        if sender.state == .began {
            return
        }
        if sender.state == .changed {
            let translationX: CGFloat = sender.translation(in: sender.view).x
            if translationX > 0 {
                delegate.constraintHamburgerLeft.constant = 0
                self.alpha = delegate.maxBlackAlpha
            }
            else if translationX < -delegate.constraintHamburgerWidth.constant {
                self.alpha = 0
            }
            else {
                delegate.constraintHamburgerLeft.constant = translationX
                let ratio: CGFloat = (delegate.constraintHamburgerWidth.constant + translationX) / delegate.constraintHamburgerWidth.constant
                let alphaValue = ratio * delegate.maxBlackAlpha
                self.alpha = alphaValue
            }
        }
        else {
            if delegate.constraintHamburgerLeft.constant < -delegate.constraintHamburgerWidth.constant / 2 {
                delegate.hideHamburgerMenu()
            }
            else {
                delegate.showHamburgerMenu()
            }
        }
    }
}

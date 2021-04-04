//
//  ImageScrollView.swift
//  EP Diagram
//
//  Created by David Mann on 12/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class ImageScrollView: UIScrollView {
    weak var diagramViewControllerDelegate: DiagramViewControllerDelegate?
    override var canBecomeFirstResponder: Bool { true }
    var leftMargin: CGFloat = 0
    var mode: Mode = .normal
    var isActivated: Bool = true {
        didSet {
            isUserInteractionEnabled = isActivated
            alpha = isActivated ? 1.0 : 0.4
        }
    }
}

extension ImageScrollView {

    @IBAction func showImageMenu(_ gestureRecognizer: UILongPressGestureRecognizer) {
        print("long press")
        guard let delegate = diagramViewControllerDelegate, delegate.okToShowLongPressMenu() else { return }
        if gestureRecognizer.state == .began {
            if contentSize == CGSize.zero { return }
            self.becomeFirstResponder()
            let rotateMenuItem = UIMenuItem(title: L("Rotate"), action: #selector(showRotateToolbar))
            let resetMenuItem = UIMenuItem(title: L("Reset"), action: #selector(resetImage))
            let doneMenuItem = UIMenuItem(title: L("Done"), action: #selector(doneAction))

            let pdfMenuItem = UIMenuItem(title: L("PDF"), action: #selector(showPDFToolbar))
            let menuController = UIMenuController.shared
            if let delegate = diagramViewControllerDelegate, delegate.showPDFMenuItems() {
                menuController.menuItems = [rotateMenuItem, resetMenuItem, pdfMenuItem, doneMenuItem]
            } else {
                menuController.menuItems = [rotateMenuItem, resetMenuItem, doneMenuItem]
            }

            // Set the location of the menu in the view.
            let location = gestureRecognizer.location(in: gestureRecognizer.view)
            let menuLocation = CGRect(x: location.x, y: location.y, width: 0, height: 0)
            menuController.showMenu(from: self, rect: menuLocation)
        }
    }

    @objc func menuDidClose() {
        print("menu did close")
    }

    func doNothing() {}

    func rotateImage(degrees: CGFloat) {
        assert(leftMargin > 0, "Left margin not set")
        diagramViewControllerDelegate?.rotateImage(degrees: degrees)
        setNeedsDisplay()
    }

    @objc func showRotateToolbar() {
        diagramViewControllerDelegate?.showRotateToolbar()
    }

    @objc func resetImage() {
        diagramViewControllerDelegate?.resetImage()
    }

    @objc func doneAction() {
        self.resignFirstResponder()
    }

    @objc func showPDFToolbar() {
        print("showPDFToolbar()")
        diagramViewControllerDelegate?.showPDFToolbar()
    }
}


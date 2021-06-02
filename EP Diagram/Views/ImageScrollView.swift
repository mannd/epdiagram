//
//  ImageScrollView.swift
//  EP Diagram
//
//  Created by David Mann on 12/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

/// ImageScrollView has a content UIView that wraps a UIImageView, which allows zooming and scrolling of
/// the content view, while the image view can have rotational transforms applied to it separately.
class ImageScrollView: UIScrollView {
    weak var diagramViewControllerDelegate: DiagramViewControllerDelegate?
    override var canBecomeFirstResponder: Bool { true }
    var leftMargin: CGFloat = 0 // set by DiagramViewController
    var mode: Mode = .normal // set by DiagramViewController
    var isActivated: Bool = true {
        didSet {
            isUserInteractionEnabled = isActivated
            alpha = isActivated ? 1.0 : 0.4
        }
    }

    deinit {
        print("*****ImageScrollView deinit()******")
    }
}

extension ImageScrollView {
    /// Shows a "long press" menu that handles image rotation
    /// - Parameter gestureRecognizer: the long press gesture recognizer, containing the position of the press
    @IBAction func showImageMenu(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard let delegate = diagramViewControllerDelegate, delegate.okToShowLongPressMenu() else { return }
        if gestureRecognizer.state == .began {
            delegate.hideCursor()
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

    // Image menu functions.  Most of these just call the DiagramViewController delegate to do the actual work.

    /// Rotate the UIImageView, parameters passed back to DiagramViewController
    /// - Parameter degrees: degrees (not radians) as `CGFloat`
    func rotateImage(degrees: CGFloat) {
        assert(leftMargin > 0, "Left margin not set")
        diagramViewControllerDelegate?.rotateImage(degrees: degrees)
        setNeedsDisplay()
    }

    /// Show rotate menu as a toolbar
    @objc func showRotateToolbar() {
        diagramViewControllerDelegate?.showRotateToolbar()
    }

    @IBAction func showMacRotateToolbar(_ sender: Any) {
        showRotateToolbar()
    }

//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        if action == #selector(showMacRotateToolbar(_:)) {
//            return true
//        } else {
//            return super.canPerformAction(action, withSender: sender)
//        }
//    }

    @IBAction func resetMacImage(_ sender: Any) {
        resetImage()
    }

    @IBAction func showMacPDFToolbar(_ sender: Any) {
        showPDFToolbar()
    }

    /// Reset image to a identity transfrom
    @objc func resetImage() {
        diagramViewControllerDelegate?.resetImage()
    }

    /// Closes long press image menu
    @objc func doneAction() {
        self.resignFirstResponder()
    }

    /// Shows PDF menu as a toolbar
    @objc func showPDFToolbar() {
        diagramViewControllerDelegate?.showPDFToolbar()
    }
}

#if targetEnvironment(macCatalyst)
extension ImageScrollView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        print("image scroll view context menu")
        guard let delegate = diagramViewControllerDelegate, delegate.okToShowLongPressMenu() else { return nil }
        delegate.hideCursor()
        return imageScrollViewContextMenuConfiguration(at: location)
    }

    func imageScrollViewContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            if self.contentSize == CGSize.zero { return nil }
            let rotateAction = UIAction(title: L("Rotate")) { action in
                self.showRotateToolbar()
            }
            let resetAction = UIAction(title: L("Reset")) { action in
                self.resetImage()
            }
            let pdfAction = UIAction(title: L("PDF")) { action in
                self.showPDFToolbar()
            }
            if let delegate = self.diagramViewControllerDelegate, delegate.showPDFMenuItems() {
                return UIMenu(title: "", children: [rotateAction, resetAction, pdfAction])
            } else {
                return UIMenu(title: "", children: [rotateAction, resetAction])
            }
        }
    }
}
#endif


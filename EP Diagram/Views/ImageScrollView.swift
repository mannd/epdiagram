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

    lazy var resetAction = UIAction(title: L("Reset")) { action in
        self.resetImage()
    }
    lazy var rotateAction = UIAction(title: L("Rotate")) { action in
        self.showRotateToolbar()
    }
}

extension ImageScrollView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        // FIXME: This might work without select mode, but scrolling image screws up.  Maybe set up an isscrolling variable to avoid this?
        guard mode == .select else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return UIMenu(title: "", children: [self.rotateAction, self.resetAction])
        }
    }

    func doNothing() {}

    func rotateImage(degrees: CGFloat) {
        assert(leftMargin > 0, "Left margin not set")
        diagramViewControllerDelegate?.rotateImage(degrees: degrees)
//        contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
        setNeedsDisplay()
    }

    func showRotateToolbar() {
        diagramViewControllerDelegate?.showRotateToolbar()
    }

    func resetImage() {
        diagramViewControllerDelegate?.resetImage()
    }

}


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
}

// FIXME: Rotation moves image to left.  Zooming removes rotation.
extension ImageScrollView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let rotate = UIAction(title: L("Rotate Image")) { action in
                self.rotateImage()
            }
            let reset = UIAction(title: L("Reset Image")) { action in
                self.resetImage()
            }
            return UIMenu(title: "Rotation", children: [rotate, reset])
        }
    }

    func doNothing() {}

    func rotateImage() {
        let leftMargin: CGFloat = 50
        diagramViewControllerDelegate?.rotateImage(degrees: 90)
        contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
    }

    func resetImage() {
        diagramViewControllerDelegate?.resetImage()
    }
}


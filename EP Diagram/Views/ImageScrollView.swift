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
}


// FIXME: Rotation moves image to left.  Zooming removes rotation.
extension ImageScrollView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let rotate90R = UIAction(title: L("Rotate 90 R")) { action in
                self.rotateImage(degrees: 90)
            }
            let rotate90L = UIAction(title: L("Rotate 90 L")) { action in
                self.rotateImage(degrees: -90)
            }
            let rotate1R = UIAction(title: L("Rotate 1 R")) { action in
                self.rotateImage(degrees: 1)
            }
            let rotate1L = UIAction(title: L("Rotate 1 L")) { action in
                self.rotateImage(degrees: -1)
            }
            let rotate01R = UIAction(title: L("Rotate 0.1 R")) { action in
                self.rotateImage(degrees: 0.1)
            }
            let rotate01L = UIAction(title: L("Rotate 0.1 L")) { action in
                self.rotateImage(degrees: -0.1)
            }
            let reset = UIAction(title: L("Reset")) { action in
                self.resetImage()
            }
            let rotate = UIMenu(title: L("Rotate..."), image: UIImage(systemName: "rotate.right"), children: [rotate90R, rotate90L, rotate1R, rotate1L, rotate01R, rotate01L, reset])
            
            return UIMenu(title: "", children: [rotate, reset])
        }
    }

    func doNothing() {}

    func rotateImage(degrees: CGFloat) {
        let leftMargin: CGFloat = 50
        diagramViewControllerDelegate?.rotateImage(degrees: degrees)
        contentInset = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: 0)
    }

    func resetImage() {
        diagramViewControllerDelegate?.resetImage()
    }

}


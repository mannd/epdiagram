//
//  ImageScrollView.swift
//  EP Diagram
//
//  Created by David Mann on 12/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class ImageScrollView: UIScrollView {
    
}

extension ImageScrollView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        print("******long press")
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let solid = UIAction(title: L("Rotate Image")) { action in
                self.doNothing()
            }
            return UIMenu(title: "Rotation", children: [solid])
        }
    }

    func doNothing() {}
}


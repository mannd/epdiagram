//
//  LadderView+UIContextMenuInteractionDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

// Note context menus seem to cause constraint warnings (non-fatal).  See https://github.com/apptekstudios/ASCollectionView/issues/77 .  Will ignore for now.
@available(iOS 13.0, *)
extension LadderView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let markWasTapped = positionIsNearMark(position: location)
        setPressedMark(position: location)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let solid = UIAction(title: L("Solid")) { action in
                self.setSolid()
            }
            let dashed = UIAction(title: L("Dashed")) { action in
                self.setDashed()
            }
            let dotted = UIAction(title: L("Dotted")) { action in
                self.setDotted()
            }
            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
            // Use .displayInline option to show menu inline with separator.
            //           let style = UIMenu(title: L("Style..."), options: .displayInline,  children: [solid, dashed, dotted])
            let unlink = UIAction(title: L("Unlink")) { action in
                self.ungroupPressedMark()
            }
            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deletePressedMark()
            }
            let deleteAll = UIAction(title: L("Delete all in region"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deleteAllInRegion()
            }
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
            let straightenToProximal = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
                self.straightenToProximal()
            }
            let straightenToDistal = UIAction(title: L("Straighten mark to distal endpoint")) { action in
                self.straightenToDistal()
            }
            // Create and return a UIMenu with all of the actions as children
            if markWasTapped {
                return UIMenu(title: L("Edit mark"), children: [style, straightenToProximal, straightenToDistal, unlink, delete, deleteAll])
            }
            else {
                return UIMenu(title: "", children: [delete, deleteAll])
            }
        }
    }
}

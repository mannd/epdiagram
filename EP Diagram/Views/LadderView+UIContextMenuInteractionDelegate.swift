//
//  LadderView+UIContextMenuInteractionDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import OSLog

// Note context menus seem to cause constraint warnings (non-fatal).  See https://github.com/apptekstudios/ASCollectionView/issues/77 .  Will ignore for now.//
// FIXME: If we return nil no menu appears.  With single tap, drag, etc. maybe set flag to avoid this context menu from appearing.
extension LadderView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        os_log("contextMenuInteraction(:configurationForMenuAtLocation:)", log: .action, type: .info)
        // Warning: don't hide cursor here, as this function is called during dragging on ladder view.
        let locationInLadder = getLocationInLadder(position: location)
        print("\(locationInLadder)")
        print("Specific Location = \(locationInLadder.specificLocation)")
        switch locationInLadder.specificLocation {
        case .mark:
            return handleMarkPressed(at: location)
        default:
            return nil
        }
//        return nil
//        let markWasLongPressed = positionIsNearMark(position: location)
//        setPressedMark(position: location)
//        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
//            let solid = UIAction(title: L("Solid")) { action in
//                self.setSolid()
//            }
//            let dashed = UIAction(title: L("Dashed")) { action in
//                self.setDashed()
//            }
//            let dotted = UIAction(title: L("Dotted")) { action in
//                self.setDotted()
//            }
//            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
//            // Use .displayInline option to show menu inline with separator.
//            //           let style = UIMenu(title: L("Style..."), options: .displayInline,  children: [solid, dashed, dotted])
//            let unlink = UIAction(title: L("Unlink")) { action in
//                self.ungroupPressedMark()
//            }
//            let paste = UIAction(title: L("Paste")) { action in
//
//            }
//            let rhythm = UIAction(title: L("Rhythm")) { action in
//
//            }
//            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
//                self.deletePressedMark()
//            }
//            let deleteAllInRegion = UIAction(title: L("Delete all in region"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
//                self.deleteAllInRegion()
//            }
//            let deleteAllInLadder = UIAction(title: L("Delete all marks in ladder"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
//                self.deleteAllInLadder()
//            }
//            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
//            let straightenToProximal = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
//                self.straightenToProximal()
//            }
//            let straightenToDistal = UIAction(title: L("Straighten mark to distal endpoint")) { action in
//                self.straightenToDistal()
//            }
//            // TODO: Must distinguish long press on mark, label, region, zone, whole ladder (outside of ladder).
//            // Create and return a UIMenu with all of the actions as children
//            if markWasLongPressed {
//                return UIMenu(title: L("Edit mark"), children: [style, straightenToProximal, straightenToDistal, unlink, delete, deleteAllInRegion, deleteAllInLadder])
//            }
//            else {
//                return UIMenu(title: "", children: [paste, rhythm, delete, deleteAllInRegion, deleteAllInLadder])
//            }
//        }
    }

    func handleMarkPressed(at location: CGPoint) -> UIContextMenuConfiguration {
        print("handleMarkPressed")
        let markWasLongPressed = positionIsNearMark(position: location)
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
            let paste = UIAction(title: L("Paste")) { action in

            }
            let rhythm = UIAction(title: L("Rhythm")) { action in

            }
            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deletePressedMark()
            }
            let deleteAllInRegion = UIAction(title: L("Delete all in region"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deleteAllInRegion()
            }
            let deleteAllInLadder = UIAction(title: L("Delete all marks in ladder"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deleteAllInLadder()
            }
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
            let straightenToProximal = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
                self.straightenToProximal()
            }
            let straightenToDistal = UIAction(title: L("Straighten mark to distal endpoint")) { action in
                self.straightenToDistal()
            }
            // TODO: Must distinguish long press on mark, label, region, zone, whole ladder (outside of ladder).
            // Create and return a UIMenu with all of the actions as children
            if markWasLongPressed {
                return UIMenu(title: L("Edit mark"), children: [style, straightenToProximal, straightenToDistal, unlink, delete, deleteAllInRegion, deleteAllInLadder])
            }
            else {
                return UIMenu(title: "", children: [paste, rhythm, delete, deleteAllInRegion, deleteAllInLadder])
            }
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        unhighlightAllMarks()
    }
}

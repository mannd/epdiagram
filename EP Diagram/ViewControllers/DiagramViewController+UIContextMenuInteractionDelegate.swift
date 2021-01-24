//
//  DiagramViewController+UIContextMenuInteractionDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 1/21/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import os.log

// TODO: Move all context menu functions here, implement through LadderView
extension DiagramViewController: UIContextMenuInteractionDelegate {
    // Need to select marks after menu appears.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        animator?.addCompletion {
            print("completion")
            if let location = self.menuPressLocation {
                self.ladderView.setPressedMark(position: location)
                self.ladderView.refresh()
            }
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        os_log("contextMenuInteraction(:configurationForMenuAtLocation:)", log: .action, type: .info)
        // Warning: don't hide cursor here, as this function is called during dragging on ladder view.
        let locationInLadder = ladderView.getLocationInLadder(position: location)
        switch locationInLadder.specificLocation {
        case .mark:
            return handleMarkPressed(at: location)
        case .region:
            return handleRegionPressed(at: location)
        case .label:
            return nil
        case .zone:
            return nil
        case .ladder:
            return nil
        case .error:
            return nil
        }
    }

    // Unselect here too
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        ladderView.normalizeAllMarks()
    }

    func handleMarkPressed(at location: CGPoint) -> UIContextMenuConfiguration {
        // FIXME: can't clear marks here
        menuPressLocation = location
//        ladderView.setPressedMark(position: location)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {_ in
            let solid = self.getSolidAction()
            let dashed = self.getDashedAction()
            let dotted = self.getDottedAction()
            // TODO: implement set slope
            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
            let slantMark = UIAction(title: L("Slant")) { action in
                self.showAngleMenu()
            }
            let unlink = UIAction(title: L("Unlink")) { action in
                self.ladderView.ungroupPressedMark()
            }
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
            let straightenToProximal = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
                self.ladderView.straightenToProximal()
            }
            let straightenToDistal = UIAction(title: L("Straighten mark to distal endpoint")) { action in
                self.ladderView.straightenToDistal()
            }
            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.ladderView.deletePressedMark()
            }
            return UIMenu(title: L("Edit mark"), children: [style, straightenToProximal, straightenToDistal, slantMark, unlink, delete])
        }
    }

    // TODO: Need to highlight region, make sure deletion is in correct region, turn off highlight when doen with menu item.
    func handleRegionPressed(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
//            let solid = UIAction(title: L("Solid")) { action in
////                self.setSolid()
//            }
//            let dashed = UIAction(title: L("Dashed")) { action in
////                self.setDashed()
//            }
//            let dotted = UIAction(title: L("Dotted")) { action in
////                self.setDotted()
//            }
//            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
            // Use .displayInline option to show menu inline with separator.
            //           let style = UIMenu(title: L("Style..."), options: .displayInline,  children: [solid, dashed, dotted])
//            let unlink = UIAction(title: L("Unlink")) { action in
//                self.ungroupPressedMark()
//            }
            let paste = UIAction(title: L("Paste")) { action in

            }
            let rhythm = UIAction(title: L("Rhythm")) { action in

            }
//            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
//                self.ladderView.deletePressedMark()
//            }
            let deleteAllInRegion = UIAction(title: L("Delete all in region"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.ladderView.deleteAllInRegion()
            }
            let deleteAllInLadder = UIAction(title: L("Delete all marks in ladder"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.ladderView.deleteAllInLadder()
            }
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
//            let straightenToProximal = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
//                self.straightenToProximal()
//            }
//            let straightenToDistal = UIAction(title: L("Straighten mark to distal endpoint")) { action in
//                self.straightenToDistal()
//            }
            // TODO: Must distinguish long press on mark, label, region, zone, whole ladder (outside of ladder).
            // Create and return a UIMenu with all of the actions as children
            return UIMenu(title: "", children: [paste, rhythm, deleteAllInRegion, deleteAllInLadder])
        }
    }

    func getSolidAction() -> UIAction {
        return UIAction(title: L("Solid")) { action in
            self.ladderView.setSolid()
        }
    }

    func getDashedAction() -> UIAction {
        return UIAction(title: L("Dashed")) { action in
            self.ladderView.setDashed()
        }
    }

    func getDottedAction() -> UIAction {
        return UIAction(title: L("Dotted")) { action in
            self.ladderView.setDotted()
        }
    }
}


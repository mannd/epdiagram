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
            guard let locationInLadder = self.longPressLocationInLadder else { return }
            self.menuAppeared = true
            self.ladderView.saveState()
            switch locationInLadder.specificLocation {
            case .mark:
                if let location = self.menuPressLocation {
                    self.ladderView.setSelectedMark(position: location)
//                    self.ladderView.refresh()
                }
            case .region:
                if let region = locationInLadder.region {
                    self.ladderView.ladder.setMarksWithMode(.selected, inRegion: region)
                    region.mode = .selected
                }
            case .label:
                break
            case .zone:
                break
            case .ladder:
                self.ladderView.ladder.setAllMarksWithMode(.selected)
                for region in self.ladderView.ladder.regions {
                    region.mode = .selected
                }
            default:
                break
            }
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        os_log("contextMenuInteraction(:configurationForMenuAtLocation:)", log: .action, type: .info)
        let locationInLadder = ladderView.getLocationInLadder(position: location)
        longPressLocationInLadder = locationInLadder

        switch locationInLadder.specificLocation {
        case .mark:
            return showMarkContextMenu(at: location)
        case .region:
            return showRegionContextMenu(at: location)
        case .label:
            return showLabelContextMenu(at: location)
        case .zone:
            return showZoneContextMenu(at: location)
        case .ladder:
            return showLadderContextMenu(at: location)
        case .error:
            return nil
        }
    }

    // This is called with each drag.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        animator?.addCompletion {
            guard self.menuAppeared else { return }
            self.ladderView.restoreState()
            self.menuAppeared = false
        }

    }

    func showMarkContextMenu(at location: CGPoint) -> UIContextMenuConfiguration {
        // FIXME: can't clear marks here
        menuPressLocation = location
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
                self.ladderView.ungroupSelectedMarks()
            }
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
            let straightenToProximal = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
                self.ladderView.straightenToProximal()
            }
            let straightenToDistal = UIAction(title: L("Straighten mark to distal endpoint")) { action in
                self.ladderView.straightenToDistal()
            }
            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.ladderView.deleteSelectedMarks()
            }
            return UIMenu(title: L("Edit mark"), children: [style, straightenToProximal, straightenToDistal, slantMark, unlink, delete])
        }
    }

    // TODO: Need to highlight region, make sure deletion is in correct region, turn off highlight when doen with menu item.
    func showRegionContextMenu(at location: CGPoint) -> UIContextMenuConfiguration {
        menuPressLocation = location
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
//                self.ungroupSelectedMarks()
//            }
            let paste = UIAction(title: L("Paste")) { action in

            }
            let rhythm = UIAction(title: L("Rhythm")) { action in

            }
//            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
//                self.ladderView.deleteSelectedMarks()
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

    func showLabelContextMenu(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration()
    }

    func showZoneContextMenu(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration()
    }

    func showLadderContextMenu(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let deleteAllInLadder = UIAction(title: L("Clear ladder"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.ladderView.deleteAllInLadder()
            }
            return UIMenu(title: "", children: [deleteAllInLadder])
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


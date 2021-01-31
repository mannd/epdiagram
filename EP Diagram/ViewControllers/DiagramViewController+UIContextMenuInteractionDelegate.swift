//
//  DiagramViewController+UIContextMenuInteractionDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 1/21/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import os.log

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
            case .region, .label:
                if let region = locationInLadder.region {
                    self.ladderView.ladder.zone = Zone() // hide zone
                    self.ladderView.ladder.setMarksWithMode(.selected, inRegion: region)
                    region.mode = .selected
                }
            case .zone:
                // zoning selects marks automatically
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

    // FIXME: Add default style for region, for new marks.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        os_log("contextMenuInteraction(:configurationForMenuAtLocation:)", log: .action, type: .info)
        let locationInLadder = ladderView.getLocationInLadder(position: location)
        longPressLocationInLadder = locationInLadder
        menuPressLocation = location
        switch locationInLadder.specificLocation {
        case .mark:
            return markContextMenuConfiguration(at: location)
        case .region, .label:
            return regionContextMenuConfiguration(at: location)
        case .zone:
            return zoneContextMenuConfiguration(at: location)
        case .ladder:
            return ladderContextMenuConfiguration(at: location)
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

    func markContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {_ in
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
            return UIMenu(title: L("Edit mark"), children: [self.styleMenu, self.straightenToProximalAction, self.straightenToDistalAction, self.slantMenuAction, self.unlinkAction, self.deleteAction])
        }
    }

    func regionContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
            return UIMenu(title: "", children: [self.styleMenu, self.regionStyleMenu, self.straightenToProximalAction, self.straightenToDistalAction, self.editLabelAction, self.rhythmAction, self.deleteAllInRegion])
        }
    }

    func zoneContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        print("zone selected")
        return UIContextMenuConfiguration()
    }

    func ladderContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return UIMenu(title: "", children: [self.deleteAllInLadder])
        }
    }
}


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

    // Will display menu
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        guard let locationInLadder = self.longPressLocationInLadder else { return }
        self.menuAppeared = true
        self.ladderView.saveState()
        self.separatorView?.isHidden = true

        if self.ladderView.mode == .select {
            let selectedRegions = self.ladderView.ladder.allRegionsWithMode(.selected)
            self.ladderView.ladder.setMarksWithMode(.selected, inRegions: selectedRegions)
            return
        }
        if self.ladderView.mode == .normal {
            switch locationInLadder.specificLocation {
            case .mark:
                if let location = self.menuPressLocation {
                    self.ladderView.setSelectedMark(position: location)
                }
            case .region:
                // TODO: can select multiple regions in select mode, but only one works with long press.
                // Maybe in select mode, wherever you press shouldn't matter, only selection matters.
                if let region = locationInLadder.region {
                    //                    self.ladderView.ladder.zone = Zone() // hide zone
                    //                    let selectedRegions = self.ladderView.ladder.allRegionsWithMode(.selected)
                    //                    self.ladderView.ladder.setMarksWithMode(.selected, inRegions: selectedRegions)
                    self.ladderView.ladder.setMarksWithMode(.selected, inRegion: region)
                    region.mode = .selected
                }
            case .label:
                if let region = locationInLadder.region {
                    region.mode = .labelSelected
                }
            case .zone:
                self.ladderView.selectInZone()
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

    // Determines what menu appears.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        os_log("contextMenuInteraction(:configurationForMenuAtLocation:)", log: .action, type: .info)
        switch ladderView.mode {
        case .normal:
            return normalModeMenu(forLocation: location)
        case .select:
            return selectModeMenu(forLocation: location)
        case .calibrate, .connect, .menu:
            return nil
        }
    }

    // contextMenuInteraction(_:willEndFor:...)  This is called with each drag, and after menu appears.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        // Filter out all the time this abortedly appears.
        guard self.menuAppeared else { return }
        if self.prolongSelectState {
            // delay restoring state until menu closes
            self.ladderView.mode = .menu
        } else {
            mode = self.ladderView.restoreState()
        }
        self.menuAppeared = false
        self.separatorView?.isHidden = false
    }

    func normalModeMenu(forLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let locationInLadder = ladderView.getLocationInLadder(position: location)
        longPressLocationInLadder = locationInLadder
        menuPressLocation = location
        switch locationInLadder.specificLocation {
        case .mark:
            return markContextMenuConfiguration(at: location)
        case .region:
            return markContextMenuConfiguration(at: location)
        case .label:
            return labelContextMenuConfiguration(at: location)
        case .zone:
            return markContextMenuConfiguration(at: location)
        case .ladder:
            return ladderContextMenuConfiguration(at: location)
        case .error:
            return nil
        }
    }

    func selectModeMenu(forLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if ladderView.noSelectionExists() {
            return noSelectionContextMenu(at: location)
        }
         return markContextMenuConfiguration(at: location)
    }

    func noSelectionContextMenu(at location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            return UIMenu(title: "No Selection Found", children: [self.noSelectionAction])
        }
    }

    func markContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {_ in
            // FIXME: make sure we won't move linked marks, or disconnect them when straightening.
            return UIMenu(title: L("Mark Menu"), children: [self.styleMenu, self.emphasisMenu, self.blockMenu, self.straightenMenu, self.slantMenu, self.adjustYMenu,  self.unlinkAction, self.deleteAction])
        }
    }

    func regionContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            // FIXME: make sure we won't move linked marks, or disconnect them when straightening.
            let title: String
            if let region = self.longPressLocationInLadder?.region {
                title = L("\(region.name) — \(region.longDescription)")
            } else {
                title = L("Region")
            }
            return UIMenu(title: title, children: [self.styleMenu, self.straightenMenu, self.slantMenu, self.adjustYMenu, self.rhythmAction, self.deleteAllInRegion])
        }
    }

    func labelContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let title: String
            if let region = self.longPressLocationInLadder?.region {
                title = L("Region Menu\n\(region.name) — \(region.longDescription)")
            } else {
                title = L("Region")
            }
            return UIMenu(title: title, children: [self.regionStyleMenu, self.editLabelAction, self.addRegionMenu, self.removeRegionAction, self.regionHeightMenu])
        }
    }

    func zoneContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        print("zone selected")
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            // TODO: add deleteInZone action
            return UIMenu(title: L("Zone"), children: [self.styleMenu, self.straightenMenu, self.slantMenu, self.rhythmAction])
        }

    }

    func ladderContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return UIMenu(title: L("Ladder"), children: [self.adjustLeftMarginAction,  self.linkAll, self.unlinkAll, self.deleteAllInLadder])
        }
    }
}


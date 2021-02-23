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
        print("****WillDisplayMenuFor")
        self.menuAppeared = true
        self.ladderView.saveState()
        self.separatorView?.isHidden = true

        self.setSelections()

//        if self.ladderView.mode == .select {
//            let selectedRegions = self.ladderView.ladder.allRegionsWithMode(.selected)
//            self.ladderView.ladder.setMarksWithMode(.selected, inRegions: selectedRegions)
//            return
//        }
//        if self.ladderView.mode == .normal {
//            switch locationInLadder.specificLocation {
//            case .mark:
//                if let location = self.menuPressLocation {
//                    self.ladderView.setSelectedMark(position: location)
//                }
//            case .region:
//                // TODO: can select multiple regions in select mode, but only one works with long press.
//                // Maybe in select mode, wherever you press shouldn't matter, only selection matters.
//                if let region = locationInLadder.region {
//                    //                    self.ladderView.ladder.zone = Zone() // hide zone
//                    //                    let selectedRegions = self.ladderView.ladder.allRegionsWithMode(.selected)
//                    //                    self.ladderView.ladder.setMarksWithMode(.selected, inRegions: selectedRegions)
//                    self.ladderView.ladder.setMarksWithMode(.selected, inRegion: region)
//                    region.mode = .selected
//                }
//            case .label:
//                if let region = locationInLadder.region {
//                    region.mode = .labelSelected
//                }
//            case .zone:
//                self.ladderView.selectInZone()
//            case .ladder:
//                self.ladderView.ladder.setAllMarksWithMode(.selected)
//                for region in self.ladderView.ladder.regions {
//                    region.mode = .selected
//                }
//            default:
//                break
//            }
//        }
    }

    func setSelections() {
        guard let locationInLadder = self.longPressLocationInLadder else { return }

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
        print("****ConfigurationForMenuAtLocation")
        os_log("contextMenuInteraction(:configurationForMenuAtLocation:)", log: .action, type: .info)
        // Have to set menu state here...
//        solidAction.state = .on
        setSelections()
        let selectedMarks = self.ladderView.ladder.allMarksWithMode(.selected)
        print("****selectedMarks = \(selectedMarks)")

        // FIXME: not finding any selected marks.
//        let selectedMarks = self.ladderView.ladder.allMarksWithMode(.selected)
//        print("****selected marks \(selectedMarks)")
//        if let dominantStyle = self.dominantStyleOfSelectedMarks(selectedMarks: selectedMarks) {
//            self.solidAction.state = dominantStyle == .solid ? .on : .off
//            self.dottedAction.state = dominantStyle == .dotted ? .on : .off
//            self.dashedAction.state = dominantStyle == .dashed ? .on : .off
//        }
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
        print("****WillEndFor")
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

    fileprivate func prepareStyleActions() {
        let selectedMarks = self.ladderView.ladder.allMarksWithMode(.selected)
        if let dominantStyle = self.ladderView.dominantStyleOfMarks(marks: selectedMarks) {
            self.solidAction.state = dominantStyle == .solid ? .on : .off
            self.dottedAction.state = dominantStyle == .dotted ? .on : .off
            self.dashedAction.state = dominantStyle == .dashed ? .on : .off
        } else {
            self.solidAction.state = .off
            self.dottedAction.state = .off
            self.dashedAction.state = .off
        }
    }

    func normalModeMenu(forLocation location: CGPoint) -> UIContextMenuConfiguration? {
        print("****NormalModeMenu")
        let locationInLadder = ladderView.getLocationInLadder(position: location)
        longPressLocationInLadder = locationInLadder
        menuPressLocation = location
        setSelections()
        prepareStyleActions()
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
        print("****SelectModeMenu")
        let selectedMarks = self.ladderView.ladder.allMarksWithMode(.selected)
        print("****selectedMarks = \(selectedMarks)")
        prepareStyleActions()
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
        print("MarkContextMenuConfiguration")
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {_ in
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
                self.regionSolidStyleAction.state = region.style == .solid ? .on : .off
                self.regionDottedStyleAction.state = region.style == .dotted ? .on : .off
                self.regionDashedStyleAction.state = region.style == .dashed ? .on : .off
                self.regionInheritedStyleAction.state = region.style == .inherited ? .on : .off
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


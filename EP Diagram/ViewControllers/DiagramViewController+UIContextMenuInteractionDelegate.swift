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

    // MARK: - Delegate methods

    // Determines what menu appears.  Called first with long press
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        os_log("contextMenuInteraction(_:configurationForMenuAtLocation:)", log: .action, type: .info)
        guard ladderView.mode == .select else { return nil }
        // we crash from nexted undo groupings without these guards.
        guard !showingPDFToolbar else { return nil }
        guard !showingRotateToolbar else { return nil }
        guard !ladderView.isDragging else { return nil }
        guard !ladderView.isDraggingSelectedMarks else { return nil }
        let locationInLadder = ladderView.getLocationInLadder(position: location)
        if locationInLadder.specificLocation == .label {
            ladderView.normalizeLadder()
            cursorView.cursorIsVisible = false
            cursorView.setNeedsDisplay()
            if let region = locationInLadder.region {
                region.mode = .labelSelected
                return labelContextMenuConfiguration(at: location, region: region)
            }
        }
        return selectMenu(at: location)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        os_log("contextMenuInteraction(_:willEndFor:animator:)", log: .action, type: .info)
        ladderView.clearSelectedLabels()
    }

    // MARK: Prepare menus

    private func prepareActions() {
        os_log("prepareActions() - DiagramViewController", log: .action, type: .info)
        let selectedMarks = self.ladderView.ladder.allMarksWithMode(.selected)
        prepareStyleActions(selectedMarks: selectedMarks)
        prepareEmphasisAction(selectedMarks: selectedMarks)
        prepareBlockAction(selectedMarks: selectedMarks)
        prepareImpulseOriginAction(selectedMarks: selectedMarks)
        let selectedRegions = self.ladderView.ladder.allRegionsWithMode(.selected)
        prepareRegionStyleActions(selectedRegions: selectedRegions)
    }

    private func prepareRegionStyleActions(selectedRegions: [Region]) {
        if let dominantRegionStyle = self.ladderView.dominantMarkStyleOfRegions(regions: selectedRegions) {
            self.regionSolidStyleAction.state = dominantRegionStyle == .solid ? .on : .off
            self.regionDashedStyleAction.state = dominantRegionStyle == .dashed ? .on : .off
            self.regionDottedStyleAction.state = dominantRegionStyle == .dotted ? .on : .off
            self.regionInheritedStyleAction.state = dominantRegionStyle == .inherited ? .on : .off
        } else {
            self.regionSolidStyleAction.state = .off
            self.regionDashedStyleAction.state = .off
            self.regionDottedStyleAction.state = .off
            self.regionInheritedStyleAction.state = .off
        }
    }

    private func prepareStyleActions(selectedMarks: [Mark]) {
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

    private func prepareEmphasisAction(selectedMarks: [Mark]) {
        if let dominantEmphasis = self.ladderView.dominantEmphasisOfMarks(marks: selectedMarks) {
            self.boldEmphasisAction.state = dominantEmphasis == .bold ? .on : .off
            self.normalEmphasisAction.state = dominantEmphasis == .normal ? .on : .off
        } else {
            self.boldEmphasisAction.state = .off
            self.boldEmphasisAction.state = .off
        }
    }

    private func prepareBlockAction(selectedMarks: [Mark]) {
        if let dominantManualBlockOfMarks = self.ladderView.dominantBlockSettingOfMarks(marks: selectedMarks) {
            self.blockProximalAction.state = dominantManualBlockOfMarks == .proximal ? .on : .off
            self.blockDistalAction.state = dominantManualBlockOfMarks == .distal ? .on : .off
            self.blockNoneAction.state = dominantManualBlockOfMarks == .none ? .on : .off
            self.blockAutoAction.state = dominantManualBlockOfMarks == .auto ? .on : .off
        } else {
            self.blockProximalAction.state = .off
            self.blockDistalAction.state = .off
            self.blockNoneAction.state = .off
            self.blockAutoAction.state = .off
        }
    }

    private func prepareImpulseOriginAction(selectedMarks: [Mark]) {
        if let dominantImpulseOriginOfMarks = self.ladderView.dominantImpulseOriginOfMarks(marks: selectedMarks) {
            self.impulseOriginProximalAction.state = dominantImpulseOriginOfMarks == .proximal ? .on : .off
            self.impulseOriginDistalAction.state = dominantImpulseOriginOfMarks == .distal ? .on : .off
            self.impulseOriginNoneAction.state = dominantImpulseOriginOfMarks == .none ? .on : .off
            self.impulseOriginAutoAction.state = dominantImpulseOriginOfMarks == .auto ? .on : .off
        } else {
            self.impulseOriginProximalAction.state = .off
            self.impulseOriginDistalAction.state = .off
            self.impulseOriginNoneAction.state = .off
            self.impulseOriginAutoAction.state = .off
        }
    }

    // MARK: - Menus

    func selectMenu(at location: CGPoint) -> UIContextMenuConfiguration? {
        os_log("selectMenu(forLocation:)", log: .action, type: .info)
        // Allow long press to select in select mode
        let locationInLadder = ladderView.getLocationInLadder(position: location)
        // Handle long press on single item.
        if ladderView.noSelectionExists() && !ladderView.ladder.zone.isVisible {
            switch locationInLadder.specificLocation {
            case .mark:
                if let mark = locationInLadder.mark {
                    mark.mode = .selected
                    prepareActions()
                    return markContextMenuConfiguration(at: location)
                }
            case .label:
                if let region = locationInLadder.region {
                    region.mode = .labelSelected
                    prepareActions()
                    return labelContextMenuConfiguration(at: location, region: region)
                }
            case .region:
                if let region = locationInLadder.region {
                    region.mode = .selected
                    ladderView.ladder.setMarksWithMode(.selected, inRegion: region)
                    prepareActions()
                    return markContextMenuConfiguration(at: location)
                }
            case .ladder, .zone:
                break
            case .error:
                fatalError("Location in ladder is error.")
            }
            return nil
        }
        // Handle long press with multiple selections made
        prepareActions()
        return markContextMenuConfiguration(at: location)
    }

    func markContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        os_log("markContextMenuConfiguration(at:)", log: .action, type: .info)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {_ in
            return self.markMenu
        }
    }
    
    func labelContextMenuConfiguration(at location: CGPoint, region: Region) -> UIContextMenuConfiguration {
        os_log("labelContextMenuConfiguration(at:)", log: .action, type: .info)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let title: String
            title = L("Region\n\(region.name) — \(region.longDescription)")
            self.regionSolidStyleAction.state = region.style == .solid ? .on : .off
            self.regionDottedStyleAction.state = region.style == .dotted ? .on : .off
            self.regionDashedStyleAction.state = region.style == .dashed ? .on : .off
            self.regionInheritedStyleAction.state = region.style == .inherited ? .on : .off
            return UIMenu(title: title, children: self.labelMenu)
        }
    }
	
}


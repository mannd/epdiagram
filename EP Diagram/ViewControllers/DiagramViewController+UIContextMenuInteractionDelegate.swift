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
        // FIXME: consider long press in normal mode, to allow selection of one mark, but that won't work with cursorview because long press changes cursor to omnidirectional.  
        guard !ladderView.isDragging else { return nil }
        guard ladderView.mode == .select else { return nil }
        return selectMenu(at: location)
    }

    // MARK: Prepare menus

    private func prepareActions() {
        os_log("prepareActions() - DiagramViewController", log: .action, type: .info)
        let selectedMarks = self.ladderView.ladder.allMarksWithMode(.selected)
        prepareStyleActions(selectedMarks: selectedMarks)
        prepareEmphasisAction(selectedMarks: selectedMarks)
        prepareBlockAction(selectedMarks: selectedMarks)
        prepareImpulseOriginAction(selectedMarks: selectedMarks)
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
        prepareActions()
        if ladderView.noSelectionExists() {
            return noSelectionContextMenu(at: location)
        } else if ladderView.ladder.mode == .selected {
            return ladderContextMenuConfiguration(at: location)
        }
        return markContextMenuConfiguration(at: location)
    }

    func noSelectionContextMenu(at location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            return UIMenu(title: "No Selection Found", children: [self.noSelectionAction])
        }
    }

    func markContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        os_log("markContextMenuConfiguration(at:)", log: .action, type: .info)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) {_ in
            return self.markMenu
        }
    }

    func regionContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        os_log("regionContextMenuConfiguration(at:)", log: .action, type: .info)
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
        os_log("labelContextMenuConfiguration(at:)", log: .action, type: .info)
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
            return UIMenu(title: title, children: self.labelChildren)
        }
    }

    func zoneContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        os_log("zoneContextMenuConfiguration(at:)", log: .action, type: .info)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            // TODO: add deleteInZone action
            return UIMenu(title: L("Zone"), children: [self.styleMenu, self.straightenMenu, self.slantMenu, self.rhythmAction])
        }

    }

    func ladderContextMenuConfiguration(at location: CGPoint) -> UIContextMenuConfiguration {
        os_log("ladderContextMenuConfiguration(at:)", log: .action, type: .info)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            return self.ladderMenu
        }
    }

    func constructMenu() -> UIMenu? {
        if ladderView.noSelectionExists() {
            return UIMenu(title: "No Selection Found", children: [self.noSelectionAction])

        } else if ladderView.ladder.mode == .selected {
            return self.ladderMenu
        }
        else { return nil }
    }
}


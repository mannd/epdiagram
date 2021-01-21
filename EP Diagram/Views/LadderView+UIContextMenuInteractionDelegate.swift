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

    func getSolidAction() -> UIAction {
        return UIAction(title: L("Solid")) { action in
            self.setSolid()
        }
    }

    func getDashedAction() -> UIAction {
        return UIAction(title: L("Dashed")) { action in
            self.setDashed()
        }
    }

    func getDottedAction() -> UIAction {
        return UIAction(title: L("Dotted")) { action in
            self.setDotted()
        }
    }

    func handleMarkPressed(at location: CGPoint) -> UIContextMenuConfiguration {
        print("handleMarkPressed")
        setPressedMark(position: location)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let solid = self.getSolidAction()
            let dashed = self.getDashedAction()
            let dotted = self.getDottedAction()
            // TODO: implement set slope 
            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
            // Use .displayInline option to show menu inline with separator.
            //           let style = UIMenu(title: L("Style..."), options: .displayInline,  children: [solid, dashed, dotted])
            let unlink = UIAction(title: L("Unlink")) { action in
                self.ungroupPressedMark()
            }
            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deletePressedMark()
            }
            // FIXME: make sure we won't move grouped marks, or disconnect them when straightening.
            let straightenToProximal = UIAction(title: L("Straighten mark to proximal endpoint")) { action in
                self.straightenToProximal()
            }
            let straightenToDistal = UIAction(title: L("Straighten mark to distal endpoint")) { action in
                self.straightenToDistal()
            }
            let slantMark = UIAction(title: L("Slant")) { action in
                self.slantMark()
            }
            // TODO: Must distinguish long press on mark, label, region, zone, whole ladder (outside of ladder).
            // Create and return a UIMenu with all of the actions as children
            return UIMenu(title: L("Edit mark"), children: [style, straightenToProximal, straightenToDistal, slantMark, unlink, delete])
        }
    }

    func handleRegionPressed(at location: CGPoint) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let solid = UIAction(title: L("Solid")) { action in
//                self.setSolid()
            }
            let dashed = UIAction(title: L("Dashed")) { action in
//                self.setDashed()
            }
            let dotted = UIAction(title: L("Dotted")) { action in
//                self.setDotted()
            }
            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
            // Use .displayInline option to show menu inline with separator.
            //           let style = UIMenu(title: L("Style..."), options: .displayInline,  children: [solid, dashed, dotted])
            let unlink = UIAction(title: L("Unlink")) { action in
//                self.ungroupPressedMark()
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
            return UIMenu(title: "", children: [paste, rhythm, delete, deleteAllInRegion, deleteAllInLadder])
        }
    }

    func slantMark(angle: CGFloat, mark: Mark, region: Region) {
        let segment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        let height = segment.distal.y - segment.proximal.y
        let delta = Geometry.rightTriangleBase(withAngle: angle, height: height)
        let newSegment = Segment(proximal: segment.proximal, distal: CGPoint(x: segment.distal.x + delta, y: segment.distal.y))
        mark.segment = transformToRegionSegment(scaledViewSegment: newSegment, region: region)
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        unhighlightAllMarks()
    }
}

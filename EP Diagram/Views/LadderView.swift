//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderViewDelegate: AnyObject {
    func makeMark(location: CGFloat) -> Mark?
    func deleteMark(mark: Mark)
    func getRegionUpperBoundary(view: UIView) -> CGFloat
    func moveMark(mark: Mark, location: CGFloat, moveCursor: Bool)
    func refresh()
    func findMarkNearby(location: CGFloat) -> Mark?
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
}

class LadderView: UIView, LadderViewDelegate {

    /// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
    struct LocationInLadder {
        var region: Region?
        var mark: Mark?
        var regionSection: RegionSection
        var regionWasTapped: Bool {
            region != nil
        }
        var labelWasTapped: Bool {
            regionSection == .labelSection
        }
        var markWasTapped: Bool {
            mark != nil
        }
    }

    var movingMark: Mark? = nil
    var regionOfDragOrigin: Region? = nil

    var contentOffset: CGFloat = 0
    var leftMargin: CGFloat = 0 {
        didSet {
            ladderViewModel.margin = leftMargin
        }
    }

    var scale: CGFloat = 1.0
    weak var cursorViewDelegate: CursorViewDelegate?
    var ladderViewModel: LadderViewModel

    // How close a touch has to be to count: +/- accuracy.
    let accuracy: CGFloat = 20

    required init?(coder aDecoder: NSCoder) {
        print("ladderView init")
        ladderViewModel = LadderViewModel()
        super.init(coder: aDecoder)
        ladderViewModel.height = self.frame.height
        ladderViewModel.initialize()

        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)
        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.dragging))
        self.addGestureRecognizer(draggingPanRecognizer)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPressRecognizer)
    }


    // Touches
    @objc func singleTap(tap: UITapGestureRecognizer) {
        let tapLocation = getLocationInLadder(location: tap.location(in: self), ladderViewModel: ladderViewModel)
        PRINT("Region was single-tapped = \(tapLocation.regionWasTapped)")
        PRINT("Label was single-tapped = \(tapLocation.labelWasTapped)")
        PRINT("Mark was single-tapped = \(tapLocation.markWasTapped)")
        if tapLocation.labelWasTapped {
            if let tappedRegion = tapLocation.region {
                if tappedRegion.selected {
                    tappedRegion.selected = false
                    ladderViewModel.activeRegion = nil
                }
                else { // !tappedRegion.selected
                    ladderViewModel.activeRegion = tappedRegion
                    cursorViewDelegate?.hideCursor(hide: true)
                }
                cursorViewDelegate?.hideCursor(hide: true)
                cursorViewDelegate?.unattachMark()
            }
        }
        else if (tapLocation.regionWasTapped) {
            if let tappedRegion = tapLocation.region {
                if !tappedRegion.selected {
                    ladderViewModel.activeRegion = tappedRegion
                }
                // make mark and attach cursor
                if let mark = tapLocation.mark {
                    if mark.attached {
                        // FIXME: attached and selected maybe the same thing, eliminate duplication.
                        PRINT("Unattaching mark")
                        mark.attached = false
                        mark.selected = false
                        cursorViewDelegate?.hideCursor(hide: true)
                        cursorViewDelegate?.unattachMark()
                    }
                    else {
                        PRINT("Attaching mark")
                        mark.attached = true
                        mark.selected = true
                        cursorViewDelegate?.attachMark(mark: mark)
                        cursorViewDelegate?.moveCursor(location: mark.position.proximal.x)
                        cursorViewDelegate?.hideCursor(hide: false)
                    }
                }
                else { // make mark and attach cursor
                    PRINT("make mark and attach cursor")
                    let mark = makeMark(location: tap.location(in: self).x)
                    if let mark = mark {
                        ladderViewModel.inactivateMarks()
                        mark.attached = true
                        mark.selected = true
                        cursorViewDelegate?.attachMark(mark: mark)
                        cursorViewDelegate?.moveCursor(location: mark.position.proximal.x)
                        cursorViewDelegate?.hideCursor(hide: false)
                    }
                }
            }
        }
        setNeedsDisplay()
        cursorViewDelegate?.refresh()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        PRINT("Double tap on ladder view")
        // delete mark
        let tapLocation = getLocationInLadder(location: tap.location(in: self), ladderViewModel: ladderViewModel)
        if tapLocation.markWasTapped {
            if let mark = tapLocation.mark {
                deleteMark(mark: mark)
                cursorViewDelegate?.hideCursor(hide: true)
            }
        }


    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        PRINT("Dragging on ladder view")
        if pan.state == .began {
            PRINT("dragging began")
            let location = getLocationInLadder(location: pan.location(in: self), ladderViewModel: ladderViewModel)
            if let mark = location.mark {
                movingMark = mark
                if let region = location.region {
                    regionOfDragOrigin = region
                }
            }
        }
        if pan.state == .changed {
            PRINT("dragging state changed")
            if let mark = movingMark {
                if mark.attached {
                    moveMark(mark: mark, location: pan.location(in: self).x, moveCursor: true)
                }
                else {
                    PRINT("dragging mark without cursor.")
                    let location = getLocationInLadder(location: pan.location(in: self), ladderViewModel: ladderViewModel)
                    if let region = location.region {
                        let regionName = region.name
                        let originalRegionName = regionOfDragOrigin?.name
                        PRINT("Region of origin = \(String(describing: originalRegionName))")
                        PRINT("Region dragged into = \(regionName)")
                        /* Logic here:
                         drag started near a mark
                         mark has no attached cursor
                         drag enters region different from region of origin
                         region is conduction region
                         drag is in the forward time direction (at least not negative!)
                         THEN
                         Add connection to mark
                         Draw line from end of mark to drag point
                         ON pan.state.ended
                         if near next region (non conducting)
                         attach to mark nearby otherwise create mark
                         BUT if in middle of region
                         offer popup menu with choices

                         More logic
                         single tap in conduction region create ectopic with two connections
                         drag on these connections to connect
                         flash mark about to be connected or created
                         double tap on connector to delete it
                         double tap on mark deletes its connectors too


                         */
                    }
                }
                setNeedsDisplay()
            }
        }
        if pan.state == .ended {
            PRINT("dragging state ended")
            movingMark = nil
            regionOfDragOrigin = nil
        }
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        let location = getLocationInLadder(location: press.location(in: self), ladderViewModel: ladderViewModel)
        PRINT("long press at \(location) ")
        // TODO: menu (e.g. "clear marks in region, etc.")
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter location: point to be processed
    /// - Parameter ladderViewModel: ladderViewModel in use
    func getLocationInLadder(location: CGPoint, ladderViewModel: LadderViewModel) -> LocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        for region in (ladderViewModel.regions()) {
            if location.y > region.upperBoundary && location.y < region.lowerBoundary {
                tappedRegion = region
            }
        }
        if let tappedRegion = tappedRegion {
            if location.x < leftMargin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(location: location.x, mark: mark) {
                        tappedMark = mark
                        break outerLoop
                    }
                }
            }
        }
        return LocationInLadder(region: tappedRegion, mark: tappedMark, regionSection: tappedRegionSection)
    }

    private func nearMark(location: CGFloat, mark: Mark) -> Bool {
//        return location < mark.end && location > mark.start
        return location < translateToRelativeLocation(location: mark.position.distal.x, offset: contentOffset, scale: scale) + accuracy && location > translateToRelativeLocation(location: mark.position.proximal.x, offset: contentOffset, scale: scale) - accuracy
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        print("LadderView draw()")
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel.draw(rect: rect, offset: contentOffset, scale: scale, context: context)
        }
    }

    func reset() {
        print("LadderView height = \(self.frame.height)")
        ladderViewModel.height = self.frame.height
        ladderViewModel.reset()
    }

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionUpperBoundary(view: UIView) -> CGFloat {
        let location = CGPoint(x: 0, y: ladderViewModel.activeRegion?.upperBoundary ?? 0)
        return convert(location, to: view).y
    }

    func makeMark(location: CGFloat) -> Mark? {
        return ladderViewModel.addMark(location: translateToAbsoluteLocation(location: location, offset: contentOffset, scale: scale))
    }

    func addMark(location: CGFloat) -> Mark? {
        return ladderViewModel.addMark(location: location / scale)
    }

    func deleteMark(mark: Mark) {
        PRINT("Delete mark \(mark)")
        ladderViewModel.deleteMark(mark: mark)
        cursorViewDelegate?.hideCursor(hide: true)
        cursorViewDelegate?.refresh()
        setNeedsDisplay()
    }

    func refresh() {
        setNeedsDisplay()
    }

    func moveMark(mark: Mark, location: CGFloat, moveCursor: Bool) {
        mark.position.proximal.x = translateToAbsoluteLocation(location: location, offset: contentOffset, scale: scale)
        mark.position.distal.x = mark.position.proximal.x
        if moveCursor {
            cursorViewDelegate?.moveCursor(location: mark.position.proximal.x)
            cursorViewDelegate?.refresh()
        }
    }

    func findMarkNearby(location: CGFloat) -> Mark? {
        if let activeRegion = ladderViewModel.activeRegion {
            let relativeLocation = translateToRelativeLocation(location: location, offset: contentOffset, scale: scale)
            for mark in activeRegion.marks {
                if abs(mark.position.proximal.x - relativeLocation) < accuracy {
                    return mark
                }
            }
        }
        return nil
    }

    // TODO: This doesn't work, region not being selected
    func setActiveRegion(regionNum: Int) {
        ladderViewModel.activeRegion = ladderViewModel.regions()[regionNum]
        ladderViewModel.activeRegion?.selected = true
    }

    func hasActiveRegion() -> Bool {
        return ladderViewModel.activeRegion != nil
    }
}

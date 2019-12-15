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
    func getRegionProximalBoundary(view: UIView) -> CGFloat
    func getRegionDistalBoundary(view: UIView) -> CGFloat
    func getRegionMidPoint(view: UIView) -> CGFloat
    func moveMark(mark: Mark, location: CGFloat, moveCursor: Bool)
    func refresh()
    func findMarkNearby(location: CGFloat) -> Mark?
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
    func getHeight() -> CGFloat
    func getTopOfLadder(view: UIView) -> CGFloat
}

// TODO: Marks only know absolute positioning (not affected by offset or scale and with
// y position between 0 and 1.0), but need to seemless convert all screen positions
// so that LadderView never has to worry about the raw Mark level.  Perhaps need a
// MarkViewModel class for this.
// OR: Maybe Mark should just handle this.
class LadderView: UIView, LadderViewDelegate {

    /// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
    struct LocationInLadder {
        var region: Region?
        var mark: Mark?
        var regionSection: RegionSection
        var regionDivision: RegionDivision
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

    // These are passed from the viewController, and in turn passed to the ladderViewModel
    var leftMargin: CGFloat = 0 {
        didSet {
            ladderViewModel.margin = leftMargin
        }
    }
    var offset: CGFloat = 0 {
        didSet {
            ladderViewModel.offset = offset
        }
    }
    var scale: CGFloat = 1 {
        didSet {
            ladderViewModel.scale = scale
        }
    }

    weak var cursorViewDelegate: CursorViewDelegate?
    var ladderViewModel: LadderViewModel

    // How close a touch has to be to count: +/- accuracy.
    let accuracy: CGFloat = 20

    required init?(coder aDecoder: NSCoder) {
        PRINT("ladderView init")
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
        PRINT("LadderView.singleTap()")
        let tapLocation = getLocationInLadder(location: tap.location(in: self), ladderViewModel: ladderViewModel)
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
                        unselectMark(mark)
                        cursorViewDelegate?.hideCursor(hide: true)
                        cursorViewDelegate?.unattachMark()
                    }
                    else {
                        PRINT("Attaching mark")
                        mark.attached = true
                        mark.anchor = getAnchor(regionDivision: tapLocation.regionDivision)
                        selectMark(mark)
                        cursorViewDelegate?.attachMark(mark: mark)
                        let anchorLocation: CGFloat
                        switch mark.anchor {
                        case .distal:
                            anchorLocation = mark.position.distal.x
                        case .middle:
                            anchorLocation = mark.midpoint().x
                        case .proximal:
                            anchorLocation = mark.position.proximal.x
                        case .none:
                            anchorLocation = mark.position.proximal.x
                        }
                        cursorViewDelegate?.moveCursor(location: anchorLocation)
                        cursorViewDelegate?.hideCursor(hide: false)
                    }
                }
                else { // make mark and attach cursor
                    PRINT("make mark and attach cursor")
                    let mark = makeMark(location: tap.location(in: self).x)
                    if let mark = mark {
                        ladderViewModel.inactivateMarks()
                        mark.attached = true
                        mark.anchor = getAnchor(regionDivision: tapLocation.regionDivision)
                        selectMark(mark)
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

    func markMidpoint(mark: Mark) -> CGFloat {
        return (mark.position.distal.x - mark.position.proximal.x) / 2.0 + mark.position.proximal.x
    }

    fileprivate func getAnchor(regionDivision: RegionDivision) -> Anchor {
        let anchor: Anchor
        switch regionDivision {
        case .proximal:
            anchor = .proximal
        case .middle:
            anchor = .middle
        case .distal:
            anchor = .distal
        case .none:
            anchor = .none
        }
        return anchor
    }

    fileprivate func selectMark(_ mark: Mark) {
        mark.highlight = .all
    }

    fileprivate func unselectMark(_ mark: Mark) {
        mark.highlight = .none
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

    // See below.  We get relative points for relavent regions and return them in an dictionary
    /*
     Need proximalRegion?, distalRegion?
     for each mark in proximal region, get mark and distal relative location
     for each mark in distal region, get mark and proximal relative location
     get moving mark compare proximal relative location with 1st set above and compare distal location with
     2nd set above.
     If either location is + or - connectionAccuracy value, then highlight and snap moving mark to the
     immovable mark above or below.
     If drag ends, connect the marks.
     */


    // TODO: Need some connection logic here.  If the proximal end of the mark or the distal end of
    // the mark, or both, brush a makr in a region proximal or distal to it, it becomes "potentiallyConnected."
    // This means the two marks are highlighted, and if the drag ends there, the marks become connected, (and
    // snap into position if there is a gap between them, favoring the position of A and V over AV, i.e. over
    // a conduction region) with some animation or coloration to show this.
    // Connected marks move together.  Long press is needed to disconnect the marks.

    // To do this, we need an array of proximal relative points and distal relative points.  So we need
    // the marks of the region proximal and region distal (if they exist).  From these marks, we need the
    // distal points of the proximal region's marks, and the proximal points of the distal region's marks.
    // We also need any connected marks to make sure we move them to (i.e. update their positions).
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
        var tappedRegionDivision: RegionDivision = .none
        for region in ladderViewModel.regions {
            if location.y > region.proximalBoundary && location.y < region.distalBoundary {
                tappedRegion = region
                tappedRegionDivision = getTappedRegionDivision(region: region, location: location.y)
                PRINT("tappedRegionDivision = \(tappedRegionDivision)")
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
                        PRINT("tap near mark")
                        tappedMark = mark
                        break outerLoop
                    }
                }
            }
        }
        return LocationInLadder(region: tappedRegion, mark: tappedMark, regionSection: tappedRegionSection, regionDivision: tappedRegionDivision)
    }

    // TODO: Move to LadderViewModel
    private func nearMark(location: CGFloat, mark: Mark) -> Bool {
        let maxX = max(Common.translateToRelativeLocation(location: mark.position.distal.x, offset: offset, scale: scale), Common.translateToRelativeLocation(location: mark.position.proximal.x, offset: offset, scale: scale))
        let minX = min(Common.translateToRelativeLocation(location: mark.position.distal.x, offset: offset, scale: scale), Common.translateToRelativeLocation(location: mark.position.proximal.x, offset: offset, scale: scale))
        return location < maxX + accuracy && location > minX - accuracy
    }

    private func getTappedRegionDivision(region: Region, location: CGFloat) -> RegionDivision {
        guard  location > region.proximalBoundary && location < region.distalBoundary else {
            return .none
        }
        if location < region.proximalBoundary + 0.25 * (region.distalBoundary - region.proximalBoundary) {
            return .proximal
        }
        else if location < region.proximalBoundary + 0.75 * (region.distalBoundary - region.proximalBoundary) {
            return .middle
        }
        else {
            return .distal
        }
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        PRINT("LadderView draw()")
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel.draw(rect: rect, context: context)
        }
    }

    func reset() {
        PRINT("LadderView height = \(self.frame.height)")
        ladderViewModel.height = self.frame.height
        ladderViewModel.reset()
    }

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionProximalBoundary(view: UIView) -> CGFloat {
        let location = CGPoint(x: 0, y: ladderViewModel.activeRegion?.proximalBoundary ?? 0)
        return convert(location, to: view).y
    }

    func getTopOfLadder(view: UIView) -> CGFloat {
        let location = CGPoint(x: 0, y: ladderViewModel.regions[0].proximalBoundary)
        return convert(location, to: view).y
    }

    func getRegionMidPoint(view: UIView) -> CGFloat {
        guard let activeRegion = ladderViewModel.activeRegion else { return 0 }
        let location = CGPoint(x: 0, y: (activeRegion.distalBoundary -  activeRegion.proximalBoundary) / 2 + activeRegion.proximalBoundary)
        return convert(location, to: view).y
    }

    func getRegionDistalBoundary(view: UIView) -> CGFloat {
        let location = CGPoint(x: 0, y: ladderViewModel.activeRegion?.distalBoundary ?? 0)
        return convert(location, to: view).y
    }

    func getHeight() -> CGFloat {
        return ladderViewModel.height
    }

    func makeMark(location: CGFloat) -> Mark? {
  //      let displacement = Displacement(rect: CGRect(), offset: contentOffset, scale: scale)
        return ladderViewModel.addMark(location: Common.translateToAbsoluteLocation(location: location, offset: offset, scale: scale))
//        return ladderViewModel.addMark(relativePosition: MarkPosition(proximal: CGPoint(x: location, y: 0), distal: CGPoint(x: location, y: 1.0)), displacement: displacement)
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
        switch mark.anchor {
        case .proximal:
            mark.position.proximal.x = Common.translateToAbsoluteLocation(location: location, offset: offset, scale: scale)
        case .middle:
            // Calculate difference between prox and distal x
//            let diff = translateToAbsoluteLocation(location: mark.position.proximal.x, offset: contentOffset, scale: scale) - translateToAbsoluteLocation(location: mark.position.distal.x, offset: contentOffset, scale: scale)

            mark.position.proximal.x = Common.translateToAbsoluteLocation(location: location , offset: offset, scale: scale)
            mark.position.distal.x = Common.translateToAbsoluteLocation(location: location, offset: offset, scale: scale)

        case .distal:
            mark.position.distal.x = Common.translateToAbsoluteLocation(location: location, offset: offset, scale: scale)
        case .none:
            break
        }
        if moveCursor {
            cursorViewDelegate?.moveCursor(location: mark.position.proximal.x)
            cursorViewDelegate?.refresh()
        }
    }

    func findMarkNearby(location: CGFloat) -> Mark? {
        if let activeRegion = ladderViewModel.activeRegion {
            let relativeLocation = Common.translateToRelativeLocation(location: location, offset: offset, scale: scale)
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
        ladderViewModel.activeRegion = ladderViewModel.regions[regionNum]
        ladderViewModel.activeRegion?.selected = true
    }

    func hasActiveRegion() -> Bool {
        return ladderViewModel.activeRegion != nil
    }
}

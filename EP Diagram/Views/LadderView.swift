//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderViewDelegate: AnyObject {
    func getRegionProximalBoundary(view: UIView) -> CGFloat
    func getRegionDistalBoundary(view: UIView) -> CGFloat
    func getRegionMidPoint(view: UIView) -> CGFloat
    func getAttachedMarkLadderViewPositionY(view: UIView) -> CGFloat?
    func refresh()
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
    func getHeight() -> CGFloat
    func getTopOfLadder(view: UIView) -> CGFloat
    func unhighlightMarks()
    func deleteMark(_ mark: Mark?)
    @discardableResult func addMark(positionX: CGFloat) -> Mark?
    func linkNearbyMarks(mark: Mark)
    func moveMark(mark: Mark, position: CGPoint, moveCursor: Bool)
}

final class LadderView: ScaledView {
    private let ladderPaddingMultiplier: CGFloat = 0.5
    private let accuracy: CGFloat = 20
    private let lowerLimitMarkHeight: CGFloat = 0.1
    private let lowerlimitMarkWidth: CGFloat = 20

    // variables that need to eventually be preferences
    var lineWidth: CGFloat = 2
    var red = UIColor.systemRed
    var blue = UIColor.systemBlue
    var unselectedColor = UIColor.black
    var selectedColor = UIColor.magenta
    var markLineWidth: CGFloat = 2
    var connectedLineWidth: CGFloat = 4

    private var ladder: Ladder = Ladder.defaultLadder()
    private var activeRegion: Region? {
        set(value) {
            ladder.activeRegion = value
            activateRegion(region: ladder.activeRegion)
        }
        get {
            return ladder.activeRegion
        }
    }
    private var attachedMark: Mark?
    private var pressedMark: Mark?
    private var movingMark: Mark?
    private var regionOfDragOrigin: Region?
    private var regionProxToDragOrigin: Region?
    private var regionDistalToDragOrigin: Region?
    private var dragCreatedMark: Mark?
    private var dragOriginDivision: RegionDivision = .none

    var leftMargin: CGFloat = 0
    private var height: CGFloat = 0
    private var regionUnitHeight: CGFloat = 0

    weak var cursorViewDelegate: CursorViewDelegate?

    override var canBecomeFirstResponder: Bool { return true }

    // MARK: - init

    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoad()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didLoad()
    }

    private func didLoad() {
        height = self.frame.height
        if #available(iOS 13.0, *) {
            unselectedColor = UIColor.label
        }
        initializeRegions()

        // Draw border around view.
        layer.masksToBounds = true
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 2

        // Set up touches.
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

    private func initializeRegions() {
        regionUnitHeight = getRegionUnitHeight(ladder: ladder)
        var regionBoundary = regionUnitHeight * ladderPaddingMultiplier
        for region: Region in ladder.regions {
            let regionHeight = CGFloat(region.unitHeight) * regionUnitHeight
            region.proximalBoundary = regionBoundary
            region.distalBoundary = regionBoundary + regionHeight
            regionBoundary += regionHeight
        }
        activeRegion = ladder.regions[0]
    }

    private func getRegionUnitHeight(ladder: Ladder) -> CGFloat {
        var numRegionUnits = 0
        for region: Region in ladder.regions {
            numRegionUnits += region.unitHeight
        }
        // we need padding above and below, so...
        let padding = Int(ladderPaddingMultiplier * 2)
        numRegionUnits += padding
        return height / CGFloat(numRegionUnits)
    }

    // MARK: - Touches

    @objc func singleTap(tap: UITapGestureRecognizer) {
        let position = tap.location(in: self)
        let tapLocationInLadder = getLocationInLadder(position: position)
        if tapLocationInLadder.labelWasTapped {
            assert(tapLocationInLadder.region != nil, "Label tapped, but region is nil!")
            if let region = tapLocationInLadder.region {
                labelWasTapped(labelRegion: region)
                cursorViewDelegate?.hideCursor(true)
                cursorViewDelegate?.unattachAttachedMark()
            }
        }
        else if (tapLocationInLadder.regionWasTapped) {
            regionWasTapped(tapLocationInLadder: tapLocationInLadder, positionX: position.x, cursorViewDelegate: cursorViewDelegate)
        }
        cursorViewDelegate?.refresh()
        setNeedsDisplay()
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter position: point to be processed
    func getLocationInLadder(position: CGPoint) -> LocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        var tappedRegionDivision: RegionDivision = .none
        var tappedAnchor: Anchor = .none
        for region in ladder.regions {
            if position.y > region.proximalBoundary && position.y < region.distalBoundary {
                tappedRegion = region
                tappedRegionDivision = getTappedRegionDivision(region: region, positionY: position.y)
            }
        }
        if let tappedRegion = tappedRegion {
            if position.x < leftMargin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(point: position, mark: mark, region: tappedRegion, accuracy: accuracy) {
                        tappedMark = mark
                        tappedAnchor = nearMarkPosition(point: position, mark: mark, region: tappedRegion)
                        break outerLoop
                    }
                }
            }
        }
        return LocationInLadder(region: tappedRegion, mark: tappedMark, regionSection: tappedRegionSection, regionDivision: tappedRegionDivision, markAnchor: tappedAnchor)
    }

    private func getTappedRegionDivision(region: Region, positionY: CGFloat) -> RegionDivision {
        guard  positionY > region.proximalBoundary && positionY < region.distalBoundary else {
            return .none
        }
        if positionY < region.proximalBoundary + 0.25 * (region.distalBoundary - region.proximalBoundary) {
            return .proximal
        }
        else if positionY < region.proximalBoundary + 0.75 * (region.distalBoundary - region.proximalBoundary) {
            return .middle
        }
        else {
            return .distal
        }
    }

    private func labelWasTapped(labelRegion: Region) {
        if labelRegion.selected {
            labelRegion.selected = false
            activeRegion = nil
        }
        else { // !tappedRegion.selected
            activeRegion = labelRegion
        }
    }

    private func regionWasTapped(tapLocationInLadder: LocationInLadder, positionX: CGFloat, cursorViewDelegate: CursorViewDelegate?) {
        assert(tapLocationInLadder.region != nil, "Region tapped, but is nil!")
        if let tappedRegion = tapLocationInLadder.region {
            if !tappedRegion.selected {
                activeRegion = tappedRegion
            }
            if let mark = tapLocationInLadder.mark {
                markWasTapped(mark: mark, tapLocationInLadder: tapLocationInLadder, cursorViewDelegate: cursorViewDelegate)
            }
            else if cursorViewDelegate?.cursorIsVisible() ?? false {
                unhighlightMarks()
                cursorViewDelegate?.hideCursor(true)
                cursorViewDelegate?.unattachAttachedMark()
            }
            else { // make mark and attach cursor
                P("make mark and attach cursor")
                let mark = makeMark(positionX: positionX)
                if let mark = mark {
                    P("mark made")
                    inactivateMarks()
                    mark.attached = true
                    mark.anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
                    selectMark(mark)
                    cursorViewDelegate?.attachMark(mark)
                    cursorViewDelegate?.moveCursor(cursorViewPositionX: mark.segment.proximal.x)
                    cursorViewDelegate?.hideCursor(false)
                }
            }
        }
    }

    /// Response to tapped mark in LadderView.  Returns marks anchor position.x or nil
    /// if no mark tapped.
    /// - Parameter tapLocationInLadder: the tapped LocationInLadder
    private func markWasTapped(mark: Mark?, tapLocationInLadder: LocationInLadder, cursorViewDelegate: CursorViewDelegate?) {
        if let mark = mark {
            if mark.attached {
                let anchor = tapLocationInLadder.markAnchor
                // Just reanchor cursor
                if anchor != mark.anchor {
                    mark.anchor = anchor
                    let anchorPositionX = mark.getAnchorPositionX()
                    cursorViewDelegate?.moveCursor(cursorViewPositionX: anchorPositionX)
                }
                else {
                    // Unattach mark and hide cursor
                    mark.attached = false
                    unhighlightMarks()
                    unselectMark(mark)
                    cursorViewDelegate?.hideCursor(true)
                    cursorViewDelegate?.unattachAttachedMark()
                }
            }
            else {
                mark.attached = true
                mark.anchor = tapLocationInLadder.markAnchor
                selectMark(mark)
                cursorViewDelegate?.attachMark(mark)
                let anchorPosition = mark.getAnchorPosition()
                //                P("anchorPosition = \(anchorPosition)")
                //                let adjustedAnchorPosition = Common.translateToLadderViewPosition(regionPosition: anchorPosition, region: activeRegion!, offsetX: offsetX, scale: scale)
                //                P("ladderView anchorPosition = \(adjustedAnchorPosition)")
                //                let height = cursorViewDelegate?.convertPoint(adjustedAnchorPosition).y
                //                if let height = height {
                //                    cursorViewDelegate?.setHeight(height)
                //                    P("height = \(height)")
                //                }
                cursorViewDelegate?.moveCursor(cursorViewPositionX: anchorPosition.x)
                cursorViewDelegate?.hideCursor(false)
            }
        }
    }
    /// - Parameters:
    ///   - position: position of, say a tap on the screen
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    ///   - accuracy: how close does it have to be?
    func nearMark(point: CGPoint, mark: Mark, region: Region, accuracy: CGFloat) -> Bool {
        let linePoint1 = translateToLadderViewPosition(regionPosition: mark.segment.proximal, region: region)
        let linePoint2 = translateToLadderViewPosition(regionPosition: mark.segment.distal, region: region)
        let distance = Common.distance(linePoint1: linePoint1, linePoint2: linePoint2, point: point)
        return distance < accuracy
    }

    func markWasTapped(position: CGPoint) -> Bool {
        return getLocationInLadder(position: position).markWasTapped
    }

    /// Determine which anchor a point is closest to.
    /// - Parameters:
    ///   - point: a point in ladder view coordinates
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    func nearMarkPosition(point: CGPoint, mark: Mark, region: Region) -> Anchor {
        // Use region coordinates
        let regionPoint = translateToRegionPosition(ladderViewPosition: point, region: region)
        let proximalDistance = Common.distance(mark.segment.proximal, regionPoint)
        let middleDistance = Common.distance(mark.midpoint(), regionPoint)
        let distalDistance = Common.distance(mark.segment.distal, regionPoint)
        let minimumDistance = min(proximalDistance, middleDistance, distalDistance)
        if minimumDistance == proximalDistance {
            return .proximal
        }
        else if minimumDistance == middleDistance {
            return .middle
        }
        else if minimumDistance == distalDistance {
            return .distal
        }
        else {
            return .none
        }
    }

    func makeMark(positionX relativePositionX: CGFloat) -> Mark? {
        return addMark(absolutePositionX: Common.translateToRegionPositionX(ladderViewPositionX: relativePositionX, offset: offsetX, scale: scale))
    }

    func addMark(absolutePositionX: CGFloat) -> Mark? {
        return ladder.addMarkAt(absolutePositionX)
    }

//    func addMark(positionX screenPositionX: CGFloat) -> Mark? {
//        P("Add mark at \(screenPositionX)")
//        return ladder.addMarkAt(unscaledRelativePositionX(relativePositionX: screenPositionX))
//    }

    func inactivateMarks() {
        for region in ladder.regions {
            for mark in region.marks {
                mark.highlight = .none
                mark.attached = false
            }
        }
    }

    func getAnchor(regionDivision: RegionDivision) -> Anchor {
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

    private func setMarkSelection(_ mark: Mark?, highlight: Mark.Highlight) {
        if let mark = mark {
            mark.highlight = highlight
            let attachedMarks = mark.attachedMarks
            for proximalMark in attachedMarks.proximal {
                proximalMark.highlight = highlight
            }
            for distalMark in attachedMarks.distal {
                distalMark.highlight = highlight
            }
        }
    }

    func unselectMark(_ mark: Mark?) {
        setMarkSelection(mark, highlight: .none)
    }

    func selectMark(_ mark: Mark?) {
        setMarkSelection(mark, highlight: .all)
    }


    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if deleteMark(position: tap.location(in: self), cursorViewDelegate: cursorViewDelegate) {
            setNeedsDisplay()
        }
    }

    /// Deletes mark if there is one at position.  Returns true if position corresponded to a mark.
    /// - Parameter position: position of potential mark
    func deleteMark(position: CGPoint, cursorViewDelegate: CursorViewDelegate?) -> Bool {
        let tapLocationInLadder = getLocationInLadder(position: position)
        if tapLocationInLadder.markWasTapped {
            if let mark = tapLocationInLadder.mark {
                let region = tapLocationInLadder.region
                ladder.deleteMark(mark: mark, region: region)
                ladder.setHighlight(highlight: .none)
                cursorViewDelegate?.hideCursor(true)
                cursorViewDelegate?.refresh()
                return true
            }
        }
        return false
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        if dragMark(position: pan.location(in: self), state: pan.state) {
            setNeedsDisplay()
        }
    }

    /// dragging mark.  Returns true if LadderView needs redisplay.
    /// - Parameters:
    ///   - position: CGPoint, position of drag point
    ///   - state: state of dragging
    ///   - cursorViewDelegate: CursorViewDelegate from LadderView
    func dragMark(position: CGPoint, state: UIPanGestureRecognizer.State) -> Bool {
        var needsDisplay = false
        if state == .began {
            let locationInLadder = getLocationInLadder(position: position)
            if let region = locationInLadder.region {
                regionOfDragOrigin = region
                regionProxToDragOrigin = ladder.getRegionBefore(region: region)
                regionDistalToDragOrigin = ladder.getRegionAfter(region: region)
                activeRegion = region
            }
            if let mark = locationInLadder.mark {
                if mark.attached {
                    movingMark = mark
                }
            }
            if movingMark == nil {
                // reset marks to be unattached and unhighlighted
                cursorViewDelegate?.unattachAttachedMark()
                cursorViewDelegate?.hideCursor(true)
                //                attachedMark?.attached = false
                //                attachedMark = nil
                unhighlightMarks()
                cursorViewDelegate?.refresh()

                dragOriginDivision = locationInLadder.regionDivision
                switch dragOriginDivision {
                case .proximal:
                    dragCreatedMark = makeMark(positionX: position.x)
                    dragCreatedMark?.segment.proximal.y = 0
                    dragCreatedMark?.segment.distal.y = 0.5
                case .middle:
                    dragCreatedMark = makeMark(positionX: position.x)
                    // TODO: REFACTOR
                    dragCreatedMark?.segment.proximal.y = (position.y - regionOfDragOrigin!.proximalBoundary) / (regionOfDragOrigin!.distalBoundary - regionOfDragOrigin!.proximalBoundary)
                    dragCreatedMark?.segment.distal.y = 0.75
                case .distal:
                    dragCreatedMark = makeMark(positionX: position.x)
                    dragCreatedMark?.segment.proximal.y = 0.5
                    dragCreatedMark?.segment.distal.y = 1
                case .none:
                    P("none")
                }
                highlightNearbyMarks(dragCreatedMark)
            }
        }
        if state == .changed {
            if let mark = movingMark {
                if mark.attached {
                    moveMark(mark: mark, screenPositionX: position.x)
                    let anchorPositionX = mark.getAnchorPositionX()
                    cursorViewDelegate?.moveCursor(cursorViewPositionX: anchorPositionX)
                    cursorViewDelegate?.refresh()
                }
            }
            else {
                let locationInLadder = getLocationInLadder(position: position)
                if regionProxToDragOrigin === locationInLadder.region {
                }
                else if regionDistalToDragOrigin === locationInLadder.region {
                }
                else if regionOfDragOrigin === locationInLadder.region {
                    switch dragOriginDivision {
                    case .proximal:
                        dragCreatedMark?.segment.distal = translateToRegionPosition(ladderViewPosition: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height)
                    case .distal:
                        dragCreatedMark?.segment.proximal = translateToRegionPosition(ladderViewPosition: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height)
                    case .middle:
                        dragCreatedMark?.segment.distal = translateToRegionPosition(ladderViewPosition: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height)
                    default:
                        break
                    }
                    highlightNearbyMarks(dragCreatedMark)
                }
            }
            needsDisplay = true
        }
        if state == .ended {
            if let mark = movingMark {
                linkNearbyMarks(mark: mark)
            }
            if let dragCreatedMark = dragCreatedMark {
                if dragCreatedMark.height < lowerLimitMarkHeight && dragCreatedMark.width < lowerlimitMarkWidth {
                    deleteMark(dragCreatedMark)
                }
                else {
                    linkNearbyMarks(mark: dragCreatedMark)
                }
            }
            // FIXME: At this point determine if there are anchors to other marks, anchors to the prox and distal boundaries, which end is the block end, etc.
            if let proximalY = dragCreatedMark?.segment.proximal.y, let distalY = dragCreatedMark?.segment.distal.y {
                if proximalY > distalY {
                    dragCreatedMark?.swapEnds()
                }
            }
            unhighlightMarks()
            movingMark = nil
            dragCreatedMark = nil
            regionOfDragOrigin = nil
            regionProxToDragOrigin = nil
            regionDistalToDragOrigin = nil
            dragOriginDivision = .none
            needsDisplay = true
        }
        return needsDisplay
    }

    private func highlightNearbyMarks(_ mark: Mark?) {
        guard let mark = mark else { return }
        var minimum: CGFloat = 10
        minimum = minimum / scale
        let nearbyProximalMarks: [Mark] = getNearbyMarks(mark: mark, minimum: minimum).proximalMarks
        let nearbyDistalMarks: [Mark] = getNearbyMarks(mark: mark, minimum: minimum).distalMarks
        let nearbyMiddleMarks: [Mark] = getNearbyMarks(mark: mark, minimum: minimum).middleMarks
        if nearbyProximalMarks.count > 0 {
            for nearbyMark in nearbyProximalMarks {
                nearbyMark.highlight = .all
            }
        }
        else {
            ladder.setHighlight(highlight: .none, region: ladder.getRegionBefore(region: activeRegion))
        }
        if nearbyDistalMarks.count > 0 {
            for nearbyMark in nearbyDistalMarks {
                nearbyMark.highlight = .all
            }
        }
        else {
            ladder.setHighlight(highlight: .none, region: ladder.getRegionAfter(region: activeRegion))
        }
        if nearbyMiddleMarks.count > 0 {
            for nearbyMark in nearbyMiddleMarks {
                nearbyMark.highlight = .all
            }
        }
        else {
            ladder.setHighlight(highlight: .none, region: activeRegion)
        }
    }

    func getNearbyMarks(mark: Mark, minimum: CGFloat) -> NearbyMarks {
        var proximalMarks: [Mark] = []
        var distalMarks: [Mark] = []
        var middleMarks: [Mark] = []
        // check proximal region.  Note that only marks that abut the neighboring region are checked.
        if let proximalRegion = ladder.getRegionBefore(region: activeRegion), mark.segment.proximal.y == 0 {
            for neighboringMark in proximalRegion.marks {
                let ladderViewPositionXMark = translateToLadderViewPositionX(regionPositionX: mark.segment.proximal.x)
                let ladderViewPositionNeighboringXMark = translateToLadderViewPositionX(regionPositionX: neighboringMark.segment.distal.x)
                if abs(ladderViewPositionXMark - ladderViewPositionNeighboringXMark) < minimum {
                    proximalMarks.append(neighboringMark)
                }
            }
        }
        // check distal region
        if let distalRegion = ladder.getRegionAfter(region: activeRegion), mark.segment.distal.y == 1.0 {
            for neighboringMark in distalRegion.marks {
                let ladderViewPositionXMark = translateToLadderViewPositionX(regionPositionX: mark.segment.distal.x)
                let ladderViewPositionNeighboringXMark = translateToLadderViewPositionX(regionPositionX: neighboringMark.segment.proximal.x)
                if abs(ladderViewPositionXMark - ladderViewPositionNeighboringXMark) < minimum {
                    distalMarks.append(neighboringMark)
                }
            }
        }
        // check in the same region
        if let region = activeRegion {
            for neighboringMark in region.marks {
                if !(neighboringMark === mark) {
                    // FIXME: distance must use screen coordinates, not ladder coordinates.
                    // compare distance of 2 line segments here and append
                    let ladderViewPositionNeighboringMarkSegment = translateToLadderViewSegment(regionSegment: neighboringMark.segment, region: region)
                    let ladderViewPositionMarkProximal = translateToLadderViewPosition(regionPosition: mark.segment.proximal, region: region)
                    let ladderViewPositionMarkDistal = translateToLadderViewPosition(regionPosition: mark.segment.distal, region: region)
                    let distanceProximal = Common.distance(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkProximal)
                    let distanceDistal = Common.distance(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkDistal)
                    if distanceProximal < minimum || distanceDistal < minimum {
                        middleMarks.append(neighboringMark)
                    }
                }
            }
        }
        return NearbyMarks(proximalMarks: proximalMarks, middleMarks: middleMarks, distalMarks: distalMarks)
    }
    func moveMark(mark: Mark, position: CGPoint, moveCursor: Bool) {
        moveMark(mark: mark, screenPositionX: position.x)
        if moveCursor {
            let anchorPositionX = mark.getAnchorPositionX()
            cursorViewDelegate?.moveCursor(cursorViewPositionX: anchorPositionX)
            cursorViewDelegate?.refresh()
        }
    }

    func moveMark(mark: Mark, screenPositionX: CGFloat) {
        let regionPosition = translateToRegionPositionX(ladderViewPositionX: screenPositionX)
        switch mark.anchor {
        case .proximal:
            mark.segment.proximal.x = regionPosition
        case .middle:
            // Determine halfway point between proximal and distal.
            let difference = (mark.segment.proximal.x - mark.segment.distal.x) / 2
            mark.segment.proximal.x = regionPosition + difference
            mark.segment.distal.x = regionPosition - difference
        case .distal:
            mark.segment.distal.x = regionPosition
        case .none:
            break
        }
        // Move linked marks
        for proximalMark in mark.attachedMarks.proximal {
            proximalMark.segment.distal.x = mark.segment.proximal.x
        }
        for distalMark in mark.attachedMarks.distal {
            distalMark.segment.proximal.x = mark.segment.distal.x
        }
        highlightNearbyMarks(mark)
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        self.becomeFirstResponder()
        let position = press.location(in: self)
        let locationInLadder = getLocationInLadder(position: position)
        P("long press at \(locationInLadder) ")
        if locationInLadder.markWasTapped {
            P("you pressed a mark")
            if #available(iOS 13.0, *) {
                // use LadderView extensions
            }
            else {
                setPressedMark(position: position)
                longPressMarkOldOS(position)
            }
        }
    }

    func setPressedMark(position: CGPoint) {
        let locationInLadder = getLocationInLadder(position: position)
        if let mark = locationInLadder.mark {
            pressedMark = mark
        }
    }

    func setPressedMarkStyle(style: Mark.LineStyle) {
        if let pressedMark = pressedMark {
            pressedMark.lineStyle = style
        }
    }


    fileprivate func longPressMarkOldOS(_ position: CGPoint) {
        // Note: it doesn't look like you can add a submenu to a UIMenuController like
        // you can do with context menus available in iOS 13.
        let solidMenuItem = UIMenuItem(title: L("Solid"), action: #selector(setSolid))
        let dashedMenuItem = UIMenuItem(title: L("Dashed"), action: #selector(setDashed))
        let dottedMenuItem = UIMenuItem(title: L("Dotted"), action: #selector(setDotted))
        let unlinkMenuItem = UIMenuItem(title: L("Unlink"), action: #selector(unlinkPressedMark))
        let deleteMenuItem = UIMenuItem(title: L("Delete"), action: #selector(deletePressedMark))
        UIMenuController.shared.menuItems = [solidMenuItem, dashedMenuItem, dottedMenuItem, unlinkMenuItem, deleteMenuItem]
        let rect = CGRect(x: position.x, y: position.y, width: 0, height: 0)
        if #available(iOS 13.0, *) {
            UIMenuController.shared.showMenu(from: self, rect: rect)
        } else {
            UIMenuController.shared.setTargetRect(rect, in: self)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }

    @objc func setSolid() {
        setPressedMarkStyle(style: .solid)
        nullifyPressedMark()
        setNeedsDisplay()
    }

    @objc func setDashed() {
        setPressedMarkStyle(style: .dashed)
        nullifyPressedMark()
        setNeedsDisplay()
    }

    @objc func setDotted() {
        setPressedMarkStyle(style: .dotted)
        nullifyPressedMark()
        setNeedsDisplay()
    }

    func nullifyPressedMark() {
        pressedMark = nil
    }

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            draw(rect: rect, context: context)
        }
    }

    func draw(rect: CGRect, context: CGContext) {
        if #available(iOS 13.0, *) {
            context.setStrokeColor(UIColor.label.cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }
        context.setLineWidth(1)
        // All horizontal distances are adjusted to scale.
        let ladderWidth: CGFloat = rect.width * scale
        for (index, region) in ladder.regions.enumerated() {
            let regionRect = CGRect(x: leftMargin, y: region.proximalBoundary, width: ladderWidth, height: region.distalBoundary - region.proximalBoundary)
            let lastRegion = index == ladder.regions.count - 1
            drawRegion(rect: regionRect, context: context, region: region, offset: offsetX, scale: scale, lastRegion: lastRegion)
        }
    }


    fileprivate func drawLabel(rect: CGRect, region: Region, context: CGContext) {
        let stringRect = CGRect(x: 0, y: rect.origin.y, width: rect.origin.x, height: rect.height)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 18.0),
            .foregroundColor: region.selected ? red : blue
        ]
        let text = region.name
        let labelText = NSAttributedString(string: text, attributes: attributes)
        let size: CGSize = text.size(withAttributes: attributes)
        let labelRect = CGRect(x: 0, y: rect.origin.y + (rect.height - size.height) / 2, width: rect.origin.x, height: size.height)
        context.addRect(stringRect)
        context.setStrokeColor(red.cgColor)
        if #available(iOS 13.0, *) {
            context.setFillColor(UIColor.secondarySystemBackground.cgColor)
        } else {
            context.setFillColor(UIColor.white.cgColor)
        }
        context.setLineWidth(1)
        context.drawPath(using: .fillStroke)
        labelText.draw(in: labelRect)
    }

    // TODO: Color alpha gets higher with each rotation of device.
    fileprivate func drawRegionArea(context: CGContext, rect: CGRect, region: Region) {
        // Draw top ladder line
        if #available(iOS 13.0, *) {
            context.setStrokeColor(UIColor.label.cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y))
        context.strokePath()

        // Highlight region if selected
        if region.selected {
            let regionRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
            context.setAlpha(0.2)
            context.addRect(regionRect)
            context.setFillColor(red.cgColor)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1)
    }

    fileprivate func drawMark(mark: Mark, region: Region, context: CGContext) {
        let segment = translateToLadderViewSegment(regionSegment: mark.segment, region: region)
        // Don't bother drawing marks in margin.
        if segment.proximal.x <= leftMargin && segment.distal.x <= leftMargin {
            return
        }
        // The two endpoints of the mark to be drawn
        var p1 = CGPoint()
        var p2 = CGPoint()
        if segment.proximal.x > leftMargin && segment.distal.x > leftMargin {
            p1 = segment.proximal
            p2 = segment.distal
        }
        else if segment.proximal.x < leftMargin {
            p1 = getTruncatedPosition(position: segment) ?? segment.proximal
            p2 = segment.distal
        }
        else {
            p1 = getTruncatedPosition(position: segment) ?? segment.distal
            p2 = segment.proximal
        }
        context.setStrokeColor(getMarkColor(mark: mark))
        context.setLineWidth(getMarkLineWidth(mark))
        context.move(to: p1)
        context.addLine(to: p2)
        // Draw dashed line
        if mark.lineStyle == .dashed {
            let dashes: [CGFloat] = [5, 5]
            context.setLineDash(phase: 0, lengths: dashes)
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])
        }
        else if mark.lineStyle == .dotted {
            let dots: [CGFloat] = [2, 2]
            context.setLineDash(phase: 0, lengths: dots)
            context.strokePath()
            context.setLineDash(phase: 0, lengths: [])
        }
        else { // draw solid line
            context.strokePath()
        }
        // FIXME: Draw circles as mark ends approach
        //        drawCircle(context: context, center: p2, radius: 5)

        drawBlock(context: context, mark: mark, position: segment)

        context.setStrokeColor(getLineColor())
    }

    func getTruncatedPosition(position: Segment) -> CGPoint? {
        // TODO: Handle lines slanted backwards, don't draw at all in margin
        let intersection = getIntersection(ofLineFrom: CGPoint(x: leftMargin, y: 0), to: CGPoint(x: leftMargin, y: height), withLineFrom: position.proximal, to: position.distal)
        return intersection
    }

    func drawCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
        context.strokePath()
    }

    func drawBlock(context: CGContext, mark: Mark, position: Segment) {
        let blockLength: CGFloat = 20
        let blockSeparation: CGFloat = 5
        switch mark.block {
        case .none:
            return
        case .distal:
            context.move(to: CGPoint(x: position.distal.x - blockLength / 2, y: position.distal.y))
            context.addLine(to: CGPoint(x: position.distal.x + blockLength / 2, y: position.distal.y))
            context.move(to: CGPoint(x: position.distal.x - blockLength / 2, y: position.distal.y + blockSeparation))
            context.addLine(to: CGPoint(x: position.distal.x + blockLength / 2, y: position.distal.y + blockSeparation))
        case .proximal:
            context.move(to: CGPoint(x: position.proximal.x - blockLength / 2, y: position.proximal.y))
            context.addLine(to: CGPoint(x: position.proximal.x + blockLength / 2, y: position.proximal.y))
            context.move(to: CGPoint(x: position.proximal.x - blockLength / 2, y: position.proximal.y - blockSeparation))
            context.addLine(to: CGPoint(x: position.proximal.x + blockLength / 2, y: position.proximal.y - blockSeparation))
        }
        context.strokePath()
    }

    // Algorithm from: https://stackoverflow.com/questions/15690103/intersection-between-two-lines-in-coordinates
    // Returns intersection point of two line segments, nil if no intersection.
    func getIntersection(ofLineFrom p1: CGPoint, to p2: CGPoint, withLineFrom p3: CGPoint, to p4: CGPoint) -> CGPoint? {
        let d: CGFloat = (p2.x - p1.x) * (p4.y - p3.y) - (p2.y - p1.y) * (p4.x - p3.x)
        if d == 0 {
            return nil; // parallel lines
        }
        let u: CGFloat = ((p3.x - p1.x)*(p4.y - p3.y) - (p3.y - p1.y)*(p4.x - p3.x))/d
        let v: CGFloat = ((p3.x - p1.x)*(p2.y - p1.y) - (p3.y - p1.y)*(p2.x - p1.x))/d
        if u < 0.0 || u > 1.0 {
            return nil; // intersection point not between p1 and p2
        }
        if v < 0.0 || v > 1.0 {
            return nil; // intersection point not between p3 and p4
        }
        var intersection = CGPoint()
        intersection.x = p1.x + u * (p2.x - p1.x)
        intersection.y = p1.y + u * (p2.y - p1.y)
        return intersection
    }

    private func getMarkLineWidth(_ mark: Mark) -> CGFloat {
        if mark.potentiallyConnected {
            return connectedLineWidth
        }
        else {
            return markLineWidth
        }
    }

    private func getMarkColor(mark: Mark) -> CGColor {
        if mark.highlight == .all {
            return selectedColor.cgColor
        }
        else {
            return unselectedColor.cgColor
        }
    }

    private func getLineColor() -> CGColor {
        if #available(iOS 13.0, *) {
            return UIColor.label.cgColor
        } else {
            return UIColor.black.cgColor
        }
    }

    fileprivate func drawMarks(region: Region, context: CGContext,  rect: CGRect) {
        // Draw marks
        for mark: Mark in region.marks {
            drawMark(mark: mark, region: region, context: context)
        }
    }

    fileprivate func drawBottomLine(context: CGContext, lastRegion: Bool, rect: CGRect) {
        // Draw bottom line of region if it is the last region of the ladder.
        context.setLineWidth(1)
        if lastRegion {
            context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
            context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y + rect.height))
        }
        context.strokePath()
    }

    func drawRegion(rect: CGRect, context: CGContext, region: Region, offset: CGFloat, scale: CGFloat, lastRegion: Bool) {
        drawLabel(rect: rect, region: region, context: context)
        drawRegionArea(context: context, rect: rect, region: region)
        drawMarks(region: region, context: context, rect: rect)
        drawBottomLine(context: context, lastRegion: lastRegion, rect: rect)
    }

    func activateRegion(region: Region?) {
        guard let region = region else { return }
        inactivateRegions()
        region.selected = true
    }

    func inactivateRegions() {
        for region in ladder.regions {
            region.selected = false
        }
    }

    func reinit() {
        initializeRegions()
    }

    func regionsToCheckForCloseness() -> [Region] {
        guard activeRegion != nil else { return [] }
        // FIXME: temporary
        return []
    }
    // FIXME: test which offsetY works.
    func resetSize() {
        height = self.frame.height
        reinit()
    }

    func addAttachedMark(positionX relativePositionX: CGFloat) {
        let mark = addMark(positionX: relativePositionX)
        attachedMark = mark
    }


    private func unscaledPositionX(positionX: CGFloat) -> CGFloat {
        return positionX / scale
    }

    @objc func deletePressedMark() {
        if let pressedMark = pressedMark {
            ladder.deleteMark(pressedMark)
            ladder.setHighlight(highlight: .none)
        }
        cursorViewDelegate?.hideCursor(true)
        refresh()
    }

    @objc func unlinkPressedMark() {
        if let pressedMark = pressedMark {
            unlinkMarks(mark: pressedMark)
        }
    }

    func unlinkMarks(mark: Mark) {
        mark.attachedMarks = Mark.AttachedMarks()
    }


}

extension LadderView: LadderViewDelegate {

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionProximalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: activeRegion?.proximalBoundary ?? 0)
        return convert(position, to: view).y
    }

//    func getAttachedMarkScreenPositionY(view: UIView) -> CGFloat? {
//        let position = ladderViewModel.getMarkAnchorLadderViewPosition(mark: ladderViewModel.attachedMark, region: ladderViewModel.activeRegion)
//        return position?.y
//    }

    func getAttachedMarkLadderViewPositionY(view: UIView) -> CGFloat? {
        let position = getMarkAnchorLadderViewPosition(mark: attachedMark, region: activeRegion)
        return position?.y
    }

    func getMarkAnchorRegionPosition(_ mark: Mark) -> CGPoint {
        let anchor = mark.anchor
        let anchorPosition: CGPoint
        switch anchor {
        case .proximal:
            anchorPosition = mark.segment.proximal
        case .middle:
            anchorPosition = mark.midpoint()
        case .distal:
            anchorPosition = mark.segment.distal
        case .none:
            anchorPosition = mark.segment.proximal
        }
        return anchorPosition
    }

    func getMarkAnchorLadderViewPosition(mark: Mark?, region: Region?) -> CGPoint? {
        guard let mark = mark, let region = region else { return nil }
        var anchorPosition = getMarkAnchorRegionPosition(mark)
        anchorPosition = translateToLadderViewPosition(regionPosition: anchorPosition, regionProximalBoundary: region.proximalBoundary, regionHeight: region.height)
        return anchorPosition
    }

    func getTopOfLadder(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: ladder.regions[0].proximalBoundary)
        return convert(position, to: view).y
    }

    func getRegionMidPoint(view: UIView) -> CGFloat {
        guard let activeRegion = activeRegion else { return 0 }
        let position = CGPoint(x: 0, y: (activeRegion.distalBoundary -  activeRegion.proximalBoundary) / 2 + activeRegion.proximalBoundary)
        return convert(position, to: view).y
    }

    func getRegionDistalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: activeRegion?.distalBoundary ?? 0)
        return convert(position, to: view).y
    }

    func getHeight() -> CGFloat {
        return height
    }

    func refresh() {
        cursorViewDelegate?.refresh()
        setNeedsDisplay()
    }

    func setActiveRegion(regionNum: Int) {
        activeRegion = ladder.regions[regionNum]
        activeRegion?.selected = true
    }

    func hasActiveRegion() -> Bool {
        return activeRegion != nil
    }

    func unhighlightMarks() {
        ladder.setHighlight(highlight: .none)
    }

    func deleteMark(_ mark: Mark?) {
        ladder.deleteMark(mark)
        ladder.setHighlight(highlight: .none)
    }
    
    @discardableResult
    func addMark(positionX screenPositionX: CGFloat) -> Mark? {
        P("Add mark at \(screenPositionX)")
        return ladder.addMarkAt(unscaledRelativePositionX(relativePositionX: screenPositionX))
    }

    private func unscaledRelativePositionX(relativePositionX: CGFloat) -> CGFloat {
        return relativePositionX / scale
    }

    func linkNearbyMarks(mark: Mark) {
        var minimum: CGFloat = 10
        minimum = minimum / scale
        let nearbyMarks = getNearbyMarks(mark: mark, minimum: minimum)
        let proxMarks = nearbyMarks.proximalMarks
        let distalMarks = nearbyMarks.distalMarks
        let middleMarks = nearbyMarks.middleMarks
        for proxMark in proxMarks {
            mark.attachedMarks.proximal.append(proxMark)
            mark.segment.proximal.x = proxMark.segment.distal.x
            if mark.anchor == .proximal {
                cursorViewDelegate?.moveCursor(cursorViewPositionX: mark.segment.proximal.x / scale)
            }
            else if mark.anchor == .middle {
                cursorViewDelegate?.moveCursor(cursorViewPositionX: mark.midpoint().x / scale)
            }
            proxMark.attachedMarks.distal.append(mark)
        }
        for distalMark in distalMarks {
            mark.attachedMarks.distal.append(distalMark)
            mark.segment.distal.x = distalMark.segment.proximal.x
            if mark.anchor == .proximal {
                cursorViewDelegate?.moveCursor(cursorViewPositionX: mark.segment.proximal.x / scale)
            }
            else if mark.anchor == .middle {
                cursorViewDelegate?.moveCursor(cursorViewPositionX: mark.midpoint().x / scale)
            }
            distalMark.attachedMarks.proximal.append(mark)
        }
        for middleMark in middleMarks {
            let distanceToProximal = Common.distance(segment: middleMark.segment, point: mark.segment.proximal)
            let distanceToDistal = Common.distance(segment: middleMark.segment, point: mark.segment.distal)
            let closestEnd = distanceToProximal < distanceToDistal ? mark.segment.proximal : mark.segment.distal
            let closestPoint = Common.closestPoint(segment: middleMark.segment, point:  closestEnd)
            if distanceToProximal < distanceToDistal {
                mark.segment.proximal = closestPoint
            }
            else {
                mark.segment.distal = closestPoint
            }
            mark.attachedMarks.distal.append(middleMark)
        }
    }
}

@available(iOS 13.0, *)
extension LadderView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let markFound = markWasTapped(position: location)
        setPressedMark(position: location)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let solid = UIAction(title: L("Solid")) { action in
                self.setSolid()
            }
            let dashed = UIAction(title: L("Dashed")) { action in
                self.setDashed()
            }
            let dotted = UIAction(title: L("Dotted")) { action in
                self.setDotted()
            }
            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
            // Use .displayInline option to show menu inline with separator.
            //           let style = UIMenu(title: L("Style..."), options: .displayInline,  children: [solid, dashed, dotted])
            let unlink = UIAction(title: L("Unlink")) { action in
                self.unlinkPressedMark()
            }
            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deletePressedMark()
            }
            // Create and return a UIMenu with all of the actions as children
            if markFound {
                return UIMenu(title: L("Edit mark"), children: [style, unlink, delete])
            }
            else {
                return UIMenu(title: "", children: [delete])
            }
        }
    }
}

//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit


extension Mark {
    func getPosition(in rect:CGRect, offset: CGFloat, scale: CGFloat) -> Segment {
        return Segment(proximal: Common.translateToScreenPosition(position: segment.proximal, inRect: rect, offsetX: offset, scale: scale), distal: Common.translateToScreenPosition(position: segment.distal, inRect: rect, offsetX: offset, scale: scale))
    }
}

class LadderViewModel : ScaledViewModel {
    // Half a region width above and below ladder
    let ladderPaddingMultiplier: CGFloat = 0.5
    let accuracy: CGFloat = 20
    let lowerLimitMarkHeight: CGFloat = 0.1

    var regions: [Region] = []
    var ladder: Ladder
    var activeRegion: Region? {
        set(value) {
            ladder.activeRegion = value
            activateRegion(region: ladder.activeRegion)
        }
        get {
            return ladder.activeRegion
        }
    }
    var attachedMark: Mark?
    var pressedMark: Mark?
    var movingMark: Mark?
    // TODO: activeMark unused
    var activeMark: Mark?
    var margin: CGFloat = 0
    var lineWidth: CGFloat = 2

    // variables that need to eventually be preferences
    let red = UIColor.systemRed
    let blue = UIColor.systemBlue
    let unselectedColor: UIColor
    let selectedColor = UIColor.magenta
    let markLineWidth: CGFloat = 2
    let connectedLineWidth: CGFloat = 4

    var height: CGFloat = 0
    var regionUnitHeight: CGFloat = 0

    // All the fields needed to implement dragging in regions.
    var regionOfDragOrigin: Region? = nil
    var regionProxToDragOrigin: Region? = nil
    var regionDistalToDragOrigin: Region? = nil
    var dragCreatedMark: Mark? = nil
    var dragOriginDivision: RegionDivision = .none

    // Use default ladder for now...
    convenience override init() {
        self.init(ladder: Ladder.defaultLadder())
    }

    init(ladder: Ladder) {
        self.ladder = ladder
        ladder.activeRegion = ladder.regions[0]
        if #available(iOS 13.0, *) {
            unselectedColor = UIColor.label
        } else {
            unselectedColor = UIColor.black
        }
    }

    func initialize() {
        regionUnitHeight = getRegionUnitHeight(ladder: ladder)
        regions.removeAll()
        var regionBoundary = regionUnitHeight * ladderPaddingMultiplier
        for region: Region in ladder.regions {
            let regionHeight = getRegionHeight(region: region)
            region.proximalBoundary = regionBoundary
            region.distalBoundary = regionBoundary + regionHeight
            regionBoundary += regionHeight
            regions.append(region)
        }
    }

    // Here we want to add the Mark at the X position on the screen.  This is independent of
    // the offset.  If the content is offset, the X position is offset too.  However,
    // the zoomScale does affect the X position.  Say the scale is 2, then what appears to be
    // the X position is actually 2 * X.  Thus we unscale the position and get an absolute mark X position.
    func addMark(positionX screenPositionX: CGFloat) -> Mark? {
        P("Add mark at \(screenPositionX)")
        return ladder.addMarkAt(unscaledRelativePositionX(relativePositionX: screenPositionX))
    }

    func addAttachedMark(positionX relativePositionX: CGFloat) {
        let mark = addMark(positionX: relativePositionX)
        attachedMark = mark
    }

    private func unscaledRelativePositionX(relativePositionX: CGFloat) -> CGFloat {
        return relativePositionX / scale
    }

    // FIXME: There are 2 addMark functions.  Why?
    func addMark(absolutePositionX: CGFloat) -> Mark? {
        return ladder.addMarkAt(absolutePositionX)
    }

    func deleteMark(_ mark: Mark?) {
        ladder.deleteMark(mark)
        ladder.setHighlight(highlight: .none)
    }

    func deletePressedMark() {
        if let pressedMark = pressedMark {
            ladder.deleteMark(pressedMark)
            ladder.setHighlight(highlight: .none)
        }
    }

    func unlinkPressedMark() {
        if let pressedMark = pressedMark {
            unlinkMarks(mark: pressedMark)
        }
    }

    func unlinkMarks(mark: Mark) {
        mark.attachedMarks = Mark.AttachedMarks()
    }

    func unhighlightMarks() {
        ladder.setHighlight(highlight: .none)
    }

    func nullifyPressedMark() {
        pressedMark = nil
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

    // TODO: must also highlight nearby marks that are in the same region (and link them too).
    fileprivate func highlightNearbyMarks(_ mark: Mark?) {
        guard let mark = mark else { return }
        var minimum: CGFloat = 10
        minimum = minimum / scale
        let nearbyProximalMarks: [Mark] = ladder.getNearbyMarks(mark: mark, minimum: minimum).proximalMarks
        let nearbyDistalMarks: [Mark] = ladder.getNearbyMarks(mark: mark, minimum: minimum).distalMarks
        if nearbyProximalMarks.count > 0 {
            for nearbyMark in nearbyProximalMarks {
                nearbyMark.highlight = .all
            }
        }
        else {
            ladder.setHighlight(highlight: .none, region: ladder.getRegionBefore(region: activeRegion))
        }
        if nearbyDistalMarks.count > 0 {
            P("nearby Marks = \(nearbyDistalMarks)")
            for nearbyMark in nearbyDistalMarks {
                nearbyMark.highlight = .all
            }
        }
        else {
            ladder.setHighlight(highlight: .none, region: ladder.getRegionAfter(region: activeRegion))
        }
    }

    func moveMark(mark: Mark, screenPositionX: CGFloat) {
        let regionPosition = translateToRegionPositionX(screenPositionX: screenPositionX)
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


    /// Determine if a mark is near the X position, using relative coordinates.  Internally compares the relative mark X position to the positionX parameter.
    /// Uses a sophistcated distance measurement of a point to a line segment which gives the same screen results regardless of zoom.
    /// - Parameters:
    ///   - position: position of, say a tap on the screen
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    ///   - accuracy: how close does it have to be?
    func nearMark(point: CGPoint, mark: Mark, region: Region, accuracy: CGFloat) -> Bool {
        let linePoint1 = translateToScreenPosition(regionPosition: mark.segment.proximal, region: region)
        let linePoint2 = translateToScreenPosition(regionPosition: mark.segment.distal, region: region)
        let distance = Common.distance(linePoint1: linePoint1, linePoint2: linePoint2, point: point)
        return distance < accuracy
    }


    func linkNearbyMarks(mark: Mark) {
        P("linkNearbyMarks")
        var minimum: CGFloat = 10
        minimum = minimum / scale
        let nearbyMarks = ladder.getNearbyMarks(mark: mark, minimum: minimum)
        let proxMarks = nearbyMarks.proximalMarks
        let distalMarks = nearbyMarks.distalMarks
        for proxMark in proxMarks {
            mark.attachedMarks.proximal.append(proxMark)
            mark.segment.proximal.x = proxMark.segment.distal.x
            proxMark.attachedMarks.distal.append(mark)
        }
        for distalMark in distalMarks {
            mark.attachedMarks.distal.append(distalMark)
            mark.segment.distal.x = distalMark.segment.proximal.x
            distalMark.attachedMarks.proximal.append(mark)
        }
    }

    func makeMark(positionX relativePositionX: CGFloat) -> Mark? {
        return addMark(absolutePositionX: Common.translateToRegionPositionX(ladderViewPositionX: relativePositionX, offset: offset, scale: scale))
    }

    func getRegionHeight(region: Region) -> CGFloat {
        return region.decremental ? 2 * regionUnitHeight : regionUnitHeight
    }

    func draw(rect: CGRect, context: CGContext) {
        P("LadderViewModel draw()")
        if #available(iOS 13.0, *) {
            context.setStrokeColor(UIColor.label.cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }
        context.setLineWidth(1)
        // All horizontal distances are adjusted to scale.
        let ladderWidth: CGFloat = rect.width * scale
        for (index, region) in regions.enumerated() {
            let regionRect = CGRect(x: margin, y: region.proximalBoundary, width: ladderWidth, height: region.distalBoundary - region.proximalBoundary)
            let lastRegion = index == regions.count - 1
            drawRegion(rect: regionRect, context: context, region: region, offset: offset, scale: scale, lastRegion: lastRegion)
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

    fileprivate func drawMark(mark: Mark, rect: CGRect, context: CGContext) {
        let position = mark.getPosition(in: rect, offset: offset, scale: scale)
        // Don't bother drawing marks in margin.
        if position.proximal.x <= margin && position.distal.x <= margin {
            return
        }
        // The two endpoints of the mark to be drawn
        var p1 = CGPoint()
        var p2 = CGPoint()
        if position.proximal.x > margin && position.distal.x > margin {
            p1 = position.proximal
            p2 = position.distal
        }
        else if position.proximal.x < margin {
            p1 = getTruncatedPosition(position: position) ?? position.proximal
            p2 = position.distal
        }
        else {
            p1 = getTruncatedPosition(position: position) ?? position.distal
            p2 = position.proximal
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

        drawBlock(context: context, mark: mark, position: position)
        
        context.setStrokeColor(getLineColor())
    }

    func getTruncatedPosition(position: Segment) -> CGPoint? {
        // TODO: Handle lines slanted backwards, don't draw at all in margin
        let intersection = getIntersection(ofLineFrom: CGPoint(x: margin, y: 0), to: CGPoint(x: margin, y: height), withLineFrom: position.proximal, to: position.distal)
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

    fileprivate func relativeMarkPosition(mark: Mark, offset: CGFloat, scale: CGFloat, rect: CGRect) -> Segment{
        let proximalX = translateToScreenPositionX(regionPositionX: mark.segment.proximal.x)
        let distalX = translateToScreenPositionX(regionPositionX: mark.segment.distal.x)
        let proximalY = rect.origin.y + mark.segment.proximal.y * rect.height
        let distalY = rect.origin.y + mark.segment.distal.y * rect.height
        let proximalPoint = CGPoint(x: proximalX, y: proximalY)
        let distalPoint = CGPoint(x: distalX, y: distalY)
        return Segment(proximal: proximalPoint, distal: distalPoint)
    }

    fileprivate func drawMarks(region: Region, context: CGContext,  rect: CGRect) {
        // Draw marks
        for mark: Mark in region.marks {
            drawMark(mark: mark, rect: rect, context: context)
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

    func getRegionUnitHeight(ladder: Ladder) -> CGFloat {
        var numRegionUnits = 0
        // Decremental regions are twice as high as regular regions.
        // FIXME: It might be better to have this be a property of each region, e.g.
        // Region.heightInRegionUnits.
        for region: Region in ladder.regions {
            numRegionUnits += region.decremental ? 2 : 1
        }
        // we'll allow padding above and below, so...
        let padding = Int(ladderPaddingMultiplier * 2)
        numRegionUnits += padding
        return height / CGFloat(numRegionUnits)
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

    func inactivateMarks() {
        for region in ladder.regions {
            for mark in region.marks {
                mark.highlight = .none
                mark.attached = false
            }
        }
    }

    func reinit() {
        initialize()
    }

    func regionsToCheckForCloseness() -> [Region] {
        guard activeRegion != nil else { return [] }
        // FIXME: temporary
        return []
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter position: point to be processed
    /// - Parameter ladderViewModel: ladderViewModel in use
    func getLocationInLadder(position: CGPoint) -> LocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        var tappedRegionDivision: RegionDivision = .none
        for region in regions {
            if position.y > region.proximalBoundary && position.y < region.distalBoundary {
                tappedRegion = region
                tappedRegionDivision = getTappedRegionDivision(region: region, positionY: position.y)
                P("tappedRegionDivision = \(tappedRegionDivision)")
            }
        }
        if let tappedRegion = tappedRegion {
            if position.x < margin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(point: position, mark: mark, region: tappedRegion, accuracy: accuracy) {
                        P("tap near mark")
                        tappedMark = mark
                        break outerLoop
                    }
                }
            }
        }
        return LocationInLadder(region: tappedRegion, mark: tappedMark, regionSection: tappedRegionSection, regionDivision: tappedRegionDivision)
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


    func setActiveRegion(regionNum: Int) {
        activeRegion = regions[regionNum]
        activeRegion?.selected = true
    }

    func hasActiveRegion() -> Bool {
        return activeRegion != nil
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

    func markWasTapped(position: CGPoint) -> Bool {
        return getLocationInLadder(position: position).markWasTapped
    }

//    let locationInLadder = self.ladderViewModel.getLocationInLadder(position: location)
//    if let mark = locationInLadder.mark {
//        self.pressedMark = mark
//        self.setSolid()
//    }

    func labelWasTapped(labelRegion: Region) {
        if labelRegion.selected {
            labelRegion.selected = false
            activeRegion = nil
        }
        else { // !tappedRegion.selected
            activeRegion = labelRegion
        }
    }

    func regionWasTapped(tapLocationInLadder: LocationInLadder, positionX: CGFloat, cursorViewDelegate: CursorViewDelegate?) {
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
                    inactivateMarks()
                    mark.attached = true
                    mark.anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
                    selectMark(mark)
                    cursorViewDelegate?.getViewModel().attachMark(mark)
                    cursorViewDelegate?.moveCursor(positionX: mark.segment.proximal.x)
                    cursorViewDelegate?.hideCursor(false)
                }
            }
        }
    }

    /// Response to tapped mark in LadderView.  Returns marks anchor position.x or nil
    /// if no mark tapped.
    /// - Parameter tapLocationInLadder: the tapped LocationInLadder
    func markWasTapped(mark: Mark?, tapLocationInLadder: LocationInLadder, cursorViewDelegate: CursorViewDelegate?) {
        if let mark = mark {
            if mark.attached {
                let anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
                // Just reanchor cursor
                if anchor != mark.anchor {
                    mark.anchor = anchor
                    let anchorPositionX = mark.getAnchorPositionX()
                    cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
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
                mark.anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
                selectMark(mark)
                cursorViewDelegate?.getViewModel().attachMark(mark)
                let anchorPosition = mark.getAnchorPosition()
                cursorViewDelegate?.moveCursor(positionX: anchorPosition.x)
                cursorViewDelegate?.hideCursor(false)
            }
        }
    }

    fileprivate func setMarkSelection(_ mark: Mark?, highlight: Mark.Highlight) {
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

    // MARK: - Touches

    func singleTap(position: CGPoint, cursorViewDelegate: CursorViewDelegate?) {
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
    }

    /// dragging mark.  Returns true if LadderView needs redisplay.
    /// - Parameters:
    ///   - position: CGPoint, position of drag point
    ///   - state: state of dragging
    ///   - cursorViewDelegate: CursorViewDelegate from LadderView
    func dragMark(position: CGPoint, state: UIPanGestureRecognizer.State, cursorViewDelegate: CursorViewDelegate?) -> Bool {
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
                    cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
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
                        dragCreatedMark?.segment.distal = translateToRegionPosition(screenPosition: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height)
                    case .distal:
                        dragCreatedMark?.segment.proximal = translateToRegionPosition(screenPosition: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height)
                    case .middle:
                        // TODO: Fix this
//                        if let proximalY = dragCreatedMark?.position.proximal.y, let distalY = dragCreatedMark?.position.distal.y {
//                            if proximalY > distalY {
//                                dragCreatedMark?.swapEnds()
//                            }
//                        }
                        dragCreatedMark?.segment.distal = translateToRegionPosition(screenPosition: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height)
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
                if dragCreatedMark.height < lowerLimitMarkHeight {
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

    func moveMark(mark: Mark, position: CGPoint, moveCursor: Bool, cursorViewDelegate: CursorViewDelegate?) {
        moveMark(mark: mark, screenPositionX: position.x)
        if moveCursor {
            let anchorPositionX = mark.getAnchorPositionX()
            cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
            cursorViewDelegate?.refresh()
        }
    }
}

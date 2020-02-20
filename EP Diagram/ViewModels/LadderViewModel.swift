//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// FIXME: experimental.
struct RelativeMarkPosition {
    var position: MarkPosition
    var proximal: CGPoint {
        get {
            position.proximal
        }
    }
    var distal: CGPoint {
        get {
            position.distal
        }
    }
    var offset: CGFloat
    var scale: CGFloat
    var rect: CGRect
    var absoluteMarkPosition: MarkPosition {
        get {
            return Common.translateToAbsoluteMarkPosition(markPosition: position, inRect: rect, offsetX: offset, scale: scale)
        }
        set(newPosition) {
            position = Common.translateToRelativeMarkPosition(markPosition: newPosition, inRect: rect, offsetX: offset, scale: scale)
        }
    }

    init(relativePosition: MarkPosition, inRect rect: CGRect, offsetX offset: CGFloat, scale: CGFloat) {
        position = relativePosition
        self.rect = rect
        self.offset = offset
        self.scale = scale
    }

    // Essentially a zeroed out RelativeMarkPosition.
    init() {
        position = MarkPosition(proximal: CGPoint.zero, distal: CGPoint.zero)
        rect = CGRect.zero
        offset = 0
        scale = 1.0
    }

    func getAbsoluteMarkPosition(inRect rect: CGRect) -> MarkPosition {
        return Common.translateToAbsoluteMarkPosition(markPosition: position, inRect: rect, offsetX: offset, scale: scale)
    }
}

// FIXME: Experimental
extension Mark {
//    func setRelativeMarkPosition(relativeMarkPosition: RelativeMarkPosition) {
//        position = relativeMarkPosition.absoluteMarkPosition
//    }

    func setPosition(relativePosition: MarkPosition, in rect:CGRect, offset: CGFloat, scale: CGFloat) {
        position.proximal = Common.translateToAbsolutePosition(position: relativePosition.proximal, inRect: rect, offsetX: offset, scale: scale)
        position.distal = Common.translateToAbsolutePosition(position: relativePosition.distal, inRect: rect, offsetX: offset, scale: scale)
    }

    func getPosition(in rect:CGRect, offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: Common.translateToRelativePosition(position: position.proximal, inRect: rect, offsetX: offset, scale: scale), distal: Common.translateToRelativePosition(position: position.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    convenience init(relativePosition: MarkPosition, in rect: CGRect, offset: CGFloat, scale: CGFloat) {
        self.init()
        setPosition(relativePosition: relativePosition, in: rect, offset: offset, scale: scale)
    }

}

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

class LadderViewModel {
    // Half a region width above and below ladder
    let ladderPaddingMultiplier: CGFloat = 0.5
    let accuracy: CGFloat = 20

    // This is used to hold relative mark positions and easily feed them to marks.
    var relativeMarkPosition = RelativeMarkPosition()
    var offset: CGFloat = 0 {
        didSet {
            relativeMarkPosition.offset = offset
        }
    }
    var scale: CGFloat = 1 {
        didSet {
            relativeMarkPosition.scale = scale
        }
    }

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
    convenience init() {
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
        P("LadderViewModel initialize()")
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
    func addMark(positionX relativePositionX: CGFloat) -> Mark? {
        P("Add mark at \(relativePositionX)")
        return ladder.addMarkAt(unscaledRelativePositionX(relativePositionX: relativePositionX))
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

    fileprivate func highlightNearbyMarks(_ mark: Mark) {
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

    func moveMark(mark: Mark, relativePositionX: CGFloat) {
        let absolutePosition = Common.translateToAbsolutePositionX(positionX: relativePositionX, offset: offset, scale: scale)
        switch mark.anchor {
        case .proximal:
            mark.position.proximal.x = absolutePosition
        case .middle:
            // Determine halfway point between proximal and distal.
            let difference = (mark.position.proximal.x - mark.position.distal.x) / 2
            mark.position.proximal.x = absolutePosition + difference
            mark.position.distal.x = absolutePosition - difference
        case .distal:
            mark.position.distal.x = absolutePosition
        case .none:
            break
        }
        // Move linked marks
        for proximalMark in mark.attachedMarks.proximal {
            proximalMark.position.distal.x = mark.position.proximal.x
        }
        for distalMark in mark.attachedMarks.distal {
            distalMark.position.proximal.x = mark.position.distal.x
        }
        highlightNearbyMarks(mark)
    }

    /// Determine if a mark is near the X position, using relative coordinates.  Internally compares the relative mark X position to the positionX parameter.
    /// Limitation: trouble with overlapping marks.
    /// - Parameters:
    ///   - positionX: X position of, say a tap on the screen
    ///   - mark: mark to check for proximity
    ///   - accuracy: how close does it have to be?
    func nearMark(positionX relativePositionX: CGFloat, mark: Mark, accuracy: CGFloat) -> Bool {
        let positionDistalX = Common.translateToRelativePositionX(positionX: mark.position.distal.x, offset: offset, scale: scale)
        let positionProximalX = Common.translateToRelativePositionX(positionX: mark.position.proximal.x, offset: offset, scale: scale)
        let maxX = max(positionDistalX, positionProximalX)
        let minX = min(positionDistalX, positionProximalX)
        return relativePositionX < maxX + accuracy && relativePositionX > minX - accuracy
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
            proxMark.position.distal.x = mark.position.proximal.x
            proxMark.attachedMarks.distal.append(mark)
        }
        for distalMark in distalMarks {
            mark.attachedMarks.distal.append(distalMark)
            distalMark.position.proximal.x = mark.position.distal.x
            distalMark.attachedMarks.proximal.append(mark)
        }
    }


    // FIXME: Probably dead code.
    func findMarkNearby(positionX: CGFloat, accuracy: CGFloat) -> Mark? {
        if let activeRegion = activeRegion {
            let relativePositionX = Common.translateToRelativePositionX(positionX: positionX, offset: offset, scale: scale)
            for mark in activeRegion.marks {
                if abs(mark.position.proximal.x - relativePositionX) < accuracy {
                    return mark
                }
            }
        }
        return nil
    }



    func makeMark(positionX relativePositionX: CGFloat) -> Mark? {
        return addMark(absolutePositionX: Common.translateToAbsolutePositionX(positionX: relativePositionX, offset: offset, scale: scale))
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
        context.setStrokeColor(getLineColor())
    }

    func getTruncatedPosition(position: MarkPosition) -> CGPoint? {
        // TODO: Handle lines slanted backwards, don't draw at all in margin
        let intersection = getIntersection(ofLineFrom: CGPoint(x: margin, y: 0), to: CGPoint(x: margin, y: height), withLineFrom: position.proximal, to: position.distal)
        return intersection
    }

    func drawCircle(context: CGContext, center: CGPoint, radius: CGFloat) {
        context.addArc(center: center, radius: radius, startAngle: 0.0, endAngle: .pi * 2.0, clockwise: true)
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

    fileprivate func relativeMarkPosition(mark: Mark, offset: CGFloat, scale: CGFloat, rect: CGRect) -> MarkPosition{
        let proximalX = Common.translateToRelativePositionX(positionX:mark.position.proximal.x, offset:offset, scale: scale)
        let distalX = Common.translateToRelativePositionX(positionX: mark.position.distal.x, offset: offset, scale: scale)
        let proximalY = rect.origin.y + mark.position.proximal.y * rect.height
        let distalY = rect.origin.y + mark.position.distal.y * rect.height
        let proximalPoint = CGPoint(x: proximalX, y: proximalY)
        let distalPoint = CGPoint(x: distalX, y: distalY)
        return MarkPosition(proximal: proximalPoint, distal: distalPoint)
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
                    if nearMark(positionX: position.x, mark: mark, accuracy: accuracy) {
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
            else { // make mark and attach cursor
                P("make mark and attach cursor")
                let mark = makeMark(positionX: positionX)
                if let mark = mark {
                    inactivateMarks()
                    mark.attached = true
                    mark.anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
                    selectMark(mark)
                    cursorViewDelegate?.getViewModel().attachMark(mark)
                    cursorViewDelegate?.moveCursor(positionX: mark.position.proximal.x)
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
                P("Unattaching mark")
                mark.attached = false
                unhighlightMarks()
//                mark.highlight = .none
                unselectMark(mark)
                cursorViewDelegate?.hideCursor(true)
                cursorViewDelegate?.unattachMark()
            }
        }
        else {
            P("Attaching mark")
            mark.attached = true
            mark.anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
            selectMark(mark)
            cursorViewDelegate?.getViewModel().attachMark(mark)
            let anchorPositionX = mark.getAnchorPositionX()
            cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
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
                cursorViewDelegate?.unattachMark()
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
            }
            if let mark = locationInLadder.mark {
                movingMark = mark
            }
            else {
                P("Dragging started away from a mark")
                dragOriginDivision = locationInLadder.regionDivision
                switch dragOriginDivision {
                case .proximal:
                    P("prox")
                    dragCreatedMark = makeMark(positionX: position.x)
                    dragCreatedMark?.position.proximal.y = 0
                    dragCreatedMark?.position.distal.y = 0.5
                case .middle:
                    P("middle")
                    dragCreatedMark = makeMark(positionX: position.x)
                    dragCreatedMark?.position.proximal.y = 0.5
                    dragCreatedMark?.position.distal.y = 0.75
                case .distal:
                    P("distal")
                    dragCreatedMark = makeMark(positionX: position.x)
                    dragCreatedMark?.position.proximal.y = 0.5
                    dragCreatedMark?.position.distal.y = 1
                case .none:
                    P("none")
                }
            }
        }
        if state == .changed {
            if let mark = movingMark {
                if mark.attached {
                    moveMark(mark: mark, relativePositionX: position.x)
                    let anchorPositionX = mark.getAnchorPositionX()
                    cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
                    cursorViewDelegate?.refresh()
                }
            }
            else {
                P("dragging mark without cursor.")
                let locationInLadder = getLocationInLadder(position: position)
                if regionProxToDragOrigin === locationInLadder.region {
                    P("Dragging into previous region")
                }
                else if regionDistalToDragOrigin === locationInLadder.region {
                    P("Dragging into next region")
                }
                else if regionOfDragOrigin === locationInLadder.region {
                    P(">>> Dragging into same region")
                    if dragOriginDivision != .distal {
                    dragCreatedMark?.position.distal = Common.translateToAbsolutePosition(position: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height, offsetX: offset,scale: scale)
                    }
                    else {
                        dragCreatedMark?.position.proximal = Common.translateToAbsolutePosition(position: position, regionProximalBoundary: regionOfDragOrigin!.proximalBoundary, regionHeight: regionOfDragOrigin!.height, offsetX: offset,scale: scale)
                    }
                }
            }
            needsDisplay = true
        }
        if state == .ended {
            if let mark = movingMark {
                linkNearbyMarks(mark: mark)
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
        moveMark(mark: mark, relativePositionX: position.x)
        if moveCursor {
            let anchorPositionX = mark.getAnchorPositionX()
            cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
            cursorViewDelegate?.refresh()
        }
    }
}

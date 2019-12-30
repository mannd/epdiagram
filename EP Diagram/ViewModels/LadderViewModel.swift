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

extension Mark {
    func setRelativeMarkPosition(relativeMarkPosition: RelativeMarkPosition) {
        position = relativeMarkPosition.absoluteMarkPosition
    }

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

class LadderViewModel {
    // Half a region width above and below ladder
    let ladderPaddingMultiplier: CGFloat = 0.5

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
        PRINT("LadderViewModel initialize()")
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
        PRINT("Add mark at \(relativePositionX)")
        return ladder.addMarkAt(unscaledRelativePositionX(relativePositionX: relativePositionX))
    }

    private func unscaledRelativePositionX(relativePositionX: CGFloat) -> CGFloat {
        return relativePositionX / scale
    }

    func addMark(absolutePositionX: CGFloat) -> Mark? {
        return ladder.addMarkAt(absolutePositionX)
    }

    func deleteMark(mark: Mark) {
        ladder.deleteMark(mark: mark)
    }

    func deleteMark(mark: Mark, region: Region?) {
        ladder.deleteMark(mark: mark, region: region)
    }

    func moveMark(mark: Mark, relativePositionX: CGFloat) {
        let absolutePosition = Common.translateToAbsolutePositionX(positionX: relativePositionX, offset: offset, scale: scale)
        switch mark.anchor {
        case .proximal:
            mark.position.proximal.x = absolutePosition
        case .middle:
            // Determine halfway point between proximal and distal.
            let difference = (mark.position.proximal.x - mark.position.distal.x) / 2
            PRINT("mark.position.proximal.x = \(mark.position.proximal.x)")
            PRINT("mark.position.distal.x = \(mark.position.distal.x)")
            PRINT("difference = \(difference)")
            mark.position.proximal.x = absolutePosition + difference
            mark.position.distal.x = absolutePosition - difference
        case .distal:
            mark.position.distal.x = absolutePosition
        case .none:
            break
        }
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
        PRINT("LadderViewModel draw()")
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

    fileprivate func drawMark(mark: Mark, rect: CGRect, context: CGContext, region: Region) {
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
        //        if position.maxX() > rect.origin.x {
        context.setStrokeColor(getMarkColor(mark: mark, region: region))
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

    private func getMarkColor(mark: Mark, region: Region) -> CGColor {
        if mark.highlight == .all && region.selected   {
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
            drawMark(mark: mark, rect: rect, context: context, region: region)
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

    func reset() {
        initialize()
    }
}

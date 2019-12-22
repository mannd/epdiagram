//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

// We're going to be throwing around a lot these parameters, so let's make them a struct.
struct Displacement {
    var rect: CGRect
    var offset: CGFloat
    var scale: CGFloat
}

fileprivate extension Mark {
    func setPosition(relativePosition: MarkPosition, in rect:CGRect, offset: CGFloat, scale: CGFloat) {
        position.proximal = Common.translateToAbsolutePosition(location: relativePosition.proximal, inRect: rect, offsetX: offset, scale: scale)
        position.distal = Common.translateToAbsolutePosition(location: relativePosition.distal, inRect: rect, offsetX: offset, scale: scale)

    }

    func getPosition(in rect:CGRect, offset: CGFloat, scale: CGFloat) -> MarkPosition {
        return MarkPosition(proximal: Common.translateToRelativePosition(location: position.proximal, inRect: rect, offsetX: offset, scale: scale), distal: Common.translateToRelativePosition(location: position.distal, inRect: rect, offsetX: offset, scale: scale))
    }

    func setPosition(relativePosition: MarkPosition, displacement: Displacement) {
        position.proximal = Common.translateToAbsolutePosition(location: relativePosition.proximal, inRect: displacement.rect, offsetX: displacement.offset, scale: displacement.scale)
        position.distal = Common.translateToAbsolutePosition(location: relativePosition.distal, inRect: displacement.rect, offsetX: displacement.offset, scale: displacement.scale)
    }

    func getPosition(displacement: Displacement) -> MarkPosition {
        return MarkPosition(proximal: Common.translateToRelativePosition(location: position.proximal, inRect: displacement.rect, offsetX: displacement.offset, scale: displacement.scale), distal: Common.translateToRelativePosition(location: position.distal, inRect: displacement.rect, offsetX: displacement.offset, scale: displacement.scale))
    }

    convenience init(relativePosition: MarkPosition, in rect: CGRect, offset: CGFloat, scale: CGFloat) {
        self.init()
        setPosition(relativePosition: relativePosition, in: rect, offset: offset, scale: scale)
    }

    convenience init(relativePosition: MarkPosition, displacement: Displacement) {
        self.init()
        setPosition(relativePosition: relativePosition, displacement: displacement)
    }
}

class LadderViewModel {
    var offset: CGFloat = 0
    var scale: CGFloat = 1

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
    let red: UIColor
    let blue: UIColor
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
        red = UIColor.systemRed
        blue = UIColor.systemBlue
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
        var regionBoundary = regionUnitHeight
        for region: Region in ladder.regions {
            let regionHeight = getRegionHeight(region: region)
            region.proximalBoundary = regionBoundary
            region.distalBoundary = regionBoundary + regionHeight
            regionBoundary += regionHeight
            regions.append(region)
        }
    }

    func addMark(location: CGFloat) -> Mark? {
        PRINT("Add mark at \(location)")
        return ladder.addMarkAt(location)
    }

    func addMark(relativePosition: MarkPosition, displacement: Displacement) -> Mark? {
        let mark = Mark(relativePosition: relativePosition, displacement: displacement)
        return ladder.addMark(mark: mark)
    }

    func deleteMark(mark: Mark) {
        ladder.deleteMark(mark: mark)
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
        // TODO: Handle reverse slanting of points
        PRINT("Mark position = \(position)")
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
        context.strokePath()
        context.setStrokeColor(getLineColor())
        //        }
    }

    func getTruncatedPosition(position: MarkPosition) -> CGPoint? {
        // TODO: Handle lines slanted backwards, don't draw at all in margin
        let intersection = getIntersection(ofLineFrom: CGPoint(x: margin, y: 0), to: CGPoint(x: margin, y: height), withLineFrom: position.proximal, to: position.distal)
        return intersection
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
        let proximalX = Common.translateToRelativeLocation(location:mark.position.proximal.x, offset:offset, scale: scale)
        let distalX = Common.translateToRelativeLocation(location: mark.position.distal.x, offset: offset, scale: scale)
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
        // we'll allow one region unit space above and below, so...
        numRegionUnits += 2
        return height / CGFloat(numRegionUnits)
    }


//    func regions() -> [Region] {
//        return ladder.regions
//    }

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

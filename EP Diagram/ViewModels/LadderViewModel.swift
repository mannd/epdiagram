//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderViewModel {
    struct RegionDetail {
        var region: Region
        var isLastRegion: Bool = false
    }
    var regionDetails: [RegionDetail] = []

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
    var activeMark: Mark?
    // Set reset to true to reinit view model.
    var margin: CGFloat = 0
    var lineWidth: CGFloat = 2

    let red: UIColor
    let blue: UIColor
    let unselectedColor: UIColor
    let selectedColor = UIColor.magenta

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
        print("LadderViewModel initialize()")
        regionUnitHeight = getRegionUnitHeight(ladder: ladder)
        regionDetails.removeAll()
        var regionBoundary = regionUnitHeight
        var regionNumber = 0
        for region: Region in ladder.regions {
            var regionDetail: RegionDetail = RegionDetail(region: region, isLastRegion: false)
            let regionHeight = getRegionHeight(region: region)
            region.upperBoundary = regionBoundary
            region.lowerBoundary = regionBoundary + regionHeight
            regionBoundary += regionHeight
            regionNumber += 1
            regionDetail.isLastRegion = (regionNumber >= ladder.regions.count)
            regionDetails.append(regionDetail)
        }
    }

    func addMark(location: CGFloat) -> Mark? {
        print("Add mark at \(location)")
        return ladder.addMarkAt(location)
    }

    func deleteMark(mark: Mark) {
        ladder.deleteMark(mark: mark)
    }

    func getRegionHeight(region: Region) -> CGFloat {
        return region.decremental ? 2 * regionUnitHeight : regionUnitHeight
    }

    func draw(rect: CGRect, offset: CGFloat, scale: CGFloat, context: CGContext) {
        print("LadderViewModel draw()")
        if #available(iOS 13.0, *) {
            context.setStrokeColor(UIColor.label.cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }
        context.setLineWidth(1)
        // All horizontal distances are adjusted to scale.
        let ladderWidth: CGFloat = rect.width * scale
        for regionDetail: RegionDetail in regionDetails {
            print("regionDetails.count = \(regionDetails.count)")
            let region = regionDetail.region
            let regionRect = CGRect(x: margin, y: region.upperBoundary, width: ladderWidth, height: region.lowerBoundary - region.upperBoundary)
            drawRegion(rect: regionRect, context: context, region: region, offset: offset, scale: scale, lastRegion: regionDetail.isLastRegion)
        }
    }

    fileprivate func drawLabel(_ rect: CGRect, _ region: Region, _ context: CGContext) {
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
    fileprivate func drawRegionArea(_ context: CGContext, _ rect: CGRect, _ region: Region) {
        // Draw top ladder line
        if #available(iOS 13.0, *) {
            context.setStrokeColor(UIColor.label.cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }

        print("drawRegionArea")
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

    fileprivate func drawMarks(_ region: Region, _ scale: CGFloat, _ offset: CGFloat, _ context: CGContext, _ rect: CGRect) {
        // Draw marks
        for mark: Mark in region.marks {
            let scrolledStartLocation = scale * mark.position.proximal.x - offset
            let scrolledEndLocation = scale * mark.position.distal.x - offset
            context.setLineWidth(lineWidth)
            // Don't bother drawing marks in margin.
            if scrolledStartLocation > rect.origin.x {
                let color: CGColor
                if mark.selected && region.selected   {
                    color = selectedColor.cgColor
                }
                else {
                    color = unselectedColor.cgColor
                }
                context.setStrokeColor(color)
                context.move(to: CGPoint(x: scrolledStartLocation, y: rect.origin.y))
                context.addLine(to: CGPoint(x: scrolledEndLocation, y: rect.origin.y + rect.height))
                context.strokePath()
                if #available(iOS 13.0, *) {
                    context.setStrokeColor(UIColor.label.cgColor)
                } else {
                    context.setStrokeColor(UIColor.black.cgColor)
                }
            }
        }
    }

    fileprivate func drawBottomLine(_ context: CGContext, _ lastRegion: Bool, _ rect: CGRect) {
        // Draw bottom line of region if it is the last region of the ladder.
        context.setLineWidth(1)
        if lastRegion {
            context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
            context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y + rect.height))
        }
        context.strokePath()
    }

    func drawRegion(rect: CGRect, context: CGContext, region: Region, offset: CGFloat, scale: CGFloat, lastRegion: Bool) {
        drawLabel(rect, region, context)
        drawRegionArea(context, rect, region)
        drawMarks(region, scale, offset, context, rect)
        drawBottomLine(context, lastRegion, rect)
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


    func regions() -> [Region] {
        return ladder.regions
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
                mark.selected = false
                mark.attached = false
            }
        }
    }

    func reset() {
        initialize()
    }

//    // Translates from LadderView coordinates to Mark coordinates.
//    func translateToAbsoluteLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
//        return (location + offset) / scale
//    }
//
//    // Translate from Mark coordinates to LadderView coordinates.
//    func translateToRelativeLocation(location: CGFloat, offset: CGFloat, scale: CGFloat) -> CGFloat {
//        return scale * location - offset
//    }
}

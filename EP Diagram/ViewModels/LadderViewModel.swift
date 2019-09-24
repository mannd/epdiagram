//
//  LadderViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderViewModel {
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
    var reset = true
    var regionUnitHeight: CGFloat = 0
    var margin: CGFloat = 0
    var lineWidth: CGFloat = 2

    let red: UIColor
    let blue: UIColor
    let unselectedColor: UIColor
    let selectedColor = UIColor.magenta

    convenience init() {
        self.init(ladder: Ladder.defaultLadder())
        let regions = ladder.regions
        // Temporarily act on first region
        ladder.activeRegion = regions[0]
    }

    init(ladder: Ladder) {
        self.ladder = ladder
        red = UIColor.systemRed
        blue = UIColor.systemBlue
        if #available(iOS 13.0, *) {
            unselectedColor = UIColor.label
        } else {
            unselectedColor = UIColor.black
        }
    }

    func addMark(location: CGFloat) -> Mark? {
        print("Add mark at \(location)")
        return ladder.addMarkAt(location)
    }

    func deleteMark(mark: Mark) {
        ladder.deleteMark(mark: mark)
    }

    func draw(rect: CGRect, offset: CGFloat, scale: CGFloat, context: CGContext) {
        if #available(iOS 13.0, *) {
            context.setStrokeColor(UIColor.label.cgColor)
        } else {
            context.setStrokeColor(UIColor.black.cgColor)
        }
        context.setLineWidth(1)
        // All horizontal distances are adjusted to scale.
        let ladderWidth: CGFloat = rect.width * scale
        // unitHeight assumes top and bottom margins equal to height of non-decremental
        // region, and decremental regions are twice this height.
        if reset {
            regionUnitHeight = getRegionUnitHeight(rect: rect, ladder: ladder)
            reset = false
        }
        // First region is one unitHeight below top of LadderView.
        var regionBoundary = regionUnitHeight
        var regionNumber = 0
        for region: Region in ladder.regions {
            let regionHeight = region.decremental ? 2 * regionUnitHeight : regionUnitHeight
            region.upperBoundary = regionBoundary
            region.lowerBoundary = regionBoundary + regionHeight
            let regionRect = CGRect(x: margin, y: regionBoundary, width: ladderWidth, height: regionHeight)
            regionBoundary += regionHeight
            regionNumber += 1
            var lastRegion = false
            if regionNumber >= ladder.regions.count {
                lastRegion = true
            }
            drawRegion(rect: regionRect, context: context, region: region, offset: offset, scale: scale, lastRegion: lastRegion)
        }
    }

    func drawRegion(rect: CGRect, context: CGContext, region: Region, offset: CGFloat, scale: CGFloat, lastRegion: Bool) {
        // draw label
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
            context.setFillColor(red.cgColor)
            let regionRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
            context.setAlpha(0.2)
            context.addRect(regionRect)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1)
        context.strokePath()

        // Draw marks
        for mark: Mark in region.marks {
            let scrolledStartLocation = scale * mark.position.origin.x - offset
            let scrolledEndLocation = scale * mark.position.terminus.x - offset
            context.setLineWidth(lineWidth)
            // Don't bother drawing marks in margin.
            if scrolledStartLocation > rect.origin.x {
                let color: CGColor
                if mark.selected {
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

        // Draw bottom line of region if it is the last region of the ladder.
        context.setLineWidth(1)
        if lastRegion {
            context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + rect.height))
            context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y + rect.height))
        }
        context.strokePath()
    }

    func getRegionUnitHeight(rect: CGRect, ladder: Ladder) -> CGFloat {
        var numRegionUnits = 0
        for region: Region in ladder.regions {
            numRegionUnits += region.decremental ? 2 : 1
        }
        // we'll allow one region unit space above and below, so...
        numRegionUnits += 2
        return rect.height / CGFloat(numRegionUnits)
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

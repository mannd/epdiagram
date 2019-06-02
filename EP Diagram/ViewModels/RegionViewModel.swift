//
//  RegionViewModel.swift
//  EP Diagram
//
//  Created by David Mann on 6/2/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class RegionViewModel: NSObject {
    let startPosition: CGFloat
    let height: CGFloat
    let region: Region

    init(startPosition: CGFloat, height: CGFloat, region: Region) {
        self.startPosition = startPosition
        self.height = height
        self.region = region
    }

    func draw(context: CGContext, originX: CGFloat, scale: CGFloat, width: CGFloat, margin: CGFloat) {
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        // Draw ladder lines
        context.move(to: CGPoint(x: margin, y: startPosition))
        context.addLine(to: CGPoint(x: width, y: startPosition))
        for mark: Mark in region.marks {
            let scrolledStartPosition = scale * CGFloat(mark.startPosition!) - originX
            let scrolledEndPosition = scale * CGFloat(mark.endPosition!) - originX
            context.move(to: CGPoint(x: scrolledStartPosition, y: startPosition))
            context.addLine(to: CGPoint(x: scrolledEndPosition, y: startPosition + height))
        }
        // TODO: Really should only bother drawing last line if last region.
        context.move(to: CGPoint(x: margin, y: startPosition + height))
        context.addLine(to: CGPoint(x: width, y: startPosition + height))
        context.strokePath()
    }
}

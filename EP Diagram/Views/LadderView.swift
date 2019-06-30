//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol CursorViewDelegate: AnyObject {
    func cursorViewRefresh()
    func cursorViewGrabMark(mark: Mark?)
}

class LadderView: UIView, LadderViewDelegate {

    weak var scrollView: UIScrollView!
    var leftMargin: CGFloat = 0
    var scale: CGFloat = 1.0
    weak var delegate: CursorViewDelegate?

    var ladderViewModel: LadderViewModel? = nil

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        ladderViewModel = LadderViewModel()
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)
        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.dragging))
        self.addGestureRecognizer(draggingPanRecognizer)
    }

    // Mark delegate
    // convert region start Y position to view's coordinates and return to view
    func ladderViewGetMarkStartPosition(view: UIView) -> CGFloat {
            let position = CGPoint(x: 0, y: ladderViewModel?.activeRegion?.startPosition ?? 0)
            NSLog("StartPosition = \(position)")
            return convert(position, to: view).y
    }

    func ladderViewDeleteMark(location: CGFloat) {
        print("Delete mark at \(location)")
    }

    func ladderViewMakeMark(location: CGFloat) {
        print("Make mark at \(location)")
        // FIXME: Need to convert cursor location to a mark location, which
        // depends on scale and scolling!
        ladderViewModel?.addMark(location: translateToAbsolutePosition(location))
        setNeedsDisplay()
    }

    // Translates from LadderView coordinates to Mark coordinates.
    func translateToAbsolutePosition(_ location: CGFloat) -> CGFloat {
        return ladderViewModel?.translateToAbsolutePosition(location: location, offset: scrollView.contentOffset.x, scale: scale) ?? location
    }

    // Translate from Mark coordinates to LadderView coordinates.
    func translateToRelativePosition(_ location: CGFloat) -> CGFloat {
        return ladderViewModel?.translateToRelativePosition(location: location, offset: scrollView.contentOffset.x, scale: scale) ?? location
    }

    // Touches
    @objc func singleTap(tap: UITapGestureRecognizer) {
        guard let ladderViewModel = ladderViewModel else { return }
        print("Single tap on ladder view")
        // select region tapped or select mark
        for region in (ladderViewModel.regions()) {
            if tap.location(in: self).y > region.startPosition && tap.location(in: self).y < region.endPosition {
                ladderViewModel.activeRegion = region
                // Are we near a mark?  If so, grab it, i.e. move cursor to it and attach.
                if let activeRegion = ladderViewModel.activeRegion {
                    // FIXME: need to adjust mark position for scrolling!
                    for mark in activeRegion.marks {
                        if tap.location(in: self).x < translateToRelativePosition(mark.startPosition) + 40 && tap.location(in: self).x > translateToRelativePosition(mark.startPosition) - 40 {
                            print("close to mark")
                            delegate?.cursorViewGrabMark(mark: mark)
                            return
                        }
                    }
                }
            }
        }
        setNeedsDisplay()
        delegate?.cursorViewRefresh()

    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        print("Double tap on ladder view")
        // unselect region or unselect mark
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        print("Dragging on ladder view")
        // somehow draw connections :)
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel?.draw(rect: rect, margin: leftMargin, offset: scrollView.contentOffset.x, scale: scale, context: context)
        }
    }



}

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
    func cursorViewMoveCursor(location: CGFloat)
    func cursorViewRecenterCursor()
    func cursorViewHighlightCursor(_ on: Bool)
}

class LadderView: UIView, LadderViewDelegate {

    struct TapResult {
        var tappedRegion: Region?
        var tappedLabel: RegionLabel?
        var tappedMark: Mark?
        var regionTapped: Bool {
            tappedRegion != nil
        }
        var labelTapped: Bool {
            tappedLabel != nil
        }
        var markTapped: Bool {
            tappedMark != nil
        }
    }

    weak var scrollView: UIScrollView!
    var leftMargin: CGFloat = 0
    var scale: CGFloat = 1.0
    weak var delegate: CursorViewDelegate?
    var ladderViewModel: LadderViewModel? = nil

    let differential: CGFloat = 20

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

    // Translates from LadderView coordinates to Mark coordinates.
    func translateToAbsoluteLocation(_ location: CGFloat) -> CGFloat {
        return ladderViewModel?.translateToAbsoluteLocation(location: location, offset: scrollView.contentOffset.x, scale: scale) ?? location
    }

    // Translate from Mark coordinates to LadderView coordinates.
    func translateToRelativeLocation(_ location: CGFloat) -> CGFloat {
        return ladderViewModel?.translateToRelativeLocation(location: location, offset: scrollView.contentOffset.x, scale: scale) ?? location
    }

    // Touches
    @objc func singleTap(tap: UITapGestureRecognizer) {
        guard let ladderViewModel = ladderViewModel else { return }
        print("Single tap on ladder view")
        // select region tapped or select mark
        let tapLocation = tap.location(in: self)
        let tapResult = getTapResult(location: tapLocation, ladderViewModel: ladderViewModel)
        ladderViewModel.activeRegion = tapResult.tappedRegion
        print("Region was tapped = \(tapResult.regionTapped)")
        print("Label was tapped = \(tapResult.labelTapped)")
        print("Mark was tapped = \(tapResult.markTapped)")
        if let mark = tapResult.tappedMark {
            if mark.grabbed {
                mark.grabbed = false
                // delegate?.cursorViewReleaseMark(mark: mark)
                delegate?.cursorViewRecenterCursor()
                delegate?.cursorViewHighlightCursor(false)
            }
            else {
                mark.grabbed = true
                delegate?.cursorViewGrabMark(mark: mark)
                delegate?.cursorViewMoveCursor(location: translateToRelativeLocation(mark.start))
                delegate?.cursorViewHighlightCursor(true)
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

    func getTapResult(location: CGPoint, ladderViewModel: LadderViewModel) -> TapResult {
        var tappedRegion: Region?
        var tappedLabel: RegionLabel?
        var tappedMark: Mark?
        for region in (ladderViewModel.regions()) {
            if location.y > region.upperBoundary && location.y < region.lowerBoundary {
                tappedRegion = region
            }
        }
        if let tappedRegion = tappedRegion {
            if location.x < leftMargin {
                tappedLabel = tappedRegion.label
            }
            outerLoop: for mark in tappedRegion.marks {
                if nearMark(location: location.x, mark: mark) {
                    tappedMark = mark
                    break outerLoop
                }
            }
        }
        return TapResult(tappedRegion: tappedRegion, tappedLabel: tappedLabel, tappedMark: tappedMark)
    }

    private func nearMark(location: CGFloat, mark: Mark) -> Bool {
        return location < translateToRelativeLocation(mark.end) + differential && location > translateToRelativeLocation(mark.start) - differential
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel?.draw(rect: rect, margin: leftMargin, offset: scrollView.contentOffset.x, scale: scale, context: context)
        }
    }

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func ladderViewGetRegionUpperBoundary(view: UIView) -> CGFloat {
        let location = CGPoint(x: 0, y: ladderViewModel?.activeRegion?.upperBoundary ?? 0)
        print("Upper boundary = \(location)")
        return convert(location, to: view).y
    }

    func ladderViewDeleteMark(location: CGFloat) {
        print("Delete mark at \(location)")
    }

    func ladderViewMakeMark(location: CGFloat) {
        // print("Make mark at \(location)")
        ladderViewModel?.addMark(location: translateToAbsoluteLocation(location))
        setNeedsDisplay()
    }

    func reset() {
        ladderViewModel?.reset = true
    }


}

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
    func cursorViewAttachMark(mark: Mark?)
    func cursorViewUnattachMark()
    func cursorViewMoveCursor(location: CGFloat)
    func cursorViewRecenterCursor()
    func cursorViewHighlightCursor(_ on: Bool)
    func cursorViewHideCursor(hide: Bool)
}

class LadderView: UIView, LadderViewDelegate {

    /// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
    struct TapLocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection
        var regionWasTapped: Bool {
            tappedRegion != nil
        }
        var labelWasTapped: Bool {
            tappedRegionSection == .labelSection
        }
        var markWasTapped: Bool {
            tappedMark != nil
        }
    }

    weak var scrollView: UIScrollView!
    var leftMargin: CGFloat = 0
    var scale: CGFloat = 1.0
    weak var delegate: CursorViewDelegate?
    var ladderViewModel: LadderViewModel? = nil

    // How close a touch has to be to count: +/- accuracy.
    let accuracy: CGFloat = 20

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
        let tapLocation = getTapLocationInLadder(location: tap.location(in: self), ladderViewModel: ladderViewModel)
        print("Region was tapped = \(tapLocation.regionWasTapped)")
        print("Label was tapped = \(tapLocation.labelWasTapped)")
        print("Mark was tapped = \(tapLocation.markWasTapped)")
        if tapLocation.labelWasTapped {
            if let tappedRegion = tapLocation.tappedRegion {
                if tappedRegion.selected {
                    tappedRegion.selected = false
                    ladderViewModel.activeRegion = nil
                    delegate?.cursorViewHideCursor(hide: true)
                }
                else { // !tappedRegion.selected
                    ladderViewModel.activeRegion = tappedRegion
                    delegate?.cursorViewHideCursor(hide: false)
                    // unattach cursor
                    delegate?.cursorViewRecenterCursor()
                    delegate?.cursorViewHighlightCursor(false)
                }
            }
        }
        else if (tapLocation.regionWasTapped) {
            if let tappedRegion = tapLocation.tappedRegion {
                if !tappedRegion.selected {
                    ladderViewModel.activeRegion = tappedRegion
                    delegate?.cursorViewHideCursor(hide: false)
                }
                // make mark and attach cursor
                if let mark = tapLocation.tappedMark {
                    if mark.attached {
                        // FIXME: attached and selected maybe the same thing, eliminate duplication.
                        mark.attached = false
                        mark.selected = false
                        // delegate?.cursorViewReleaseMark(mark: mark)
                        delegate?.cursorViewRecenterCursor()
                        delegate?.cursorViewHighlightCursor(false)
                        delegate?.cursorViewUnattachMark()
                    }
                    else {
                        mark.attached = true
                        mark.selected = true
                        delegate?.cursorViewAttachMark(mark: mark)
                        delegate?.cursorViewMoveCursor(location: translateToRelativeLocation(mark.start))
                        delegate?.cursorViewHighlightCursor(true)
                    }
                }
                else { // make mark and attach cursor
                    print("make mark and attach cursor")
                    let mark = ladderViewMakeMark(location: tap.location(in: self).x)
                    if let mark = mark {
                        mark.attached = true
                        mark.selected = true
                        delegate?.cursorViewAttachMark(mark: mark)
                        delegate?.cursorViewMoveCursor(location: translateToRelativeLocation(mark.start))
                        delegate?.cursorViewHighlightCursor(true)
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
        // FIXME: need to store active mark, and move it along with cursor, otherwise,
        // ignore or draw connections.
//        let delta = pan.translation(in: self)
//        cursor.move(delta: delta)
//        if let attachedMark = attachedMark {
//            print("Move grabbed Mark")
//            delegate?.ladderViewMoveMark(mark: attachedMark, location: cursor.location)
//            delegate?.ladderViewRefresh()
//        }
//        pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
//        setNeedsDisplay())
    }

    /// Magic function that returns struct indicating what part of ladder was touched.
    /// - Parameter location: point that was touched
    /// - Parameter ladderViewModel: ladderViewModel in use
    func getTapLocationInLadder(location: CGPoint, ladderViewModel: LadderViewModel) -> TapLocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        for region in (ladderViewModel.regions()) {
            if location.y > region.upperBoundary && location.y < region.lowerBoundary {
                tappedRegion = region
            }
        }
        if let tappedRegion = tappedRegion {
            if location.x < leftMargin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(location: location.x, mark: mark) {
                        tappedMark = mark
                        break outerLoop
                    }
                }
            }
        }
        return TapLocationInLadder(tappedRegion: tappedRegion, tappedMark: tappedMark, tappedRegionSection: tappedRegionSection)
    }

    private func nearMark(location: CGFloat, mark: Mark) -> Bool {
        return location < translateToRelativeLocation(mark.end) + accuracy && location > translateToRelativeLocation(mark.start) - accuracy
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel?.draw(rect: rect, margin: leftMargin, offset: scrollView.contentOffset.x, scale: scale, context: context)
        }
    }

    func reset() {
        ladderViewModel?.reset = true
    }

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func ladderViewGetRegionUpperBoundary(view: UIView) -> CGFloat {
        let location = CGPoint(x: 0, y: ladderViewModel?.activeRegion?.upperBoundary ?? 0)
        return convert(location, to: view).y
    }

    func ladderViewDeleteMark(location: CGFloat) {
        print("Delete mark at \(location)")
    }

    func ladderViewMakeMark(location: CGFloat) -> Mark? {
        // print("Make mark at \(location)")
        return ladderViewModel?.addMark(location: translateToAbsoluteLocation(location))
    }

    func ladderViewDeleteMark(mark: Mark) {
        print("Delete mark \(mark)")
        ladderViewModel?.deleteMark(mark: mark)
    }

    func ladderViewRefresh() {
        setNeedsDisplay()
    }
    
    func ladderViewMoveMark(mark: Mark, location: CGFloat) {
        mark.start = translateToAbsoluteLocation(location)
        mark.end = mark.start
    }


}

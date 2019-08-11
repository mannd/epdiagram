//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderViewDelegate: AnyObject {
    func makeMark(location: CGFloat) -> Mark?
    func deleteMark(location: CGFloat)
    func deleteMark(mark: Mark)
    func getRegionUpperBoundary(view: UIView) -> CGFloat
    func moveMark(mark: Mark, location: CGFloat)
    func refresh()
    func findMarkNearby(location: CGFloat) -> Mark?
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
}

class LadderView: UIView, LadderViewDelegate {

    /// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
    struct LocationInLadder {
        var region: Region?
        var mark: Mark?
        var regionSection: RegionSection
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

    // FIXME: movingMark == selectedMark == highlightedMark ???
    var movingMark: Mark? = nil

    var contentOffset: CGFloat = 0
    var leftMargin: CGFloat = 0 {
        didSet {
            ladderViewModel?.margin = leftMargin
        }
    }

    var scale: CGFloat = 1.0
    weak var cursorViewDelegate: CursorViewDelegate?
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

    // Touches
    @objc func singleTap(tap: UITapGestureRecognizer) {
        guard let ladderViewModel = ladderViewModel else { return }
        let tapLocation = getLocationInLadder(location: tap.location(in: self), ladderViewModel: ladderViewModel)
        print("Region was single-tapped = \(tapLocation.regionWasTapped)")
        print("Label was single-tapped = \(tapLocation.labelWasTapped)")
        print("Mark was single-tapped = \(tapLocation.markWasTapped)")
        if tapLocation.labelWasTapped {
            if let tappedRegion = tapLocation.region {
                if tappedRegion.selected {
                    tappedRegion.selected = false
                    ladderViewModel.activeRegion = nil
                }
                else { // !tappedRegion.selected
                    ladderViewModel.activeRegion = tappedRegion
                    cursorViewDelegate?.hideCursor(hide: true)
                    // unattach cursor
//                    delegate?.cursorViewRecenterCursor()
                }
                cursorViewDelegate?.hideCursor(hide: true)
                cursorViewDelegate?.unattachMark()
            }
        }
        else if (tapLocation.regionWasTapped) {
            if let tappedRegion = tapLocation.region {
                if !tappedRegion.selected {
                    ladderViewModel.activeRegion = tappedRegion
                    cursorViewDelegate?.hideCursor(hide: true)
                    cursorViewDelegate?.unattachMark()
                }
                // make mark and attach cursor
                if let mark = tapLocation.mark {
                    if mark.attached {
                        // FIXME: attached and selected maybe the same thing, eliminate duplication.
                        mark.attached = false
                        mark.selected = false
                        // delegate?.cursorViewReleaseMark(mark: mark)
                        cursorViewDelegate?.hideCursor(hide: true)
//                        delegate?.cursorViewRecenterCursor()
//                        delegate?.cursorViewHighlightCursor(false)
                        cursorViewDelegate?.unattachMark()
                    }
                    else {
                        mark.attached = true
                        mark.selected = true
                        cursorViewDelegate?.attachMark(mark: mark)
                        cursorViewDelegate?.moveCursor(location: translateToRelativeLocation(location: mark.start, offset: contentOffset, scale: scale))
                        cursorViewDelegate?.hideCursor(hide: false)
//                        delegate?.cursorViewHighlightCursor(true)
                    }
                }
                else { // make mark and attach cursor
                    print("make mark and attach cursor")
                    let mark = makeMark(location: tap.location(in: self).x)
                    if let mark = mark {
                        mark.attached = true
                        mark.selected = true
                        cursorViewDelegate?.attachMark(mark: mark)
                        cursorViewDelegate?.moveCursor(location: translateToRelativeLocation(location: mark.start, offset: contentOffset, scale: scale))
                        cursorViewDelegate?.highlightCursor(true)
                        cursorViewDelegate?.hideCursor(hide: false)
                    }
                }
            }
        }
        setNeedsDisplay()
        cursorViewDelegate?.refresh()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        print("Double tap on ladder view")
        // unselect region or unselect mark
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        print("Dragging on ladder view")
        // FIXME: need to store active mark, and move it along with cursor, otherwise,
        // ignore or draw connections.
        if pan.state == .began {
            print("dragging began")
            if let ladderViewModel = ladderViewModel {
                let location = getLocationInLadder(location: pan.location(in: self), ladderViewModel: ladderViewModel)
                if let mark = location.mark {
                    movingMark = mark
                }
            }
        }
        if pan.state == .changed {
            print("dragging state changed")
            if let mark = movingMark {
                moveMark(mark: mark, location: pan.location(in: self).x)
                // TODO: move cursor too
                setNeedsDisplay()
            }
        }
        if pan.state == .ended {
            print("dragging state ended")
            movingMark = nil
        }
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter location: point to be processed
    /// - Parameter ladderViewModel: ladderViewModel in use
    func getLocationInLadder(location: CGPoint, ladderViewModel: LadderViewModel) -> LocationInLadder {
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
        return LocationInLadder(region: tappedRegion, mark: tappedMark, regionSection: tappedRegionSection)
    }

    private func nearMark(location: CGFloat, mark: Mark) -> Bool {
//        return location < mark.end && location > mark.start
        return location < translateToRelativeLocation(location: mark.end, offset: contentOffset, scale: scale) + accuracy && location > translateToRelativeLocation(location: mark.start, offset: contentOffset, scale: scale) - accuracy
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel?.draw(rect: rect, offset: contentOffset, scale: scale, context: context)
        }
    }

    func reset() {
        ladderViewModel?.reset = true
    }

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionUpperBoundary(view: UIView) -> CGFloat {
        let location = CGPoint(x: 0, y: ladderViewModel?.activeRegion?.upperBoundary ?? 0)
        return convert(location, to: view).y
    }

    func deleteMark(location: CGFloat) {
        print("Delete mark at \(location)")
    }

    func makeMark(location: CGFloat) -> Mark? {
        // print("Make mark at \(location)")
        print("Relative location = \(translateToRelativeLocation(location: location, offset: contentOffset, scale: scale))")
        print("Absoulte location = \(translateToAbsoluteLocation(location: location, offset: contentOffset, scale: scale))")
//        return ladderViewModel?.addMark(location: translateToAbsoluteLocation(location: location, offset: contentOffset, scale: scale))
        return ladderViewModel?.addMark(location: location)
    }

    func addMark(location: CGFloat) -> Mark? {
//                return ladderViewModel?.addMark(location: translateToAbsoluteLocation(location: location, offset: contentOffset, scale: scale))
        return ladderViewModel?.addMark(location: location / scale)
    }

    func deleteMark(mark: Mark) {
        print("Delete mark \(mark)")
        ladderViewModel?.deleteMark(mark: mark)
    }

    func refresh() {
        setNeedsDisplay()
    }
    
    func moveMark(mark: Mark, location: CGFloat) {
//        mark.start = translateToAbsoluteLocation(location: location, offset: contentOffset, scale: scale)
        mark.start = location
        mark.end = mark.start
    }

    func findMarkNearby(location: CGFloat) -> Mark? {
        if let activeRegion = ladderViewModel?.activeRegion {
            let relativeLocation = translateToRelativeLocation(location: location, offset: contentOffset, scale: scale)
            for mark in activeRegion.marks {
                if abs(mark.start - relativeLocation) < accuracy {
                    return mark
                }
            }
        }
        return nil
    }

    // TODO: This doesn't work, region not being selected
    func setActiveRegion(regionNum: Int) {
        ladderViewModel?.activeRegion = ladderViewModel?.regions()[regionNum]
        ladderViewModel?.activeRegion?.selected = true
    }

    func hasActiveRegion() -> Bool {
        return ladderViewModel?.activeRegion != nil
    }
}

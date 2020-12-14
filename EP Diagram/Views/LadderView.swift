//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log

protocol LadderViewDelegate: AnyObject {
    func getRegionProximalBoundary(view: UIView) -> CGFloat
    func getRegionDistalBoundary(view: UIView) -> CGFloat
    func getRegionMidPoint(view: UIView) -> CGFloat
    func getAttachedMarkLadderViewPositionY(view: UIView) -> CGPoint?
    func getPositionYInView(positionY: CGFloat, view: UIView) -> CGFloat
    func getTopOfLadder(view: UIView) -> CGFloat

    func refresh()
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
    func unhighlightAllMarks()
    func deleteAttachedMark()
    func groupMarksNearbyAttachedMark()
    func addAttachedMark(scaledViewPositionX: CGFloat)
    func unattachAttachedMark()
    func groupNearbyMarks(mark: Mark)
    func moveAttachedMark(position: CGPoint)
    func fixBoundsOfAttachedMark()
    func getAttachedMarkAnchor() -> Anchor
    func assessBlockAndImpulseOrigin(mark: Mark?)
    func getAttachedMarkScaledAnchorPosition() -> CGPoint?
    func setAttachedMarkAndGroupedMarksHighlights()
    func toggleAttachedMarkAnchor()
}

final class LadderView: ScaledView {
    private let ladderPaddingMultiplier: CGFloat = 0.5
    private let accuracy: CGFloat = 20
    private let lowerLimitMarkHeight: CGFloat = 0.1
    private let lowerLimitMarkWidth: CGFloat = 20
    private let nearbyMarkAccuracy: CGFloat = 15

    // TODO: lineWidth vs markLineWidth??????
    // variables that need to eventually be preferences
    var markLineWidth: CGFloat = 2
    var connectedLineWidth: CGFloat = 4
    var red = UIColor.systemRed
    var blue = UIColor.systemBlue
    var unhighlightedColor = UIColor.label
    var attachedColor = UIColor.systemOrange
    var linkColor = UIColor.systemGreen
    var selectedColor = UIColor.systemRed
    var groupedColor = UIColor.systemPurple
    var snapMarks = true

    // Controlled by Preferences at present.
    var lineWidth: CGFloat = 2
    var showImpulseOrigin = true
    var showBlock = true
    var showPivots = true
    var showIntervals = true
    var showMarkText = true

    var ladderIsLocked = false

    var calibration: Calibration?

    var isZoning: Bool = false
    let zoneColor = UIColor.systemIndigo

    var ladderIsDirty: Bool {
        get {
            ladder.isDirty
        }
        set(newValue) {
            ladder.isDirty = newValue
        }
    }
    var marksAreVisible: Bool {
        get {
            ladder.marksAreVisible
        }
        set(newValue) {
            ladder.marksAreVisible = newValue
        }
    }

    var ladder: Ladder = Ladder.defaultLadder()


    private var activeRegion: Region? {
        didSet { activateRegion(region: activeRegion)}
    }
    private var attachedMark: Mark? {
        get {
            return ladder.attachedMark
        }
        set(newValue) {
            ladder.attachedMark = newValue
        }
    }
    private var pressedMark: Mark? {
        get {
            return ladder.pressedMark
        }
        set(newValue) {
            ladder.pressedMark = newValue
        }
    }
    private var movingMark: Mark? {
        get {
            return ladder.movingMark
        }
        set(newValue) {
            ladder.movingMark = newValue
        }
    }

    private var regionOfDragOrigin: Region?
    private var regionProximalToDragOrigin: Region?
    private var regionDistalToDragOrigin: Region?
    private var dragCreatedMark: Mark?
    private var dragOriginDivision: RegionDivision = .none

    var mode: Mode = .normal

    var leftMargin: CGFloat = 0
    internal var ladderViewHeight: CGFloat = 0
    private var regionUnitHeight: CGFloat = 0

    weak var cursorViewDelegate: CursorViewDelegate! // Note IUO.
    var currentDocument: DiagramDocument?

    override var canBecomeFirstResponder: Bool { return true }

    // MARK: - init

    // This is not called because view is created from storyboard.
    override init(frame: CGRect) {
        os_log("init(frame:) - LadderView", log: .viewCycle, type: .info)
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        os_log("init(coder:) - LadderView", log: .viewCycle, type: .info)
        super.init(coder: aDecoder)
        setupView()
    }

    func reset() {
        os_log("reset() - LadderView", log: .action, type: .info)
    }

    private func setupView() {
        os_log("didLoad() - LadderView", log: .action, type: .info)
        ladderViewHeight = self.frame.height
        initializeRegions()

        // Draw border around view.
        layer.masksToBounds = true
        layer.borderColor = UIColor.systemBlue.cgColor
        layer.borderWidth = 2

        // Set up touches.
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.singleTap))
        singleTapRecognizer.numberOfTapsRequired = 1
        self.addGestureRecognizer(singleTapRecognizer)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        singleTapRecognizer.require(toFail: doubleTapRecognizer)
        self.addGestureRecognizer(doubleTapRecognizer)

        let draggingPanRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.dragging))
        self.addGestureRecognizer(draggingPanRecognizer)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress))
        self.addGestureRecognizer(longPressRecognizer)
    }

    private func initializeRegions() {
        regionUnitHeight = getRegionUnitHeight(ladder: ladder)
        var regionBoundary = regionUnitHeight * ladderPaddingMultiplier
        for region: Region in ladder.regions {
            let regionHeight = CGFloat(region.unitHeight) * regionUnitHeight
            region.proximalBoundary = regionBoundary
            region.distalBoundary = regionBoundary + regionHeight
            regionBoundary += regionHeight
        }
        activeRegion = ladder.regions[0]
    }

    internal func getRegionUnitHeight(ladder: Ladder) -> CGFloat {
        var numRegionUnits = 0
        for region: Region in ladder.regions {
            numRegionUnits += region.unitHeight
        }
        // we need padding above and below, so...
        let padding = Int(ladderPaddingMultiplier * 2)
        numRegionUnits += padding
        return ladderViewHeight / CGFloat(numRegionUnits)
    }

//    func resetLadder() {
//        ladder = Ladder.defaultLadder()
//        activeRegion = ladder.regions[0]
//        cursorViewDelegate.cursorIsVisible = false
//        setupView()
//    }

    // MARK: - Touches

    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap(tap:) - LadderView", log: OSLog.touches, type: .info)
        let position = tap.location(in: self)
        let tapLocationInLadder = getLocationInLadder(position: position)
        if mode == .select {
            performMarkSelecting(tapLocationInLadder)
            return
        }
        if mode == .link {
            performMarkLinking(tapLocationInLadder)
            return
        }
        unhighlightAllMarks()
        if tapLocationInLadder.labelWasTapped {
            assert(tapLocationInLadder.region != nil, "Label tapped, but region is nil!")
            if let region = tapLocationInLadder.region {
                labelWasTapped(labelRegion: region)
                cursorViewDelegate.cursorIsVisible = false
                unattachAttachedMark()
            }
        }
        else if (tapLocationInLadder.regionWasTapped) {
            regionWasTapped(tapLocationInLadder: tapLocationInLadder, positionX: position.x)
        }
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter position: point to be processed
    func getLocationInLadder(position: CGPoint) -> LocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        var tappedRegionDivision: RegionDivision = .none
        var tappedAnchor: Anchor = .none
        for region in ladder.regions {
            if position.y > region.proximalBoundary && position.y < region.distalBoundary {
                tappedRegion = region
                tappedRegionDivision = getTappedRegionDivision(region: region, positionY: position.y)
            }
        }
        if let tappedRegion = tappedRegion {
            if position.x < leftMargin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(point: position, mark: mark, region: tappedRegion, accuracy: accuracy) {
                        tappedMark = mark
                        tappedAnchor = nearMarkPosition(point: position, mark: mark, region: tappedRegion)
                        break outerLoop
                    }
                }
            }
        }
        let location = LocationInLadder(region: tappedRegion, mark: tappedMark, ladder: ladder, regionSection: tappedRegionSection, regionDivision: tappedRegionDivision, markAnchor: tappedAnchor, unscaledPosition: position)
        P("location in ladder = " + location.debugDescription)
        return location
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


    private func labelWasTapped(labelRegion: Region) {
        if labelRegion.activated {
            labelRegion.activated = false
            activeRegion = nil
        }
        else {
            activeRegion = labelRegion
        }
    }

    private func regionWasTapped(tapLocationInLadder: LocationInLadder, positionX: CGFloat) {
        assert(tapLocationInLadder.region != nil, "Region tapped, but is nil!")
        if let tappedRegion = tapLocationInLadder.region {
            if !tappedRegion.activated {
                activeRegion = tappedRegion
            }
            if let mark = tapLocationInLadder.mark {
                markWasTapped(mark: mark, tapLocationInLadder: tapLocationInLadder)
            }
            else if cursorViewDelegate.cursorIsVisible {
                unhighlightAllMarks()
                cursorViewDelegate.cursorIsVisible = false
                unattachAttachedMark()
            }
            else { // make mark and attach cursor
                let mark = addMark(scaledViewPositionX: positionX)
                if let mark = mark {
                    undoablyAddMark(mark: mark, region: activeRegion)
                    unhighlightAllMarks()
                    mark.anchor = ladder.defaultAnchor(forMark: mark)
                    attachMark(mark)
                    cursorViewDelegate.setCursorHeight()
                    cursorViewDelegate.moveCursor(cursorViewPositionX: mark.segment.proximal.x)
                    cursorViewDelegate.cursorIsVisible = true
                }
            }
        }
    }

    private func markWasTapped(mark: Mark?, tapLocationInLadder: LocationInLadder) {
        if let mark = mark, let activeRegion = activeRegion {
            if mark.attached {
                attachMark(mark)
                // TODO: Consider using RegionDivision to position Anchor.  Tapping on cursor it makes sense to just toggle the anchor, but tapping on the mark itself it might be better to position anchor near where you tap.  On other hand, it might be easy to miss the mark division zone.  Also, if not all anchors are available (say the .middle anchor is missing), which anchor do you switch to?  Maybe default to toggleAnchor() if anchor not available.
                toggleAnchor(mark: mark)
                adjustCursor(mark: mark, region: activeRegion)
                cursorViewDelegate.cursorIsVisible = true
            }
            else { // mark wasn't already attached.
                unattachMarks()
                attachMark(mark)
                mark.anchor = ladder.defaultAnchor(forMark: mark)
                adjustCursor(mark: mark, region: activeRegion)
                cursorViewDelegate.cursorIsVisible = true
            }
        }
    }

    private func link(marksToLink marks: [Mark]) -> Mark? {
        // Should not be called unless two marks to link are in marks.
        guard marks.count == 2 else { return nil }
        guard let firstRegionIndex = ladder.getRegionIndex(ofMark: marks[0]) else {
            return nil
        }
        guard let secondRegionIndex = ladder.getRegionIndex(ofMark: marks[1]) else {
            return nil
        }
        let regionDifference = secondRegionIndex - firstRegionIndex
        // ignore same region for now.  Only allow diff of 2 regions
        if abs(regionDifference) == 2 {
            if regionDifference > 0 {
                activeRegion = ladder.getRegion(index: firstRegionIndex + 1)
                let segment = Segment(proximal: CGPoint(x: marks[0].segment.distal.x, y: 0), distal: CGPoint(x: marks[1].segment.proximal.x, y: 1.0))
                let mark = ladder.addMark(fromSegment: segment, inRegion: activeRegion)
                if let mark = mark {
                    undoablyAddMark(mark: mark, region: activeRegion)
                }
                mark?.highlight = .linked
                return mark
            }
            if regionDifference < 0 {
                activeRegion = ladder.getRegion(index: firstRegionIndex - 1)
                let segment = Segment(proximal: CGPoint(x: marks[1].segment.distal.x, y: 0), distal: CGPoint(x: marks[0].segment.proximal.x, y: 1.0))
                let mark = ladder.addMark(fromSegment: segment, inRegion: activeRegion)
                if let mark = mark {
                    undoablyAddMark(mark: mark, region: activeRegion)
                }
                mark?.highlight = .linked
                return mark
            }
        }
        return nil
    }

    private func linkTappedMark(_ mark: Mark) {
        if ladder.linkedMarks.count == 0 {
            ladder.linkedMarks.append(mark)
            mark.highlight = .linked
        }
        else if ladder.linkedMarks.count == 1 {
            // tap same mark, cancel linking
            if mark == ladder.linkedMarks[0] {
                ladder.linkedMarks.removeAll()
                mark.highlight = .none
            }
            else {
                // different mark tapped
                // what region is the mark in?
                let markRegionIndex = ladder.getRegionIndex(ofMark: mark)
                let firstMarkRegionIndex = ladder.getRegionIndex(ofMark: ladder.linkedMarks[0])
                os_log("markRegionIndex = %d, firstMarkRegionIndex = %d (-1 == nil)", log: OSLog.debugging, type: .info, markRegionIndex ?? -1, firstMarkRegionIndex ?? -1)
                // TODO: what about create mark with each tap?
                ladder.linkedMarks.append(mark)
                mark.highlight = .linked
                if let linkedMark = link(marksToLink: ladder.linkedMarks) {
                    ladder.linkedMarks.append(linkedMark)
                    linkedMark.highlight = .linked
                    groupNearbyMarks(mark: linkedMark)
                    addGroupedMiddleMarks(ofMark: linkedMark)
                }
            }
        }
        else if ladder.linkedMarks.count >= 2 {
            // start over
            ladder.setHighlightForAllMarks(highlight: .none)
            ladder.linkedMarks.removeAll()
        }
    }

    private func performMarkLinking(_ tapLocationInLadder: LocationInLadder) {
        if let mark = tapLocationInLadder.mark {
            linkTappedMark(mark)
        }
        else if let region = tapLocationInLadder.region {
            P("link tapped region")
            activeRegion = region
            if ladder.linkedMarks.count == 0 {
                P("no linked marks so far")
            }
            else if ladder.linkedMarks.count == 1 {
                // draw mark from end of previous linked mark
                let firstTappedMark = ladder.linkedMarks[0]
                if let firstTappedMarkRegionIndex = ladder.getRegionIndex(ofMark: firstTappedMark), let regionIndex = ladder.getIndex(ofRegion: region) {
                    let tapRegionPosition = translateToRegionPosition(scaledViewPosition: tapLocationInLadder.unscaledPosition, region: region)
                    if firstTappedMarkRegionIndex < regionIndex {
                        P("add mark and link to distal end of linked mark")
                        P("tapRegionPosition = \(tapRegionPosition)")
                        if let newMark = addMark(regionPositionX: firstTappedMark.segment.distal.x) {
                            newMark.segment.distal = tapRegionPosition
                            undoablyAddMark(mark: newMark, region: region)
                        }
                    }
                    else if firstTappedMarkRegionIndex > regionIndex {
                        P("add mark and link to proximal end of linked mark")
                    }
                    else { // mark in same region
                        P("add mark and link to linked mark in same region")
                    }
                    ladder.linkedMarks.removeAll()
                }
            }
        }
        setNeedsDisplay()
        return
    }

    private func performMarkSelecting(_ tapLocationInLadder: LocationInLadder) {
        if let mark = tapLocationInLadder.mark {
            // toggle mark selection
            mark.selected.toggle()
            mark.highlight = mark.selected ? .selected : .none
            if mark.selected {
                ladder.selectedMarks.append(mark)
            }
            else {
                if let index = ladder.selectedMarks.firstIndex(of: mark) {
                    ladder.selectedMarks.remove(at: index)
                }
            }
            setNeedsDisplay()
        }
    }

    private func unattachMarks() {
        ladder.unattachAllMarks()
    }

    private func adjustCursor(mark: Mark, region: Region) {
        let anchorPosition = mark.getAnchorPosition()
        let scaledAnchorPositionY = translateToScaledViewPosition(regionPosition: anchorPosition, region: region).y
        cursorViewDelegate.moveCursor(cursorViewPositionX: anchorPosition.x)
        cursorViewDelegate.setCursorHeight(anchorPositionY: scaledAnchorPositionY)
    }

    /// - Parameters:
    ///   - position: position of, say a tap on the screen
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    ///   - accuracy: how close does it have to be?
    func nearMark(point: CGPoint, mark: Mark, region: Region, accuracy: CGFloat) -> Bool {
        let scaledViewMarkSegment = translateToScaledViewSegment(regionSegment: mark.segment, region: region)
        let distance = Common.distanceSegmentToPoint(segment: scaledViewMarkSegment, point: point)
        return distance < accuracy
    }

    func positionIsNearMark(position: CGPoint) -> Bool {
        return getLocationInLadder(position: position).markWasTapped
    }

    /// Determine which anchor a point is closest to.
    /// - Parameters:
    ///   - point: a point in ladder view coordinates
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    func nearMarkPosition(point: CGPoint, mark: Mark, region: Region) -> Anchor {
        // Use region coordinates
        let regionPoint = translateToRegionPosition(scaledViewPosition: point, region: region)
        let proximalDistance = Common.distanceBetweenPoints(mark.segment.proximal, regionPoint)
        let middleDistance = Common.distanceBetweenPoints(mark.midpoint(), regionPoint)
        let distalDistance = Common.distanceBetweenPoints(mark.segment.distal, regionPoint)
        let minimumDistance = min(proximalDistance, middleDistance, distalDistance)
        if minimumDistance == proximalDistance {
            return .proximal
        }
        else if minimumDistance == middleDistance {
            return .middle
        }
        else if minimumDistance == distalDistance {
            return .distal
        }
        else {
            return .none
        }
    }

    func addMark(scaledViewPositionX: CGFloat) -> Mark? {
        return addMark(regionPositionX: translateToRegionPositionX(scaledViewPositionX: scaledViewPositionX))
    }

    func addMark(regionPositionX: CGFloat) -> Mark? {
        if let mark = ladder.addMark(at: regionPositionX, inRegion: activeRegion) {
            mark.highlight = .attached
            mark.attached = true
            return mark
        }
        return nil
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

    // FIXME: When cursor goes from hidden to visible, mark anchor should reset to middle of mark.
    private func toggleAnchor(mark: Mark?) {
        guard let mark = mark else { return }
        let availableAnchors = ladder.availableAnchors(forMark: mark)
        guard availableAnchors.count > 0 else { return }
        let currentAnchor = mark.anchor
        if availableAnchors.contains(currentAnchor) {
            if availableAnchors.count == 1 {
                return // can't change anchor
            }
            // ok to ! this, since we alreay made sure currentAnchor in availableAnchors
            let currentAnchorIndex = availableAnchors.firstIndex(of: currentAnchor)!
            // last anchor, scroll around
            if currentAnchorIndex == availableAnchors.count - 1 {
                mark.anchor = availableAnchors[0]
            }
            else {
                if let newAnchor = Anchor(rawValue: mark.anchor.rawValue + 1) {
                    if newAnchor == .none {
                        mark.anchor = availableAnchors[0]
                    }
                    else {
                        mark.anchor = newAnchor
                    }
                }
                else {
                    mark.anchor = availableAnchors[0]
                }
            }
        }
        else {
            mark.anchor = availableAnchors[0]
        }
    }

    func setAttachedMarkAndGroupedMarksHighlights() {
        if let attachedMark = attachedMark {
            let groupedMarkIds = attachedMark.groupedMarkIds
            // Note that the order below is important.  An attached mark can be in its own groupedMarks.  But we always want the attached mark to have an .attached highlight.
            ladder.setHighlightForMarkIdGroup(highlight: .grouped, markIdGroup: groupedMarkIds)
            attachedMark.highlight = .attached
        }
    }

    func attachMark(_ mark: Mark?) {
        mark?.attached = true
        attachedMark = mark
        setAttachedMarkAndGroupedMarksHighlights()
    }


    @objc func doubleTap(tap: UITapGestureRecognizer) {
        os_log("doubleTap(tap:) - LadderView", log: OSLog.touches, type: .info)
        if deleteMark(position: tap.location(in: self), cursorViewDelegate: cursorViewDelegate) {
            setNeedsDisplay()
        }
    }

    /// Deletes mark if there is one at position.  Returns true if position corresponded to a mark.
    /// - Parameter position: position of potential mark
    func deleteMark(position: CGPoint, cursorViewDelegate: CursorViewDelegate) -> Bool {
        os_log("deleteMark(position:cursofViewDelegate:) - LadderView", log: OSLog.debugging, type: .debug)
        let tapLocationInLadder = getLocationInLadder(position: position)
        activeRegion = tapLocationInLadder.region
        if tapLocationInLadder.markWasTapped {
            if let mark = tapLocationInLadder.mark {
                let region = tapLocationInLadder.region
                undoablyDeleteMark(mark: mark, region: region)
                return true
            }
        } else {
            print("no mark tapped")

            // FIXME: refactor
            let region = tapLocationInLadder.region
            let scaledPositionX = translateToRegionPositionX(scaledViewPositionX: tapLocationInLadder.unscaledPosition.x)
            if let mark = ladder.addMark(at: scaledPositionX, inRegion: region) {
                undoablyAddMark(mark: mark, region: region)
                attachedMark = mark
                mark.attached = true
                mark.highlight = .attached
                cursorViewDelegate.moveCursor(cursorViewPositionX: scaledPositionX)
                cursorViewDelegate.cursorIsVisible = true
                cursorViewDelegate.setCursorHeight()
                cursorViewDelegate.refresh()
            }
        }
        return true
    }

    // See https://stackoverflow.com/questions/36491789/using-nsundomanager-how-to-register-undos-using-swift-closures/36492619#36492619
    private func undoablyDeleteMark(mark: Mark, region: Region?) {
        os_log("undoablyDeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.redoablyUndeleteMark(mark: mark, region: region)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        deleteMark(mark: mark, region: region)
    }

    private func redoablyUndeleteMark(mark: Mark, region: Region?) {
        os_log("redoablyUndeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark, region: region)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        undeleteMark(mark: mark, region: region)
    }

    private func undoablyAddMark(mark: Mark, region: Region?) {
        os_log("undoablyAddMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark, region: region)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        // Note no call here because calling function needs to actually add the mark.
    }

    private func deleteMark(mark: Mark, region: Region?) {
        os_log("deleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        mark.attached = false
        ladder.deleteMark(mark, inRegion: region)
        cursorViewDelegate.cursorIsVisible = false
        cursorViewDelegate.refresh()
    }

    private func undeleteMark(mark: Mark, region: Region?) {
        os_log("undeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        if let region = region {
            ladder.addMark(mark, toRegion: region)
            mark.attached = false
            mark.highlight = .none
        }
        cursorViewDelegate.cursorIsVisible = false
        cursorViewDelegate.refresh()
    }

    private func deleteMark(_ mark: Mark?) {
        os_log("deleteMark(_:) - LadderView", log: OSLog.debugging, type: .debug)
        if let mark = mark {
            undoablyDeleteMark(mark: mark, region: activeRegion)
        }
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        if isZoning {
            print("zone drag")
            dragZone(pan: pan)
            return
        }
        let position = pan.location(in: self)
        let state = pan.state
        let locationInLadder = getLocationInLadder(position: position)
        if state == .began {
            currentDocument?.undoManager?.beginUndoGrouping()
            // Activate region and get regions proximal and distal.
            if let region = locationInLadder.region {
                regionOfDragOrigin = region
                regionProximalToDragOrigin = ladder.getRegionBefore(region: region)
                regionDistalToDragOrigin = ladder.getRegionAfter(region: region)
                activeRegion = region
            }
            if let regionOfDragOrigin = regionOfDragOrigin {
                // We're about to move the attached mark.
                if let mark = locationInLadder.mark, mark.attached {
                    movingMark = mark
                    setAttachedMarkAndGroupedMarksHighlights()
                    // need to move it nowhere, to let undo work
                    if let anchorPosition = getMarkScaledAnchorPosition(mark) {
                        moveMark(mark: mark, scaledViewPosition: anchorPosition)
                    }
                }
                else {  // We need to make a new mark.
                    cursorViewDelegate.cursorIsVisible = false
                    unattachAttachedMark()
                    unhighlightAllMarks()
                    // Get the third of region for endpoint of new mark.
                    dragOriginDivision = locationInLadder.regionDivision
                    switch dragOriginDivision {
                    case .proximal:
                        // FIXME: undoablyAddMark()???
                        dragCreatedMark = addMark(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0
                        dragCreatedMark?.segment.distal.y = 0.5
                    case .middle:
                        dragCreatedMark = addMark(scaledViewPositionX: position.x)
                        // TODO: REFACTOR
                        dragCreatedMark?.segment.proximal.y = (position.y - regionOfDragOrigin.proximalBoundary) / (regionOfDragOrigin.distalBoundary - regionOfDragOrigin.proximalBoundary)
                        dragCreatedMark?.segment.distal.y = 0.75
                    case .distal:
                        dragCreatedMark = addMark(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0.5
                        dragCreatedMark?.segment.distal.y = 1
                    case .none:
                        assert(false, "Making a mark with a .none regionDivision!")
                    }
                    if let dragCreatedMark = dragCreatedMark {
                        undoablyAddMark(mark: dragCreatedMark, region: activeRegion)
                    }
                    dragCreatedMark?.highlight = .attached
                }
            }
        }
        if state == .changed {
            if let mark = movingMark {
                moveMark(mark: mark, scaledViewPosition: position)
                highlightNearbyMarks(movingMark)
            }
            else if regionOfDragOrigin == locationInLadder.region, let regionOfDragOrigin = regionOfDragOrigin {
                switch dragOriginDivision {
                case .proximal:
                    dragCreatedMark?.segment.distal = translateToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                case .distal:
                    dragCreatedMark?.segment.proximal = translateToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                case .middle:
                    dragCreatedMark?.segment.distal = translateToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                default:
                    break
                }
                highlightNearbyMarks(dragCreatedMark)
            }
        }
        if state == .ended {
            currentDocument?.undoManager?.endUndoGrouping()
            if let movingMark = movingMark {
                swapEndsIfNeeded(mark: movingMark)
                groupNearbyMarks(mark: movingMark)
                addGroupedMiddleMarks(ofMark: movingMark)
                assessBlockAndImpulseOrigin(mark: movingMark)
            }
            else if let dragCreatedMark = dragCreatedMark {
                if dragCreatedMark.height < lowerLimitMarkHeight && dragCreatedMark.width < lowerLimitMarkWidth {
                    deleteMark(dragCreatedMark)
                }
                else {
                    swapEndsIfNeeded(mark: dragCreatedMark)
                    groupNearbyMarks(mark: dragCreatedMark)
                    addGroupedMiddleMarks(ofMark: dragCreatedMark)
                    assessBlockAndImpulseOrigin(mark: dragCreatedMark)
                }
            }
            if !cursorViewDelegate.cursorIsVisible {
                unhighlightAllMarks()
            }
            movingMark?.attached = false
            dragCreatedMark?.attached = false
            movingMark = nil
            dragCreatedMark = nil
            regionOfDragOrigin = nil
            regionProximalToDragOrigin = nil
            regionDistalToDragOrigin = nil
            dragOriginDivision = .none
        }
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    func dragZone(pan: UIPanGestureRecognizer) {
        // drag zone
    }

    private func swapEndsIfNeeded(mark: Mark) {
        let proximalY = mark.segment.proximal.y
        let distalY = mark.segment.distal.y
        if proximalY > distalY {
            P("swapping ends")
            mark.swapEnds()
        }
    }

    // TODO: expand on this logic.  Reset block and impulseOrigin to .none as necessary.
    // Also, consider adding arrows to marks indicating direction of flow (arrow will be added
    // to whichever end of the mark is later in time.  Opposite of impluse origin.
    func assessBlockAndImpulseOrigin(mark: Mark?) {
        if let mark = mark {
            mark.block = .none
            mark.impulseOrigin = .none
            if mark.segment.proximal.y != 0 && mark.segment.proximal.x >= mark.segment.distal.x {
                mark.block = .proximal
            }
            if mark.segment.distal.y != 1.0 && mark.segment.distal.x > mark.segment.proximal.x {
                mark.block = .distal
            }
            if mark.groupedMarkIds.proximal.count == 0 {
                if mark.segment.proximal.x <= mark.segment.distal.x {
                    mark.impulseOrigin = .proximal
                }
            }
            if mark.groupedMarkIds.distal.count == 0 {
                if mark.segment.distal.x < mark.segment.proximal.x {
                    mark.impulseOrigin = .distal
                }
            }
        }
    }

    private func highlightNearbyMarks(_ mark: Mark?) {
        guard let mark = mark else { return }
        var nearbyDistance: CGFloat = 10
        nearbyDistance = nearbyDistance / scale
        let nearbyMarkIds = getNearbyMarkIds(mark: mark, nearbyDistance: nearbyDistance)
//        let nearbyMarks = getNearbyMarks(mark: mark, nearbyDistance: nearbyDistance)
        ladder.setHighlightForAllMarks(highlight: .none)
        ladder.setHighlightForMarkIdGroup(highlight: .grouped, markIdGroup: nearbyMarkIds)
//        nearbyMarks.highlight(highlight: .grouped)
        setAttachedMarkAndGroupedMarksHighlights()
    }

    func getNearbyMarkIds(mark: Mark, nearbyDistance: CGFloat) -> MarkIdGroup {
        guard let activeRegion = activeRegion else { return MarkIdGroup() }
        var proximalMarkIds = MarkIdSet()
        var distalMarkIds = MarkIdSet()
        var middleMarkIds = MarkIdSet()
        if let proximalRegion = ladder.getRegionBefore(region: activeRegion) {
            for neighboringMark in proximalRegion.marks {
                if assessCloseness(ofMark: mark, inRegion: activeRegion, toNeighboringMark: neighboringMark, inNeighboringRegion: proximalRegion, usingNearbyDistance: nearbyDistance) {
                    proximalMarkIds.insert(neighboringMark.id)
                }
            }
        }
        if let distalRegion = ladder.getRegionAfter(region: activeRegion) {
            for neighboringMark in distalRegion.marks {
                if assessCloseness(ofMark: mark, inRegion: activeRegion, toNeighboringMark: neighboringMark, inNeighboringRegion: distalRegion, usingNearbyDistance: nearbyDistance) {
                    distalMarkIds.insert(neighboringMark.id)
                }
            }
        }
        // check in the same region ("middle region", same as activeRegion)
        for neighboringMark in activeRegion.marks {
            if assessCloseness(ofMark: mark, inRegion: activeRegion, toNeighboringMark: neighboringMark, inNeighboringRegion: activeRegion, usingNearbyDistance: nearbyDistance) {
                middleMarkIds.insert(neighboringMark.id)
                P("found middle mark")
            }
        }
        return MarkIdGroup(proximal: proximalMarkIds, middle: middleMarkIds, distal: distalMarkIds)
    }

    private func assessCloseness(ofMark mark: Mark, inRegion region: Region, toNeighboringMark neighboringMark: Mark, inNeighboringRegion neighboringRegion: Region, usingNearbyDistance nearbyDistance: CGFloat) -> Bool {
        guard mark != neighboringMark else { return false }
        var isClose = false
        // To get minimum distance between two line segments, must get minimum distances between each segment and each endpoint of the other segment, and take minimum of all those.
        let ladderViewPositionNeighboringMarkSegment = translateToScaledViewSegment(regionSegment: neighboringMark.segment, region: neighboringRegion)
        let ladderViewPositionMarkProximal = translateToScaledViewPosition(regionPosition: mark.segment.proximal, region: region)
        let ladderViewPositionMarkDistal = translateToScaledViewPosition(regionPosition: mark.segment.distal, region: region)
        let distanceToNeighboringMarkSegmentProximal = Common.distanceSegmentToPoint(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkProximal)
        let distanceToNeighboringMarkSegmentDistal = Common.distanceSegmentToPoint(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkDistal)

        let ladderViewPositionMarkSegment = translateToScaledViewSegment(regionSegment: mark.segment, region: region)
        let ladderViewPositionNeighboringMarkProximal = translateToScaledViewPosition(regionPosition: neighboringMark.segment.proximal, region: neighboringRegion)
        let ladderViewPositionNeighboringMarkDistal = translateToScaledViewPosition(regionPosition: neighboringMark.segment.distal, region: neighboringRegion)
        let distanceToMarkSegmentProximal = Common.distanceSegmentToPoint(segment: ladderViewPositionMarkSegment, point: ladderViewPositionNeighboringMarkProximal)
        let distanceToMarkSegmentDistal = Common.distanceSegmentToPoint(segment: ladderViewPositionMarkSegment, point: ladderViewPositionNeighboringMarkDistal)

        if distanceToNeighboringMarkSegmentProximal < nearbyDistance
            || distanceToNeighboringMarkSegmentDistal < nearbyDistance
            || distanceToMarkSegmentProximal < nearbyDistance
            || distanceToMarkSegmentDistal < nearbyDistance {
            isClose = true
        }
        return isClose
    }

    func moveAttachedMark(position: CGPoint) {
        if let attachedMark = attachedMark {
            moveMark(mark: attachedMark, scaledViewPosition: position)
        }
    }

    func fixBoundsOfAttachedMark() {
        if let attachedMark = attachedMark {
            fixBoundsOfMark(attachedMark)
        }
    }

    private func fixBoundsOfMark(_ mark: Mark) {
        mark.segment = mark.segment.normalized()
    }

    private func undoablyMoveMark(movement: Movement, mark: Mark, regionPosition: CGPoint) {
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: {target in
            target.undoablyMoveMark(movement: movement, mark: mark, regionPosition: regionPosition)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        moveMark(movement: movement, mark: mark, regionPosition: regionPosition)
    }

    private func moveMark(movement: Movement, mark: Mark, regionPosition: CGPoint) {
        if movement == .horizontal {
            switch mark.anchor {
            case .proximal:
                mark.segment.proximal.x = regionPosition.x
            case .middle:
                // Determine halfway point between proximal and distal.
                let differenceX = (mark.segment.proximal.x - mark.segment.distal.x) / 2
                mark.segment.proximal.x = regionPosition.x + differenceX
                mark.segment.distal.x = regionPosition.x - differenceX
            case .distal:
                mark.segment.distal.x = regionPosition.x
            case .none:
                break
            }
        }
        else if movement == .omnidirectional {
            switch mark.anchor {
            case .proximal:
                mark.segment.proximal = regionPosition
            case .middle:
                // Determine halfway point between proximal and distal.
                let differenceX = (mark.segment.proximal.x - mark.segment.distal.x) / 2
                let differenceY = (mark.segment.proximal.y - mark.segment.distal.y) / 2
                mark.segment.proximal.x = regionPosition.x + differenceX
                mark.segment.distal.x = regionPosition.x - differenceX
                mark.segment.proximal.y = regionPosition.y + differenceY
                mark.segment.distal.y = regionPosition.y - differenceY
            case .distal:
                mark.segment.distal = regionPosition
            case .none:
                break
            }
        }
        moveGroupedMarks(forMark: mark)
        if let activeRegion = activeRegion {
            adjustCursor(mark: mark, region: activeRegion)
            cursorViewDelegate.refresh()
        }
    }

    private func moveGroupedMarks(forMark mark: Mark) {
        os_log("moveGroupedMarked(forMark:)", log: .action, type: .info)
        // adjust ends of mark segment.
        for proximalMark in ladder.getMarkSet(fromMarkIdSet: mark.groupedMarkIds.proximal) {
            proximalMark.segment.distal.x = mark.segment.proximal.x
        }
        for distalMark in ladder.getMarkSet(fromMarkIdSet: mark.groupedMarkIds.distal) {
            distalMark.segment.proximal.x = mark.segment.distal.x
        }
        for middleMark in ladder.getMarkSet(fromMarkIdSet:mark.groupedMarkIds.middle) {
            if mark == middleMark { break }
            let distanceToProximal = Common.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.proximal)
            let distanceToDistal = Common.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.distal)
            if distanceToProximal < distanceToDistal {
                let x = Common.getX(onSegment: mark.segment, fromY: middleMark.segment.proximal.y)
                if let x = x {
                    middleMark.segment.proximal.x = x
                }
            }
            else {
                    let x = Common.getX(onSegment: mark.segment, fromY: middleMark.segment.distal.y)
                    if let x = x {
                        middleMark.segment.distal.x = x
                }
            }
        }
    }

    func moveMark(mark: Mark, scaledViewPosition: CGPoint) {
        guard let activeRegion = activeRegion else { return }
        let regionPosition = translateToRegionPosition(scaledViewPosition: scaledViewPosition, region: activeRegion)
        if cursorViewDelegate.cursorIsVisible {
            undoablyMoveMark(movement: cursorViewDelegate.cursorMovement(), mark: mark, regionPosition: regionPosition)
        }
        highlightNearbyMarks(mark)
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        self.becomeFirstResponder()
        let position = press.location(in: self)
        let locationInLadder = getLocationInLadder(position: position)
        P("long press at \(locationInLadder) ")
    }

    func setPressedMark(position: CGPoint) {
        let locationInLadder = getLocationInLadder(position: position)
        // Need to activate region that was pressed.
        if let region = locationInLadder.region {
            activeRegion = region
        }
        if let mark = locationInLadder.mark {
            pressedMark = mark
        }
    }

    func setPressedMarkStyle(style: Mark.LineStyle) {
        if let pressedMark = pressedMark {
            pressedMark.lineStyle = style
            if mode == .select {
                for mark in ladder.selectedMarks {
                    mark.lineStyle = style
                }
            }
        }
    }

    @objc func setSolid() {
        setPressedMarkStyle(style: .solid)
        nullifyPressedMark()
        setNeedsDisplay()
    }

    @objc func setDashed() {
        setPressedMarkStyle(style: .dashed)
        nullifyPressedMark()
        setNeedsDisplay()
    }

    @objc func setDotted() {
        setPressedMarkStyle(style: .dotted)
        nullifyPressedMark()
        setNeedsDisplay()
    }

    func nullifyPressedMark() {
        pressedMark = nil
    }

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            draw(rect: rect, context: context)
        }
    }

    func draw(rect: CGRect, context: CGContext) {
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(1)
        let ladderWidth: CGFloat = rect.width
        for (index, region) in ladder.regions.enumerated() {
            let regionRect = CGRect(x: leftMargin, y: region.proximalBoundary, width: ladderWidth, height: region.distalBoundary - region.proximalBoundary)
            let lastRegion = index == ladder.regions.count - 1
            drawRegion(rect: regionRect, context: context, region: region, offset: offsetX, scale: scale, lastRegion: lastRegion)
        }
        if isZoning {
            drawZone(context: context)
        }
        if ladderIsLocked {
            showLockLadderWarning(rect: rect)
        }
        if !marksAreVisible {
            showMarksAreHiddenWarning(rect: rect)
        }
    }

    fileprivate func drawZone(context: CGContext) {
        guard let zone = ladder.zone else { return }
        let start = translateToRegionPositionX(scaledViewPositionX: zone.start)
        let end = translateToRegionPositionX(scaledViewPositionX: zone.end)
        for region in zone.regions {
            let zoneRect = CGRect(x: start, y: region.proximalBoundary, width: end - start, height: region.distalBoundary - region.proximalBoundary)
            context.addRect(zoneRect)
            context.setFillColor(zoneColor.cgColor)
            context.setAlpha(0.2)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1.0)
    }


    fileprivate func drawLabel(rect: CGRect, region: Region, context: CGContext) {
        let stringRect = CGRect(x: 0, y: rect.origin.y, width: rect.origin.x, height: rect.height)
        // TODO: refactor out constant attributes.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 18.0),
            .foregroundColor: region.activated ? red : blue
        ]
        let text = region.name
        let labelText = NSAttributedString(string: text, attributes: attributes)
        let size: CGSize = text.size(withAttributes: attributes)
        let labelRect = CGRect(x: 0, y: rect.origin.y + (rect.height - size.height) / 2, width: rect.origin.x, height: size.height)
        context.addRect(stringRect)
        context.setStrokeColor(red.cgColor)
        context.setFillColor(UIColor.secondarySystemBackground.cgColor)
        context.setLineWidth(1)
        context.drawPath(using: .fillStroke)
        labelText.draw(in: labelRect)
    }

    fileprivate func drawRegionArea(context: CGContext, rect: CGRect, region: Region) {
        // Draw top ladder line
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y))
        context.strokePath()

        // Highlight region if selected
        if region.activated {
            let regionRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)
            context.setAlpha(0.2)
            context.addRect(regionRect)
            context.setFillColor(red.cgColor)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1)
    }

    fileprivate func drawMark(mark: Mark, region: Region, context: CGContext) {
        // Don't draw outside bounds of region, fix out of bounds segments at end of mark movement.
        let normalizedSegment = mark.segment.normalized()
        let segment = translateToScaledViewSegment(regionSegment: normalizedSegment, region: region)
        // Don't bother drawing marks in margin.
        if segment.proximal.x <= leftMargin && segment.distal.x <= leftMargin {
            return
        }
        // The two endpoints of the mark to be drawn
        var p1 = CGPoint()
        var p2 = CGPoint()
        if segment.proximal.x > leftMargin && segment.distal.x > leftMargin {
            p1 = segment.proximal
            p2 = segment.distal
        }
        else if segment.proximal.x < leftMargin {
            p1 = getTruncatedPosition(segment: segment) ?? segment.proximal
            p2 = segment.distal
        }
        else {
            p1 = getTruncatedPosition(segment: segment) ?? segment.distal
            p2 = segment.proximal
        }
        context.setStrokeColor(getMarkColor(mark: mark))
        context.setFillColor(getMarkColor(mark: mark))
        context.setLineWidth(lineWidth)
//        context.setLineWidth(getMarkLineWidth(mark))
        context.move(to: p1)
        context.addLine(to: p2)
        // Draw dashed line
        if mark.lineStyle == .dashed {
            let dashes: [CGFloat] = [5, 5]
            context.setLineDash(phase: 0, lengths: dashes)
        }
        else if mark.lineStyle == .dotted {
            let dots: [CGFloat] = [2, 2]
            context.setLineDash(phase: 0, lengths: dots)
        }
        else { // draw solid line
            context.setLineDash(phase: 0, lengths: [])
        }
        context.strokePath()
        context.setLineDash(phase: 0, lengths: [])

        drawBlock(context: context, mark: mark, segment: segment)
        drawImpulseOrigin(context: context, mark: mark, segment: segment)
        // FIXME: this is just a sample pivot point.  Pivots need to be determined by ladder.
        drawPivots(forMark: mark, segment: Segment(proximal: p1, distal: p2), context: context)
        drawMarkText(forMark: mark, segment: segment, context: context)

        context.setStrokeColor(UIColor.label.cgColor)
    }

    fileprivate func drawIntervals(region: Region, context: CGContext) {
        guard showIntervals else { return }
        guard let calibration = calibration, calibration.isCalibrated else { return }
        let marks = region.marks
        let intervals = Interval.createIntervals(marks: marks)
        for interval in intervals {
            if let firstProximalX = interval.proximalBoundary?.first, let secondProximalX = interval.proximalBoundary?.second {
                let scaledFirstProximalX = translateToScaledViewPositionX(regionPositionX: firstProximalX)
                let scaledSecondProximalX = translateToScaledViewPositionX(regionPositionX: secondProximalX)
                let halfwayPosition = (scaledFirstProximalX + scaledSecondProximalX) / 2.0
                let value = lround(Double(cursorViewDelegate.intervalMeasurement(value: interval.proximalValue ?? 0)))
                let text = "\(value)"
                var origin = CGPoint(x: halfwayPosition, y: region.proximalBoundary)
                var attributes = [NSAttributedString.Key: Any]()
                let textFont = UIFont(name: "Helvetica Neue Medium", size: 14.0) ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
                let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                // FIXME: foreground color?  Crashes app???
                attributes = [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                ]
                let size = text.size(withAttributes: attributes)
                // Center the origin.
                origin = CGPoint(x: origin.x - size.width / 2, y: origin.y)
                let textRect = CGRect(origin: origin, size: size)
                text.draw(in: textRect, withAttributes: attributes)
                context.strokePath()
            }
            if let firstDistalX = interval.distalBoundary?.first, let secondDistalX = interval.distalBoundary?.second {
                let scaledFirstDistalX = translateToScaledViewPositionX(regionPositionX: firstDistalX)
                let scaledSecondDistalX = translateToScaledViewPositionX(regionPositionX: secondDistalX)
                let halfwayPosition = (scaledFirstDistalX + scaledSecondDistalX) / 2.0
                let value = lround(Double(cursorViewDelegate.intervalMeasurement(value: interval.distalValue ?? 0)))
                let text = "\(value)"
                var origin = CGPoint(x: halfwayPosition, y: region.distalBoundary)
                var attributes = [NSAttributedString.Key: Any]()
                let textFont = UIFont(name: "Helvetica Neue Medium", size: 14.0) ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
                let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
                // FIXME: foreground color?  Crashes app???
                attributes = [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.paragraphStyle: paragraphStyle,
                ]
                let size = text.size(withAttributes: attributes)
                // Center the origin.
                origin = CGPoint(x: origin.x - size.width / 2, y: origin.y - size.height)
                let textRect = CGRect(origin: origin, size: size)
                text.draw(in: textRect, withAttributes: attributes)
                context.strokePath()
            }
        }

    }

    func showLockLadderWarning(rect: CGRect) {
        let text = L("LADDER LOCK")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0),
            .foregroundColor: UIColor.white, .backgroundColor: UIColor.systemRed,

        ]
        let lockRect = CGRect(x: rect.origin.x + 5, y: rect.origin.y + 5, width: rect.size.width, height: rect.size.height)
        text.draw(in: lockRect, withAttributes: attributes)
    }


    func showMarksAreHiddenWarning(rect: CGRect) {
        let text = L("MARKS ARE HIDDEN")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0),
            .foregroundColor: UIColor.white, .backgroundColor: UIColor.systemRed,

        ]
        let size = text.size(withAttributes: attributes)
        let hiddenMarksRect = CGRect(x: rect.size.width - size.width - 5, y: rect.origin.y + 5, width: rect.size.width, height: rect.size.height)
        text.draw(in: hiddenMarksRect, withAttributes: attributes)
    }

    func getTruncatedPosition(segment: Segment) -> CGPoint? {
        let intersection = Common.getIntersection(ofLineFrom: CGPoint(x: leftMargin, y: 0), to: CGPoint(x: leftMargin, y: ladderViewHeight), withLineFrom: segment.proximal, to: segment.distal)
        return intersection
    }

    func drawFilledCircle(context: CGContext, position: CGPoint, radius: CGFloat) {
        let rectangle = CGRect(x: position.x, y: position.y, width: radius, height: radius)
        context.addEllipse(in: rectangle)
        context.drawPath(using: .fillStroke)
    }

    func drawPivots(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showPivots else { return }
        // We only show pivots when cursor is attached.
        guard mark.attached else { return }
        let pivots = ladder.pivotPoints(forMark: mark)
        guard pivots.count > 0 else { return }
        var position: CGPoint = CGPoint.zero
        for pivot in pivots {
            switch pivot {
            case .proximal:
                position = segment.proximal
            case .distal:
                position = segment.distal
            default:
                assert(false, "pivot != .proximal or .distal!")
            }
            if (position.x > leftMargin) {
                drawPivot(context: context, position: position)
            }
        }
    }

    func drawMarkText(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard cursorViewDelegate.isCalibrated(), showMarkText, mark.showText, mark.text.count > 0 else { return }
        let value = lround(Double(cursorViewDelegate.markMeasurement(segment: segment)))
        let text = "\(value)"
        var origin = Common.getSegmentMidpoint(segment)
        var attributes = [NSAttributedString.Key: Any]()
        let textFont = UIFont(name: "Helvetica Neue Medium", size: 14.0) ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        // FIXME: foreground color?  Crashes app???
        attributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
        ]
        let size = text.size(withAttributes: attributes)
        // Center the origin.
        origin = CGPoint(x: origin.x + 10, y: origin.y - size.height / 2)
        let textRect = CGRect(origin: origin, size: size)
        text.draw(in: textRect, withAttributes: attributes)
        context.strokePath()

    }

    func drawPivot(context: CGContext, position: CGPoint) {
        let radius: CGFloat = 5.0
        drawX(context: context, position: position, radius: radius)
    }

    private func drawX(context: CGContext, position: CGPoint, radius: CGFloat) {
        let x = position.x
        let y = position.y
        context.move(to: CGPoint(x: x - radius, y: y - radius))
        context.addLine(to: CGPoint(x: x + radius, y: y + radius))
        context.move(to: CGPoint(x: x + radius, y: y - radius))
        context.addLine(to: CGPoint(x: x - radius, y: y + radius))
        context.strokePath()
    }

    func drawBlock(context: CGContext, mark: Mark, segment: Segment) {
        guard showBlock else { return }
        let blockLength: CGFloat = 20
        let blockSeparation: CGFloat = 5
        switch mark.block {
        case .none:
            return
        case .distal:
            context.move(to: CGPoint(x: segment.distal.x - blockLength / 2, y: segment.distal.y))
            context.addLine(to: CGPoint(x: segment.distal.x + blockLength / 2, y: segment.distal.y))
            context.move(to: CGPoint(x: segment.distal.x - blockLength / 2, y: segment.distal.y + blockSeparation))
            context.addLine(to: CGPoint(x: segment.distal.x + blockLength / 2, y: segment.distal.y + blockSeparation))
        case .proximal:
            context.move(to: CGPoint(x: segment.proximal.x - blockLength / 2, y: segment.proximal.y))
            context.addLine(to: CGPoint(x: segment.proximal.x + blockLength / 2, y: segment.proximal.y))
            context.move(to: CGPoint(x: segment.proximal.x - blockLength / 2, y: segment.proximal.y - blockSeparation))
            context.addLine(to: CGPoint(x: segment.proximal.x + blockLength / 2, y: segment.proximal.y - blockSeparation))
        }
        context.strokePath()
    }

    func drawImpulseOrigin(context: CGContext, mark: Mark, segment: Segment) {
        guard showImpulseOrigin else { return }
        let separation: CGFloat = 10
        let radius: CGFloat = 5
        switch mark.impulseOrigin {
        case .none:
            return
        case .distal:
            drawFilledCircle(context: context, position: CGPoint(x: segment.distal.x - radius / 2, y: segment.distal.y + separation - radius), radius: radius)
        case .proximal:
            drawFilledCircle(context: context, position: CGPoint(x: segment.proximal.x - radius / 2, y: segment.proximal.y - separation), radius: radius)
        }
    }

    private func getMarkLineWidth(_ mark: Mark) -> CGFloat {
        return markLineWidth
    }

    private func getMarkColor(mark: Mark) -> CGColor {
        switch mark.highlight {
        case .grouped:
            return groupedColor.cgColor
        case .attached:
            return attachedColor.cgColor
        case .selected:
            return selectedColor.cgColor
        case .linked:
            return linkColor.cgColor
        case .none:
            return unhighlightedColor.cgColor
        }
    }

    fileprivate func drawMarks(region: Region, context: CGContext,  rect: CGRect) {
        // Draw marks
        for mark: Mark in region.marks {
            drawMark(mark: mark, region: region, context: context)
        }
        drawIntervals(region: region, context: context)
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
        if ladder.marksAreVisible {
            drawMarks(region: region, context: context, rect: rect)
        }
        drawBottomLine(context: context, lastRegion: lastRegion, rect: rect)
    }

    func activateRegion(region: Region?) {
        guard let region = region else { return }
        inactivateRegions()
        region.activated = true
    }

    func inactivateRegions() {
        for region in ladder.regions {
            region.activated = false
        }
    }

    func resetSize() {
        os_log("resetSize() - LadderView", log: .action, type: .info)
        ladderViewHeight = self.frame.height
        initializeRegions()
        cursorViewDelegate.setCursorHeight()

    }

    func setCaliperMaxY(_ maxY: CGFloat) {
        cursorViewDelegate.setCaliperMaxY(maxY)
    }

    @objc func deletePressedMark() {
        os_log("deletePressedMark() - LadderView", log: OSLog.debugging, type: .debug)
        if let pressedMark = pressedMark {
            undoablyDeleteMark(mark: pressedMark, region: activeRegion)
            ladder.setHighlightForAllMarks(highlight: .none)
        }
        cursorViewDelegate.cursorIsVisible = false
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func deleteAllInRegion() {
        os_log("deleteAllInRegion() - LadderView", log: OSLog.debugging, type: .debug)
        if let activeRegion = activeRegion {
            undoManager?.beginUndoGrouping()
            for mark in activeRegion.marks {
                undoablyDeleteMark(mark: mark, region: activeRegion)
            }
            undoManager?.endUndoGrouping()
            ladder.setHighlightForAllMarks(highlight: .none)
            cursorViewDelegate.cursorIsVisible = false
            cursorViewDelegate.refresh()
            setNeedsDisplay()
        }
    }

    @objc func deleteAllInLadder() {
        os_log("deleteAllInLadder() - LadderView", log: OSLog.debugging, type: .debug)
        undoManager?.beginUndoGrouping()
        for region in ladder.regions {
            for mark in region.marks {
                undoablyDeleteMark(mark: mark, region: region)
            }
        }
        undoManager?.endUndoGrouping()
        ladder.setHighlightForAllMarks(highlight: .none)
        cursorViewDelegate.cursorIsVisible = false
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func ungroupPressedMark() {
        if let pressedMark = pressedMark {
            ungroupMarks(mark: pressedMark)
        }
    }

    func ungroupMarks(mark: Mark) {
        ladder.setHighlightForAllMarks(highlight: .none)
        mark.groupedMarkIds = MarkIdGroup()
    }

    @objc func straightenToProximal() {
        if let pressedMark = pressedMark {
            pressedMark.segment.distal.x = pressedMark.segment.proximal.x
            cursorViewDelegate.moveCursor(cursorViewPositionX: pressedMark.segment.proximal.x)
            cursorViewDelegate.refresh()
        }
    }

    @objc func straightenToDistal() {
        if let pressedMark = pressedMark {
            pressedMark.segment.proximal.x = pressedMark.segment.distal.x
            cursorViewDelegate.moveCursor(cursorViewPositionX: pressedMark.segment.proximal.x)
            cursorViewDelegate.refresh()
        }
    }
}

extension LadderView: LadderViewDelegate {

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionProximalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: activeRegion?.proximalBoundary ?? 0)
        return convert(position, to: view).y
    }

    func getAttachedMarkLadderViewPositionY(view: UIView) -> CGPoint? {
        guard let position = getMarkAnchorLadderViewPosition(mark: attachedMark, region: activeRegion) else {
            return nil
        }
        return convert(position, to: view)
    }

    func getMarkAnchorRegionPosition(_ mark: Mark) -> CGPoint {
        let anchor = mark.anchor
        let anchorPosition: CGPoint
        switch anchor {
        case .proximal:
            anchorPosition = mark.segment.proximal
        case .middle:
            anchorPosition = mark.midpoint()
        case .distal:
            anchorPosition = mark.segment.distal
        case .none:
            anchorPosition = mark.segment.proximal
        }
        return anchorPosition
    }

    func getMarkAnchorLadderViewPosition(mark: Mark?, region: Region?) -> CGPoint? {
        guard let mark = mark, let region = region else { return nil }
        var anchorPosition = getMarkAnchorRegionPosition(mark)
        anchorPosition = translateToScaledViewPosition(regionPosition: anchorPosition, region: region)
        return anchorPosition
    }

    func getTopOfLadder(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: ladder.regions[0].proximalBoundary)
        return convert(position, to: view).y
    }

    func getRegionMidPoint(view: UIView) -> CGFloat {
        guard let activeRegion = activeRegion else { return 0 }
        let position = CGPoint(x: 0, y: (activeRegion.distalBoundary -  activeRegion.proximalBoundary) / 2 + activeRegion.proximalBoundary)
        return convert(position, to: view).y
    }

    func getRegionDistalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: activeRegion?.distalBoundary ?? 0)
        return convert(position, to: view).y
    }

    func refresh() {
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    func setActiveRegion(regionNum: Int) {
        activeRegion = ladder.regions[regionNum]
        activeRegion?.activated = true
    }

    func hasActiveRegion() -> Bool {
        return activeRegion != nil
    }

    func unhighlightAllMarks() {
        ladder.setHighlightForAllMarks(highlight: .none)
    }

    func unselectAllMarks() {
        ladder.unselectAllMarks()
    }

    func addAttachedMark(scaledViewPositionX positionX: CGFloat) {
        attachedMark = ladder.addMark(at: positionX / scale, inRegion: activeRegion)
        if let attachedMark = attachedMark {
            undoablyAddMark(mark: attachedMark, region: activeRegion)
            attachedMark.attached = true
            attachedMark.highlight = .attached
        }
    }

    func groupMarksNearbyAttachedMark() {
        guard let attachedMark = attachedMark else { return }
        groupNearbyMarks(mark: attachedMark)
        addGroupedMiddleMarks(ofMark: attachedMark)
    }



    private func snap(movingMark: Mark, fixedMark: Mark) {

    }


    func undoablySnapMarkToNearbyMarks(mark: Mark, nearbyMarks: MarkGroup) {
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.redoablyUnsnapMarkFromNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        snapMarkToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
    }

    func redoablyUnsnapMarkFromNearbyMarks(mark: Mark, nearbyMarks: MarkGroup) {
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.undoablySnapMarkToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        unsnapMarkFromNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
    }

    func unsnapMarkFromNearbyMarks(mark: Mark, nearbyMarks: MarkGroup) {
        os_log("unsnapMarkFromNearbyMarks(mark:nearbyMarks:))", log: .action, type: .info)
        guard snapMarks else { return }
        for proxMark in nearbyMarks.proximal {
            mark.groupedMarkIds.proximal.remove(proxMark.id)
            proxMark.groupedMarkIds.distal.remove(mark.id)
        }
        for distalMark in nearbyMarks.distal {
            mark.groupedMarkIds.distal.remove(distalMark.id)
            distalMark.groupedMarkIds.proximal.remove(mark.id)
        }
        for middleMark in nearbyMarks.middle {
            mark.groupedMarkIds.middle.remove(middleMark.id)
            middleMark.groupedMarkIds.middle.remove(mark.id)
        }
    }

    // Adjust ends of marks to connect after dragging.
    func snapMarkToNearbyMarks(mark: Mark, nearbyMarks: MarkGroup) {
        os_log("SnapMarkToNearbyMarks(mark:nearbyMarks:))", log: .action, type: .info)
        guard snapMarks else { return }
        for proxMark in nearbyMarks.proximal {
            mark.groupedMarkIds.proximal.insert(proxMark.id)
            proxMark.groupedMarkIds.distal.insert(mark.id)
            mark.segment.proximal.x = proxMark.segment.distal.x
            if mark.anchor == .proximal {
                cursorViewDelegate.moveCursor(cursorViewPositionX: mark.segment.proximal.x)
            }
            else if mark.anchor == .middle {
                cursorViewDelegate.moveCursor(cursorViewPositionX: mark.midpoint().x)
            }
        }
        for distalMark in nearbyMarks.distal {
            mark.groupedMarkIds.distal.insert(distalMark.id)
            distalMark.groupedMarkIds.proximal.insert(mark.id)
            mark.segment.distal.x = distalMark.segment.proximal.x
            if mark.anchor == .proximal {
                cursorViewDelegate.moveCursor(cursorViewPositionX: mark.segment.proximal.x)
            }
            else if mark.anchor == .middle {
                cursorViewDelegate.moveCursor(cursorViewPositionX: mark.midpoint().x)
            }
        }
        for middleMark in nearbyMarks.middle {
            // FIXME: this doesn't work for vertical mark.
            mark.groupedMarkIds.middle.insert(middleMark.id)
            middleMark.groupedMarkIds.middle.insert(mark.id)
            var distanceToProximal = Common.distanceSegmentToPoint(segment: middleMark.segment, point: mark.segment.proximal)
            distanceToProximal = min(distanceToProximal, Common.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.proximal))
            var distanceToDistal = Common.distanceSegmentToPoint(segment: middleMark.segment, point: mark.segment.distal)
            distanceToDistal = min(distanceToDistal, Common.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.distal))
            if distanceToProximal < distanceToDistal {
                let x = Common.getX(onSegment: middleMark.segment, fromY: mark.segment.proximal.y)
                if let x = x {
                    mark.segment.proximal.x = x
                }
                // FIXME: This causes unexpected straightening of mark
                else { // vertical mark
//                    mark.segment.proximal.x = middleMark.segment.proximal.x
//                    mark.segment.distal.x = middleMark.segment.proximal.x
                }
            }
            else {
                let x = Common.getX(onSegment: middleMark.segment, fromY: mark.segment.distal.y)
                if let x = x {
                    mark.segment.distal.x = x
                }
                // FIXME: This causes unexpected straightening of mark
                else { // vertical mark
//                    mark.segment.proximal.x = middleMark.segment.distal.x
//                    mark.segment.distal.x = middleMark.segment.distal.x
                }
            }
        }
    }

    func groupNearbyMarks(mark: Mark) {
        os_log("groupNearbyMarks(mark:) - LadderView", log: OSLog.debugging, type: .debug)
        guard snapMarks else { return }
        let minimum: CGFloat = nearbyMarkAccuracy / scale
        let nearbyMarkIds = getNearbyMarkIds(mark: mark, nearbyDistance: minimum)
        let nearbyMarks = ladder.getMarkGroup(fromMarkIdGroup: nearbyMarkIds)
        undoablySnapMarkToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
    }

    // FIXME: this should add all grouped middle marks together, but doesn't seem to work.
    func addGroupedMiddleMarks(ofMark mark: Mark) {
//        var middleMarkIds = mark.groupedMarkIds.middle
//        for id in middleMarkIds {
//            if let middleSet = ladder.lookup(id: id)?.groupedMarkIds.middle {
//                middleMarkIds = middleMarkIds.union(middleSet)
//            }
//        }
//        mark.groupedMarkIds.middle = middleMarkIds
    }

    func getPositionYInView(positionY: CGFloat, view: UIView) -> CGFloat {
        let point = CGPoint(x: 0, y: positionY)
        return convert(point, to: view).y
    }

    func getAttachedMarkScaledAnchorPosition() -> CGPoint? {
        return getMarkScaledAnchorPosition(attachedMark)
    }

    func getMarkScaledAnchorPosition(_ mark: Mark?) -> CGPoint? {
        guard let mark = mark, let activeRegion = activeRegion else { return nil}
        return translateToScaledViewPosition(regionPosition: mark.getAnchorPosition(), region: activeRegion)
    }

    func getAttachedMarkAnchor() -> Anchor {
        guard let attachedMark = attachedMark else { return .none }
        return attachedMark.anchor
    }

    func unattachAttachedMark() {
        assessBlockAndImpulseOrigin(mark: attachedMark)
        attachedMark?.attached = false
        attachedMark?.highlight = .none
        attachedMark = nil
    }

    func deleteAttachedMark() {
        os_log("deleteAttachedMark() - LadderView", log: OSLog.debugging, type: .debug)
        deleteMark(attachedMark)
    }

    func toggleAttachedMarkAnchor() {
        toggleAnchor(mark: attachedMark)
        if let attachedMark = attachedMark, let activeRegion = activeRegion {
            adjustCursor(mark: attachedMark, region: activeRegion)
        }
    }
}

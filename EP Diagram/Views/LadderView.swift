//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import OSLog

final class LadderView: ScaledView {

    // TODO: These all may need some tweaking...
    private let ladderPaddingMultiplier: CGFloat = 0.5
    private let accuracy: CGFloat = 20
    private let lowerLimitMarkHeight: CGFloat = 0.1
    private let lowerLimitMarkWidth: CGFloat = 20
    private let nearbyMarkAccuracy: CGFloat = 15

    lazy var measurementTextAttributes: [NSAttributedString.Key: Any] = {
        let textFont = UIFont(name: "Helvetica Neue Medium", size: 14.0) ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.medium)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let attributes = [
            NSAttributedString.Key.font: textFont,
            NSAttributedString.Key.foregroundColor: UIColor.label,
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
        ]
        return attributes
    }()

    // For debugging
    #if DEBUG  // Change this for debugging impulse origins and block
    var showProxEnd = true
    var showEarliestPoint: Bool = false
    #else  // Don't ever change this
    var showProxEnd = false
    var showEarliestPoint = false
    #endif

    // Controlled by Preferences
    var markLineWidth: CGFloat = 2
    var showImpulseOrigin = true
    var showBlock = true
    var showPivots = true
    var showIntervals = true
    var showConductionTimes = true
    var showMarkText = true
    var snapMarks = true
    var defaultMarkStyle = Mark.Style.solid {
        didSet {
            ladder.defaultMarkStyle = defaultMarkStyle
        }
    }
    var showLabelDescription: TextVisibility = .invisible
    var marksAreHidden: Bool = false

    // Colors - can change via Preferences
    var activeColor = UIColor.systemRed
    var normalColor = UIColor.label
    var attachedColor = UIColor.systemOrange
    var connectedColor = UIColor.systemGreen
    var selectedColor = UIColor.systemBlue
    var linkedColor = UIColor.systemPurple

    var ladderIsLocked = false

    var zone: Zone {
        get { return ladder.zone }
        set(newValue) { ladder.zone = newValue }
    }
    let zoneColor = UIColor.systemBlue
    var calibration: Calibration?
    var ladder: Ladder = Ladder.defaultLadder()
    var activeRegion: Region? {
        get { ladder.activeRegion }
        set(newValue) { ladder.activeRegion = newValue }
    }
    var caliperMaxY: CGFloat {
        get { cursorViewDelegate.caliperMaxY }
        set(newValue) { cursorViewDelegate.caliperMaxY = newValue }
    }
    private var movingMark: Mark?
    private var regionOfDragOrigin: Region?
    private var regionProximalToDragOrigin: Region?
    private var regionDistalToDragOrigin: Region?
    private var dragCreatedMark: Mark?
    private var dragOriginDivision: RegionDivision = .none

    private var savedActiveRegion: Region?
    private var savedMode: Mode = .normal

    var mode: Mode = .normal

    var leftMargin: CGFloat = 0
    var ladderViewHeight: CGFloat = 0
    private var regionUnitHeight: CGFloat = 0

    weak var cursorViewDelegate: CursorViewDelegate! // Note IUO.
    var currentDocument: DiagramDocument?

    override var canBecomeFirstResponder: Bool { return true }

    // MARK: - init

    required init?(coder aDecoder: NSCoder) {
        os_log("init(coder:) - LadderView", log: .viewCycle, type: .info)
        super.init(coder: aDecoder)
        setupView()
    }

    // used for unit testing
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    func reset() {
        os_log("reset() - LadderView", log: .action, type: .info)
    }

    private func setupView() {
        os_log("setupView() - LadderView", log: .action, type: .info)
        ladderViewHeight = self.frame.height
        initializeRegions()
        removeConnectedMarks()
        // FIXME: snap marks on startup

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
    }

    func initializeRegions() {
        regionUnitHeight = getRegionUnitHeight(ladder: ladder)
        var regionBoundary = regionUnitHeight * ladderPaddingMultiplier
        for region: Region in ladder.regions {
            let regionHeight = CGFloat(region.unitHeight) * regionUnitHeight
            region.proximalBoundary = regionBoundary
            region.distalBoundary = regionBoundary + regionHeight
            regionBoundary += regionHeight
        }
        guard ladder.regions.count > 0 else { assertionFailure("ladder.regions has no regions!"); return }
        activeRegion = ladder.region(atIndex: 0)
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

    // MARK: - Touches

    @objc func singleTap(tap: UITapGestureRecognizer) {
        os_log("singleTap(tap:) - LadderView", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        let position = tap.location(in: self)
        let tapLocationInLadder = getLocationInLadder(position: position)
        switch mode {
        case .select:
            selectModeSingleTap(tapLocationInLadder)
        case .connect:
            connectModeSingleTap(tapLocationInLadder)
        case .normal:
            normalModeSingleTap(tapLocationInLadder)
        default: // other modes don't respond to single tap
            break
        }
    }

    func normalModeSingleTap(_ tapLocationInLadder: LocationInLadder) {
        if tapLocationInLadder.specificLocation == .label {
            assert(tapLocationInLadder.region != nil, "Label tapped, but region is nil!")
            if let region = tapLocationInLadder.region {
                labelWasTapped(labelRegion: region)
                hideCursorAndNormalizeAllMarks()
                unattachAttachedMark()
            }
        }
        else if (tapLocationInLadder.region != nil) { // tap is in a region
            regionWasTapped(tapLocationInLadder: tapLocationInLadder, positionX: tapLocationInLadder.unscaledPosition.x)
        }
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    private func hideCursorAndNormalizeAllMarks() {
        guard cursorViewDelegate.cursorIsVisible else { return }
        cursorViewDelegate.cursorIsVisible = false
        normalizeAllMarks()
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter position: point to be processed
    func getLocationInLadder(position: CGPoint) -> LocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        var tappedDivision: RegionDivision = .none
        var tappedAnchor: Anchor?
        var tappedZone: Zone?
        for region in ladder.regions {
            if position.y > region.proximalBoundary && position.y < region.distalBoundary {
                tappedRegion = region
                tappedDivision = tappedRegionDivision(region: region, positionY: position.y)
            }
        }
        if position.x > min(zone.start, zone.end) && position.x < max(zone.start, zone.end), let tappedRegion = tappedRegion {
            if ladder.zone.regions.firstIndex(of: tappedRegion) != nil {
                tappedZone = zone
            }
        }
        if let tappedRegion = tappedRegion {
            if position.x < leftMargin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(position: position, mark: mark, region: tappedRegion, accuracy: accuracy) {
                        tappedMark = mark
                        tappedAnchor = nearestAnchor(position: position, mark: mark)
                        break outerLoop
                    }
                }
            }
        }
        let location = LocationInLadder(region: tappedRegion, mark: tappedMark, ladder: ladder, zone: tappedZone, regionSection: tappedRegionSection, regionDivision: tappedDivision, markAnchor: tappedAnchor, unscaledPosition: position)
        return location
    }

    private func tappedRegionDivision(region: Region, positionY: CGFloat) -> RegionDivision {
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

    func labelWasTapped(labelRegion: Region) {
        if labelRegion.mode == .active {
            activeRegion = nil
        }
        else {
            activeRegion = labelRegion
        }
    }

    private func regionWasTapped(tapLocationInLadder: LocationInLadder, positionX: CGFloat) {
        assert(tapLocationInLadder.region != nil, "Region tapped, but is nil!")
        if let tappedRegion = tapLocationInLadder.region {
            if tappedRegion.mode != .active {
                activeRegion = tappedRegion
            }
            if let mark = tapLocationInLadder.mark {
                markWasTapped(mark: mark, tapLocationInLadder: tapLocationInLadder)
            }
            else if cursorViewDelegate.cursorIsVisible {
                hideCursorAndNormalizeAllMarks()
                unattachAttachedMark()
            }
            else { // make mark and attach cursor
                let mark = addMarkToActiveRegion(scaledViewPositionX: positionX)
                if let mark = mark {
                    undoablyAddMark(mark: mark)
                    normalizeAllMarks()
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
        if let mark = mark {
            if mark.mode == .attached {
                attachMark(mark)
                // TODO: Consider using RegionDivision to position Anchor.  Tapping on cursor it makes sense to just toggle the anchor, but tapping on the mark itself it might be better to position anchor near where you tap.  On other hand, it might be easy to miss the mark division zone.  Also, if not all anchors are available (say the .middle anchor is missing), which anchor do you switch to?  Maybe default to toggleAnchor() if anchor not available.
                toggleAnchor(mark: mark)
                adjustCursor(mark: mark)
                cursorViewDelegate.cursorIsVisible = true
            }
            else { // mark wasn't already attached.
                normalizeAllMarks()
                attachMark(mark)
                mark.anchor = ladder.defaultAnchor(forMark: mark)
                adjustCursor(mark: mark)
                cursorViewDelegate.cursorIsVisible = true
            }
        }
    }

    private func connect(marksToConnect marks: [Mark]) -> Mark? {
        // Should not be called unless two marks to connect are in marks.
        guard marks.count == 2 else { return nil }
        let firstRegionIndex = ladder.regionIndex(ofMark: marks[0])
        let secondRegionIndex = ladder.regionIndex(ofMark: marks[1])
        let regionDifference = secondRegionIndex - firstRegionIndex
        // ignore same region for now.  Only allow diff of 2 regions
        if abs(regionDifference) == 2 {
            if regionDifference > 0 {
                // FIXME: do we exclude region index out of range?
                let markRegion = ladder.region(atIndex: firstRegionIndex + 1)
                let segment = Segment(proximal: CGPoint(x: marks[0].segment.distal.x, y: 0), distal: CGPoint(x: marks[1].segment.proximal.x, y: 1.0))
                if let mark = ladder.addMark(fromSegment: segment, toRegion: markRegion) {
                    undoablyAddMark(mark: mark)
                    return mark
                }
            }
            if regionDifference < 0 {
                // FIXME: do we exclude region index out of range?
                let markRegion = ladder.region(atIndex: firstRegionIndex - 1)
                let segment = Segment(proximal: CGPoint(x: marks[1].segment.distal.x, y: 0), distal: CGPoint(x: marks[0].segment.proximal.x, y: 1.0))
                if let mark = ladder.addMark(fromSegment: segment, toRegion: markRegion) {
                    undoablyAddMark(mark: mark)
                    return mark
                }
            }
        }
        return nil
    }

    private func connectTappedMark(_ mark: Mark) {
        switch ladder.connectedMarks.count {
        case 2...:
            ladder.connectedMarks.removeAll()
            normalizeAllMarks()
            ladder.connectedMarks.append(mark)
            mark.mode = .connected
            return
        case 0:
            ladder.connectedMarks.append(mark)
            mark.mode = .connected
            return
        case 1:
            guard mark != ladder.connectedMarks[0] else { return }
            // different mark tapped
            // what region is the mark in?
            let markRegionIndex = ladder.regionIndex(ofMark: mark)
            let firstMarkRegionIndex = ladder.regionIndex(ofMark: ladder.connectedMarks[0])
            // TODO: what about create mark with each tap?
            let regionDistance = abs(markRegionIndex - firstMarkRegionIndex)
            if regionDistance > 1 {
                ladder.connectedMarks.append(mark)
                mark.mode = .connected
                if let connectedMark = connect(marksToConnect: ladder.connectedMarks) {
                    ladder.connectedMarks.append(connectedMark)
                    connectedMark.mode = .connected
                    linkNearbyMarks(mark: connectedMark)
                    addlinkedMiddleMarks(ofMark: connectedMark)
                }
            }

        // etc.
        default:
            assertionFailure("Impossible connected mark count.")
        }
    }

    func removeConnectedMarks() {
        ladder.connectedMarks.removeAll()
    }

    private func connectModeSingleTap(_ tapLocationInLadder: LocationInLadder) {
        if let mark = tapLocationInLadder.mark {
            connectTappedMark(mark)
        }
        else if let region = tapLocationInLadder.region {
            // Regions are only used if a first mark is already chosen.
            guard ladder.connectedMarks.count == 1 else { return }
            let firstTappedMark = ladder.connectedMarks[0]
            // Region must be adjacent to the first mark.
            let firstTappedMarkRegionIndex = ladder.regionIndex(ofMark: firstTappedMark)
            guard let regionIndex = ladder.index(ofRegion: region),
                  abs(firstTappedMarkRegionIndex - regionIndex) == 1 else { return }
            activeRegion = region
            // draw mark from end of previous connecteded mark
            let tapRegionPosition = transformToRegionPosition(scaledViewPosition: tapLocationInLadder.unscaledPosition, region: region)
            if firstTappedMarkRegionIndex < regionIndex {
                // marks must reach close enough to region boundary to be snapable
                guard firstTappedMark.segment.distal.y > (1.0 - lowerLimitMarkHeight) else { return }
                if let newMark = addMarkToActiveRegion(regionPositionX: firstTappedMark.segment.distal.x) {
                    newMark.segment.distal = tapRegionPosition
                    newMark.mode = .connected
                    ladder.connectedMarks.append(newMark)
                    undoablyAddMark(mark: newMark)
                }
            }
            else if firstTappedMarkRegionIndex > regionIndex {
                guard firstTappedMark.segment.proximal.y < lowerLimitMarkHeight else { return }
                if let newMark = addMarkToActiveRegion(regionPositionX: firstTappedMark.segment.proximal.x) {
                    newMark.segment.proximal = tapRegionPosition
                    newMark.mode = .connected
                    ladder.connectedMarks.append(newMark)
                    undoablyAddMark(mark: newMark)
                }
            }
            // FIXME: what do do if something illegal tapped (same mark, illegal region).  Remove connected marks?
            // Maybe displace red X if illegal spot.
            else {
                ladder.connectedMarks.removeAll()
            }
        }
        setNeedsDisplay()
    }

    private func selectModeSingleTap(_ tapLocationInLadder: LocationInLadder) {
        if ladder.zone.isVisible {
            // This deselects all selected marks, even those outside zone, which means you can't combine zone selection with region or mark selection, but this seems like the best solution for now.
            ladder.setAllMarksWithMode(.normal)
            ladder.hideZone()
        } else if let mark = tapLocationInLadder.mark {
            // toggle mark selection
            mark.mode = mark.mode == .selected ? .normal : .selected
        } else if let region = tapLocationInLadder.region {
            region.mode = region.mode == .selected ? .normal : .selected
            ladder.setMarksWithMode(region.mode == .selected ? .selected : .normal, inRegion: region)
        }
        setNeedsDisplay()
    }

    func adjustCursor(mark: Mark) {
        let anchorPosition = mark.getAnchorPosition()
        let theRegion = ladder.region(ofMark: mark)
        let scaledAnchorPositionY = transformToScaledViewPosition(regionPosition: anchorPosition, region: theRegion).y
        cursorViewDelegate.moveCursor(cursorViewPositionX: anchorPosition.x)
        cursorViewDelegate.setCursorHeight(anchorPositionY: scaledAnchorPositionY)
    }

    /// - Parameters:
    ///   - position: position of, say a tap on the screen
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    ///   - accuracy: how close does it have to be?
    func nearMark(position: CGPoint, mark: Mark, region: Region, accuracy: CGFloat) -> Bool {
        let scaledViewMarkSegment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        let distance = Geometry.distanceSegmentToPoint(segment: scaledViewMarkSegment, point: position)
        return distance < accuracy
    }

    func positionIsNearMark(position: CGPoint) -> Bool {
        return getLocationInLadder(position: position).specificLocation == .mark
    }

    /// Determine which anchor a point is closest to.
    /// - Parameters:
    ///   - point: a point in ladder view coordinates
    ///   - mark: mark to check for proximity
    ///   - region: region in which mark is located
    func nearestAnchor(position: CGPoint, mark: Mark) -> Anchor? {
        let region = ladder.region(ofMark: mark)
        let regionPoint = transformToRegionPosition(scaledViewPosition: position, region: region)
        let proximalDistance = CGPoint.distanceBetweenPoints(mark.segment.proximal, regionPoint)
        let middleDistance = CGPoint.distanceBetweenPoints(mark.midpoint(), regionPoint)
        let distalDistance = CGPoint.distanceBetweenPoints(mark.segment.distal, regionPoint)
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
            return nil
        }
    }

    func addMarkToActiveRegion(scaledViewPositionX: CGFloat) -> Mark? {
        return addMarkToActiveRegion(regionPositionX: transformToRegionPositionX(scaledViewPositionX: scaledViewPositionX))
    }

    func addMarkToActiveRegion(regionPositionX: CGFloat) -> Mark? {
        if let mark = ladder.addMark(at: regionPositionX, toRegion: activeRegion) {
            mark.mode = .attached
            return mark
        }
        return nil
    }

    @available(*, deprecated, message: "Used for setting anchor depending on tap location, not used.")
    func getAnchor(regionDivision: RegionDivision) -> Anchor? {
        let anchor: Anchor?
        switch regionDivision {
        case .proximal:
            anchor = .proximal
        case .middle:
            anchor = .middle
        case .distal:
            anchor = .distal
        case .none:
            anchor = nil
        }
        return anchor
    }

    func toggleAnchor(mark: Mark?) {
        ladder.toggleAnchor(mark: mark)
    }

    func setAttachedMarkAndLinkedMarksModes() {
        print("setAttachedMarkAndLinkedMarksModes()")
        if let attachedMark = ladder.attachedMark {
            let linkedMarkIDs = attachedMark.linkedMarkIDs
            // Note that the order below is important.  An attached mark can be in its own linkedMarks.  But we always want the attached mark to have an .attached highlight.
            ladder.setModeForLinkedMarkIDs(mode: .linked, linkedMarkIDs: linkedMarkIDs)
            attachedMark.mode = .attached
        }
    }

    func attachMark(_ mark: Mark?) {
        print("attachMark()")
        ladder.attachedMark = mark
        setAttachedMarkAndLinkedMarksModes()
    }


    @objc func doubleTap(tap: UITapGestureRecognizer) {
        os_log("doubleTap(tap:) - LadderView", log: OSLog.touches, type: .info)
        guard !marksAreHidden else { return }
        switch mode {
        case .normal:
            if deleteOrAddMark(position: tap.location(in: self), cursorViewDelegate: cursorViewDelegate) {
                setNeedsDisplay()
            }
        default:
            break
        }
    }

    /// Deletes mark if there is one at position.  Returns true if position corresponded to a mark.
    /// - Parameter position: position of potential mark
    func deleteOrAddMark(position: CGPoint, cursorViewDelegate: CursorViewDelegate) -> Bool {
        os_log("deleteMark(position:cursofViewDelegate:) - LadderView", log: OSLog.debugging, type: .debug)
        let tapLocationInLadder = getLocationInLadder(position: position)
        activeRegion = tapLocationInLadder.region
        if tapLocationInLadder.specificLocation == .mark {
            if let mark = tapLocationInLadder.mark {
                undoablyDeleteMark(mark: mark)
                return true
            }
        } else {
            // FIXME: refactor
            let region = tapLocationInLadder.region
            let scaledPositionX = transformToRegionPositionX(scaledViewPositionX: tapLocationInLadder.unscaledPosition.x)
            if let mark = ladder.addMark(at: scaledPositionX, toRegion: region) {
                normalizeAllMarks()
                undoablyAddMark(mark: mark)
                attachMark(mark)
                cursorViewDelegate.moveCursor(cursorViewPositionX: scaledPositionX)
                cursorViewDelegate.cursorIsVisible = true
                cursorViewDelegate.setCursorHeight()
                cursorViewDelegate.refresh()
            }
        }
        return true
    }

    // See https://stackoverflow.com/questions/36491789/using-nsundomanager-how-to-register-undos-using-swift-closures/36492619#36492619
    func undoablyDeleteMark(mark: Mark) {
        os_log("undoablyDeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.redoablyUndeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        deleteMark(mark)
    }

    func redoablyUndeleteMark(mark: Mark) {
        os_log("redoablyUndeleteMark(mark:region:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        undeleteMark(mark: mark)
    }

    private func undoablyAddMark(mark: Mark) {
        os_log("undoablyAddMark(mark:) - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.undoablyDeleteMark(mark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        // Note no call here because calling function needs to actually add the mark.
    }

    private func deleteMark(_ mark: Mark) {
        os_log("deleteMark(mark:) - LadderView", log: OSLog.debugging, type: .debug)
        mark.mode = .normal
        ladder.deleteMark(mark)
        hideCursorAndNormalizeAllMarks()
        cursorViewDelegate.refresh()
    }

    private func undeleteMark(mark: Mark) {
        os_log("undeleteMark(mark:) - LadderView", log: OSLog.debugging, type: .debug)
        let region = ladder.region(ofMark: mark)
        ladder.addMark(mark, toRegion: region)
        mark.mode = .normal
        hideCursorAndNormalizeAllMarks()
        cursorViewDelegate.refresh()
    }

    fileprivate func normalModeDrag(_ pan: UIPanGestureRecognizer) {
        let position = pan.location(in: self)
        let state = pan.state
        let locationInLadder = getLocationInLadder(position: position)
        if state == .began {
            currentDocument?.undoManager?.beginUndoGrouping()
            // Activate region and get regions proximal and distal.
            if let region = locationInLadder.region {
                regionOfDragOrigin = region
                regionProximalToDragOrigin = ladder.regionBefore(region: region)
                regionDistalToDragOrigin = ladder.regionAfter(region: region)
                activeRegion = region
            }
            if let regionOfDragOrigin = regionOfDragOrigin {
                // We're about to move the attached mark.
                if let mark = locationInLadder.mark, mark.mode == .attached {
                    movingMark = mark
                    setAttachedMarkAndLinkedMarksModes()
                    // need to move it nowhere, to let undo work
                    if let anchorPosition = getMarkScaledAnchorPosition(mark) {
                        moveMark(mark: mark, scaledViewPosition: anchorPosition)
                    }
                }
                else {  // We need to make a new mark.
                    hideCursorAndNormalizeAllMarks()
                    unattachAttachedMark()
                    // Get the third of region for endpoint of new mark.
                    dragOriginDivision = locationInLadder.regionDivision
                    switch dragOriginDivision {
                    case .proximal:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0
                        dragCreatedMark?.segment.distal.y = 0.5
                    case .middle:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        // TODO: REFACTOR
                        dragCreatedMark?.segment.proximal.y = (position.y - regionOfDragOrigin.proximalBoundary) / (regionOfDragOrigin.distalBoundary - regionOfDragOrigin.proximalBoundary)
                        dragCreatedMark?.segment.distal.y = 0.75
                    case .distal:
                        dragCreatedMark = addMarkToActiveRegion(scaledViewPositionX: position.x)
                        dragCreatedMark?.segment.proximal.y = 0.5
                        dragCreatedMark?.segment.distal.y = 1
                    case .none:
                        assert(false, "Making a mark with a .none regionDivision!")
                    }
                    if let dragCreatedMark = dragCreatedMark {
                        undoablyAddMark(mark: dragCreatedMark)
                    }
                    dragCreatedMark?.mode = .attached
                }
            }
        }
        if state == .changed {
            if let mark = movingMark {
                moveMark(mark: mark, scaledViewPosition: position)
                setModeOfNearbyMarks(movingMark)
            }
            else if regionOfDragOrigin == locationInLadder.region, let regionOfDragOrigin = regionOfDragOrigin {
                switch dragOriginDivision {
                case .proximal:
                    dragCreatedMark?.segment.distal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                case .distal:
                    dragCreatedMark?.segment.proximal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                case .middle:
                    dragCreatedMark?.segment.distal = transformToRegionPosition(scaledViewPosition: position, region: regionOfDragOrigin)
                default:
                    break
                }
                setModeOfNearbyMarks(dragCreatedMark)
            }
        }
        if state == .ended {
            currentDocument?.undoManager?.endUndoGrouping()
            if let movingMark = movingMark {
                swapEndsIfNeeded(mark: movingMark)
                linkNearbyMarks(mark: movingMark)
                addlinkedMiddleMarks(ofMark: movingMark)
                assessBlockAndImpulseOrigin(mark: movingMark)
            }
            else if let dragCreatedMark = dragCreatedMark {
                if dragCreatedMark.height < lowerLimitMarkHeight && dragCreatedMark.width < lowerLimitMarkWidth {
                    undoablyDeleteMark(mark: dragCreatedMark)
                }
                else {
                    swapEndsIfNeeded(mark: dragCreatedMark)
                    linkNearbyMarks(mark: dragCreatedMark)
                    addlinkedMiddleMarks(ofMark: dragCreatedMark)
                    assessBlockAndImpulseOrigin(mark: dragCreatedMark)
                }
            }
            if !cursorViewDelegate.cursorIsVisible {
                normalizeAllMarks()
            }
            dragCreatedMark?.mode = .normal
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

    @objc func dragging(pan: UIPanGestureRecognizer) {
        guard !marksAreHidden else { return }
        switch mode {
        case .select:
            selectModeDrag(pan)
        case .normal:
            normalModeDrag(pan)
        default:
            break
        }
    }

    func selectModeDrag(_ pan: UIPanGestureRecognizer) {
        let position = pan.location(in: self)
        let state = pan.state
        let regionPositionX = transformToRegionPositionX(scaledViewPositionX: position.x)
        let locationInLadder = getLocationInLadder(position: position)
        guard let region = locationInLadder.region else { return }
        if state == .began {
            zone = Zone()
            zone.startingRegion = region
            zone.regions.insert(region)
            zone.start = regionPositionX
            zone.end = regionPositionX
        }
        if state == .changed {
            if !zone.regions.contains(region) {
                self.zone.regions.insert(region)
            }
            zone.end = regionPositionX
            selectInZone()
        }
        if state == .ended {
            selectInZone()
        }
        setNeedsDisplay()
    }

    func selectInZone() {
        let zoneMin = min(zone.start, zone.end)
        let zoneMax = max(zone.start, zone.end)
        for region in zone.regions {
            for mark in region.marks {
                if (mark.segment.proximal.x > zoneMin
                        || mark.segment.distal.x > zoneMin)
                    && (mark.segment.proximal.x < zoneMax
                            || mark.segment.distal.x < zoneMax) {
                    mark.mode = .selected
                } else {
                    mark.mode = .normal
                }
            }
        }
    }

    func setModeInZone(mode: Mark.Mode) {
        let zoneMin = min(zone.start, zone.end)
        let zoneMax = max(zone.start, zone.end)
        for region in zone.regions {
            for mark in region.marks {
                if (mark.segment.proximal.x > zoneMin
                        || mark.segment.distal.x > zoneMin)
                    && (mark.segment.proximal.x < zoneMax
                            || mark.segment.distal.x < zoneMax) {
                    mark.mode = mode
                }
            }
        }
    }

    private func swapEndsIfNeeded(mark: Mark) {
        print("****swapping ends")
        let proximalY = mark.segment.proximal.y
        let distalY = mark.segment.distal.y
        if proximalY > distalY {
            P("swapping ends")
            mark.swapEnds()
        }
    }

    func swapEndsIfNeeded() {
        ladder.regions.forEach {
            region in region.marks.forEach {
                mark in self.swapEndsIfNeeded(mark: mark)
            }
        }
    }



    // TODO: expand on this logic.  Reset block and impulseOrigin to .none as necessary.
    // Also, consider adding arrows to marks indicating direction of flow (arrow will be added
    // to whichever end of the mark is later in time.  Opposite of impluse origin.
    func assessBlockAndImpulseOrigin(mark: Mark?) {
        if let mark = mark {
            assessBlock(mark: mark)
            assessImpulseOrigin(mark: mark)
        }
    }

    var blockMin: CGFloat = 0.1
    var blockMax: CGFloat = 0.9
    func assessBlock(mark: Mark) {
        if mark.autoBlock {
            mark.block = .none
            if mark.early == .none {
                return  // for now, ignore vertical marks
            }
            if mark.segment.proximal.y > blockMin
                && mark.late == .proximal {
                mark.block = .proximal
            } else if mark.segment.distal.y < blockMax
                        && mark.late == .distal {
                mark.block = .distal
            }
        }
    }

    func assessImpulseOrigin(mark: Mark) {
        mark.impulseOrigin = .none
        if mark.linkedMarkIDs.proximal.count == 0 && (mark.early == .proximal || mark.early == .none) {
            mark.impulseOrigin = .proximal
        } else if mark.linkedMarkIDs.distal.count == 0 && mark.early == .distal {
            mark.impulseOrigin = .distal
        }
    }

    func clearBlock() {
        ladder.clearBlock()
    }

    func clearImpulseOrigin() {
        ladder.clearImpulseOrigin()
    }

    private func setModeOfNearbyMarks(_ mark: Mark?) {
        guard let mark = mark else { return }
        let nearbyDistance = nearbyMarkAccuracy / scale
        let markIds = nearbyMarkIds(mark: mark, nearbyDistance: nearbyDistance)
        // FIXME: xxx
        ladder.normalizeAllMarks()
        ladder.setModeForLinkedMarkIDs(mode: .linked, linkedMarkIDs: markIds)
        setAttachedMarkAndLinkedMarksModes()
    }

    // FIXME: middle marks end up with a copy of themselves in the neighboring linked marks.
    // Returns linked mark ids of marks close to passed in mark.
    func nearbyMarkIds(mark: Mark, nearbyDistance: CGFloat) -> LinkedMarkIDs {
        guard let activeRegion = activeRegion else { return LinkedMarkIDs() }
        var proximalMarkIds = MarkIdSet()
        var distalMarkIds = MarkIdSet()
        var middleMarkIds = MarkIdSet()
        if let proximalRegion = ladder.regionBefore(region: activeRegion) {
            for neighboringMark in proximalRegion.marks {
                if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                    proximalMarkIds.insert(neighboringMark.id)
                }
            }
        }
        if let distalRegion = ladder.regionAfter(region: activeRegion) {
            for neighboringMark in distalRegion.marks {
                if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                    distalMarkIds.insert(neighboringMark.id)
                }
            }
        }
        // check in the same region ("middle region", same as activeRegion)
        for neighboringMark in activeRegion.marks {
            if assessCloseness(ofMark: mark, toNeighboringMark: neighboringMark, usingNearbyDistance: nearbyDistance) {
                middleMarkIds.insert(neighboringMark.id)
            }
        }
        return LinkedMarkIDs(proximal: proximalMarkIds, middle: middleMarkIds, distal: distalMarkIds)
    }

    func assessCloseness(ofMark mark: Mark, toNeighboringMark neighboringMark: Mark, usingNearbyDistance nearbyDistance: CGFloat) -> Bool {
        guard mark != neighboringMark else { return false }
        let region = ladder.region(ofMark: mark)
        let neighboringRegion = ladder.region(ofMark: neighboringMark)
        // parallel marks in the same region are by definition not close
        if (region == neighboringRegion) && (Geometry.areParallel(mark.segment, neighboringMark.segment)) {
            return false
        }
        var isClose = false
        // To get minimum distance between two line segments, must get minimum distances between each segment and each endpoint of the other segment, and take minimum of all those.
        let ladderViewPositionNeighboringMarkSegment = transformToScaledViewSegment(regionSegment: neighboringMark.segment, region: neighboringRegion)
        let ladderViewPositionMarkProximal = transformToScaledViewPosition(regionPosition: mark.segment.proximal, region: region)
        let ladderViewPositionMarkDistal = transformToScaledViewPosition(regionPosition: mark.segment.distal, region: region)
        let distanceToNeighboringMarkSegmentProximal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkProximal)
        let distanceToNeighboringMarkSegmentDistal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionNeighboringMarkSegment, point: ladderViewPositionMarkDistal)

        let ladderViewPositionMarkSegment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        let ladderViewPositionNeighboringMarkProximal = transformToScaledViewPosition(regionPosition: neighboringMark.segment.proximal, region: neighboringRegion)
        let ladderViewPositionNeighboringMarkDistal = transformToScaledViewPosition(regionPosition: neighboringMark.segment.distal, region: neighboringRegion)
        let distanceToMarkSegmentProximal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionMarkSegment, point: ladderViewPositionNeighboringMarkProximal)
        let distanceToMarkSegmentDistal = Geometry.distanceSegmentToPoint(segment: ladderViewPositionMarkSegment, point: ladderViewPositionNeighboringMarkDistal)

        if distanceToNeighboringMarkSegmentProximal < nearbyDistance
            || distanceToNeighboringMarkSegmentDistal < nearbyDistance
            || distanceToMarkSegmentProximal < nearbyDistance
            || distanceToMarkSegmentDistal < nearbyDistance {
            isClose = true
        }
        return isClose
    }

    func moveAttachedMark(position: CGPoint) {
        if let attachedMark = ladder.attachedMark {
            moveMark(mark: attachedMark, scaledViewPosition: position)
        }
    }

    func fixBoundsOfAttachedMark() {
        if let attachedMark = ladder.attachedMark {
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
        mark.move(movement: movement, to: regionPosition)
        moveLinkedMarks(forMark: mark)
        adjustCursor(mark: mark)
        cursorViewDelegate.refresh()
    }

    // FIXME: After saving and reopening diagram, the linked marks appear to have their segments adjusted appropriately, but nothing shows up on the screen.  The linked marks don't move.  Why?
    private func moveLinkedMarks(forMark mark: Mark) {
        os_log("moveLinkedMarked(forMark:)", log: .action, type: .info)
        ladder.moveLinkedMarks(forMark: mark)
        setNeedsDisplay()
    }

    func moveMark(mark: Mark, scaledViewPosition: CGPoint) {
        guard let activeRegion = activeRegion else { return }
        let regionPosition = transformToRegionPosition(scaledViewPosition: scaledViewPosition, region: activeRegion)
        if cursorViewDelegate.cursorIsVisible {
            undoablyMoveMark(movement: cursorViewDelegate.cursorMovement(), mark: mark, regionPosition: regionPosition)
        }
        setModeOfNearbyMarks(mark)
    }

    func setSelectedMark(position: CGPoint) {
        let locationInLadder = getLocationInLadder(position: position)
        if let mark = locationInLadder.mark {
            normalizeAllMarks()
            mark.mode = .selected
        }
    }

    func undoablySetMarkStyle(mark: Mark, style: Mark.Style) {
        let originalStyle = mark.style
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetMarkStyle(mark: mark, style: originalStyle)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.style = style
    }

    func setSelectedMarksStyle(style: Mark.Style) {
        let selectedMarks: [Mark] = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in self.undoablySetMarkStyle(mark: mark, style: style) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func undoablySetAutoBlock(mark: Mark, value: Bool) {
        let originalValue = mark.autoBlock
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetAutoBlock(mark: mark, value: originalValue)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.autoBlock = value
        print("****mark autoblock = \(mark.autoBlock)")
    }

    func setSelectedMarksAutoBlock(value: Bool) {
        let selectedMarks: [Mark] = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in self.undoablySetAutoBlock(mark: mark, value: value) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func setSelectedMarksEmphasis(emphasis: Mark.Emphasis) {
        let selectedMarks: [Mark] = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in self.undoablySetMarkEmphasis(mark: mark, emphasis: emphasis) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func undoablySetMarkEmphasis(mark: Mark, emphasis: Mark.Emphasis) {
        let originalEmphasis = mark.emphasis
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetMarkEmphasis(mark: mark, emphasis: originalEmphasis)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.emphasis = emphasis
    }

    func undoablySetRegionStyle(region: Region, style: Mark.Style) {
        let originalStyle = region.style
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetRegionStyle(region: region, style: originalStyle)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        region.style = style
    }

    func setSelectedRegionsStyle(style: Mark.Style) {
        let selectedRegions: [Region] = ladder.allRegionsWithMode(.labelSelected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedRegions.forEach { region in self.undoablySetRegionStyle(region: region, style: style) }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func dominantStyleOfMarks(marks: [Mark]) -> Mark.Style? {
        guard marks.count > 0 else { return nil }
        let count = marks.count
        if marks.filter({ $0.style == .solid }).count == count {
            return .solid
        }
        if marks.filter({ $0.style == .dotted }).count == count {
            return .dotted
        }
        if marks.filter({ $0.style == .dashed }).count == count {
            return .dashed
        }
        return nil
    }

    func dominantEmphasisOfMarks(marks: [Mark]) -> Mark.Emphasis? {
        guard marks.count > 0 else { return nil }
        let count = marks.count
        if marks.filter({ $0.emphasis == .bold }).count == count {
            return .bold
        }
        if marks.filter({ $0.emphasis == .normal }).count == count {
            return .normal
        }
        return nil
    }

    func dominantAutoBlockOfMarks(marks: [Mark]) -> Bool? {
        guard marks.count > 0 else { return nil }
        let count = marks.count
        if marks.filter({ $0.autoBlock == true }).count == count {
            return true
        }
        if marks.filter({ $0.autoBlock == false }).count == count {
            return false
        }
        return nil
    }

    func noSelectionExists() -> Bool {
        for region in ladder.regions {
            if region.mode == .selected {
                return false
            }
            for mark in region.marks {
                if mark.mode == .selected {
                    return false
                }
            }
        }
        return true
    }

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(1)
        let ladderWidth: CGFloat = rect.width
        for (index, region) in ladder.regions.enumerated() {
            let regionRect = CGRect(x: leftMargin, y: region.proximalBoundary, width: ladderWidth, height: region.distalBoundary - region.proximalBoundary)
            let lastRegion = index == ladder.regions.count - 1
            drawRegion(rect: regionRect, context: context, region: region, offset: offsetX, scale: scale, lastRegion: lastRegion)
        }
        if mode == .select {
            drawZone(context: context)
        }
        if ladderIsLocked {
            showLockLadderWarning(rect: rect)
        }
        if marksAreHidden {
            showMarksAreHiddenWarning(rect: rect)
        }
    }

    func startZoning() {
        zone = Zone()
    }

    func endZoning() {
        zone = Zone()
    }

    fileprivate func drawZone(context: CGContext) {
        let start = transformToScaledViewPositionX(regionPositionX: zone.start)
        let end = transformToScaledViewPositionX(regionPositionX: zone.end)
        for region in zone.regions {
            let zoneRect = CGRect(x: start, y: region.proximalBoundary, width: end - start, height: region.distalBoundary - region.proximalBoundary)
            context.addRect(zoneRect)
            context.setFillColor(zoneColor.cgColor)
            context.setAlpha(0.2)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1.0)
    }

    // TODO: implement fitting longer label text into labels
    fileprivate func drawLabel(rect: CGRect, region: Region, context: CGContext) {
        let stringRect = CGRect(x: 0, y: rect.origin.y, width: rect.origin.x, height: rect.height)
        // TODO: refactor out constant attributes.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 18.0),
            .foregroundColor: region.mode == .active ? activeColor : selectedColor
        ]
        let text = region.name
        let labelText = NSAttributedString(string: text, attributes: attributes)
        let size: CGSize = text.size(withAttributes: attributes)
        let labelRect = CGRect(x: 0, y: rect.origin.y + (rect.height - size.height) / 2, width: rect.origin.x, height: size.height)

        context.addRect(stringRect)
        context.setStrokeColor(activeColor.cgColor)
        if region.mode == .labelSelected {
            context.setFillColor(selectedColor.cgColor)
            context.setAlpha(0.2)
        } else {
            context.setFillColor(UIColor.secondarySystemBackground.cgColor)
        }
        context.setLineWidth(1)
        context.drawPath(using: .fillStroke)
        context.setAlpha(1.0)
        labelText.draw(in: labelRect)

        // FIXME: Raise up label a bit to allow room for description
        guard showLabelDescription != .invisible else { return }
        let descriptionAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 12.0),
            .foregroundColor: region.mode == .active ? activeColor : selectedColor
        ]
        let descriptionText = NSAttributedString(string: region.longDescription, attributes: descriptionAttributes)

        let descriptionSize: CGSize = region.longDescription.size(withAttributes: descriptionAttributes)
        if showLabelDescription == .visibility || (showLabelDescription == .visibleIfFits && descriptionSize.width < stringRect.width) {
            let descriptionRect = CGRect(x: 0, y: labelRect.minY + labelRect.height, width: rect.origin.x, height: stringRect.height - labelRect.height)

            descriptionText.draw(in: descriptionRect)
        }

    }

    fileprivate func drawRegionArea(context: CGContext, rect: CGRect, region: Region) {
        // Draw top ladder line
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        context.addLine(to: CGPoint(x: rect.width, y: rect.origin.y))
        context.strokePath()

        let regionRect = CGRect(x: rect.origin.x, y: rect.origin.y, width: rect.width, height: rect.height)

        // Highlight region if selected
        if region.mode == .active {
            context.setAlpha(0.2)
            context.addRect(regionRect)
            context.setFillColor(activeColor.cgColor)
            context.drawPath(using: .fillStroke)
        }
        if region.mode == .selected {
            context.setAlpha(0.2)
            context.addRect(regionRect)
            context.setFillColor(selectedColor.cgColor)
            context.drawPath(using: .fillStroke)
        }
        context.setAlpha(1)
    }

    fileprivate func drawMark(mark: Mark, region: Region, context: CGContext) {
        // Don't draw outside bounds of region, fix out of bounds segments at end of mark movement.
        let normalizedSegment = mark.segment.normalized()
        let segment = transformToScaledViewSegment(regionSegment: normalizedSegment, region: region)
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
        context.setLineWidth(mark.emphasis == .bold ? markLineWidth + 1 :  markLineWidth)
        context.move(to: p1)
        context.addLine(to: p2)
        // Draw dashed line
        if mark.style == .dashed {
            let dashes: [CGFloat] = [5, 5]
            context.setLineDash(phase: 0, lengths: dashes)
        }
        else if mark.style == .dotted {
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
        drawConductionTime(forMark: mark, segment: segment, context: context)
        drawIntervals(region: region, context: context)

        drawProxEnd(forMark: mark, segment: segment, context: context)
        drawEarliestPoint(forMark: mark, segment: segment, context: context)

        context.setStrokeColor(UIColor.label.cgColor)
    }

    fileprivate func drawIntervals(region: Region, context: CGContext) {
        guard showIntervals else { return }
        guard let calibration = calibration, calibration.isCalibrated else { return }
        let marks = region.marks
        let intervals = Interval.createIntervals(marks: marks)
        for interval in intervals {
            if let firstProximalX = interval.proximalBoundary?.first, let secondProximalX = interval.proximalBoundary?.second {
                let scaledFirstX = transformToScaledViewPositionX(regionPositionX: firstProximalX)
                let scaledSecondX = transformToScaledViewPositionX(regionPositionX: secondProximalX)
                let halfwayPosition = (scaledFirstX + scaledSecondX) / 2.0
                let value = formatValue(interval.proximalValue, usingCalFactor: calibration.currentCalFactor)
                let text = "\(value)"
                var origin = CGPoint(x: halfwayPosition, y: region.proximalBoundary)
                let size = text.size(withAttributes: measurementTextAttributes)
                // Center the origin.
                origin = CGPoint(x: origin.x - size.width / 2, y: origin.y)
                drawIntervalText(origin: origin, size: size, text: text, context: context, attributes: measurementTextAttributes)
            }
            if let firstDistalX = interval.distalBoundary?.first, let secondDistalX = interval.distalBoundary?.second {
                let scaledFirstX = transformToScaledViewPositionX(regionPositionX: firstDistalX)
                let scaledSecondX = transformToScaledViewPositionX(regionPositionX: secondDistalX)
                let halfwayPosition = (scaledFirstX + scaledSecondX) / 2.0
                let value = formatValue(interval.distalValue, usingCalFactor: calibration.currentCalFactor)
                let text = "\(value)"
                var origin = CGPoint(x: halfwayPosition, y: region.distalBoundary)
                let size = text.size(withAttributes: measurementTextAttributes)
                // Center the origin.
                origin = CGPoint(x: origin.x - size.width / 2, y: origin.y - size.height)
                drawIntervalText(origin: origin, size: size, text: text, context: context, attributes: measurementTextAttributes)
            }
        }
    }

    private func formatValue(_ value: CGFloat?, usingCalFactor calFactor: CGFloat) -> Int {
        return lround(Double(value ?? 0)  * Double(calFactor))
    }

    private func drawIntervalText(origin: CGPoint, size: CGSize, text: String, context: CGContext, attributes: [NSAttributedString.Key: Any]) {
        let textRect = CGRect(origin: origin, size: size)
        if textRect.minX > leftMargin {
            text.draw(in: textRect, withAttributes: attributes)
            context.strokePath()
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
        let intersection = Geometry.intersection(ofLineFrom: CGPoint(x: leftMargin, y: 0), to: CGPoint(x: leftMargin, y: ladderViewHeight), withLineFrom: segment.proximal, to: segment.distal)
        return intersection
    }

    func drawFilledCircle(context: CGContext, position: CGPoint, radius: CGFloat) {
        let rectangle = CGRect(x: position.x, y: position.y, width: radius, height: radius)
        context.addEllipse(in: rectangle)
        context.drawPath(using: .fillStroke)
    }

    func drawProxEnd(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showProxEnd else { return }
        drawFilledCircle(context: context, position: segment.proximal, radius: 10)
    }

    func drawEarliestPoint(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showEarliestPoint else { return }
        if mark.earliestPoint == mark.segment.proximal {
            drawFilledCircle(context: context, position: segment.proximal, radius: 20)
        } else {
            drawFilledCircle(context: context, position: segment.distal, radius: 20)
        }
    }

    func drawPivots(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard showPivots else { return }
        // We only show pivots when cursor is attached.
        guard mark.mode == .attached else { return }
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

    func drawConductionTime(forMark mark: Mark, segment: Segment, context: CGContext) {
        guard let calibration = calibration, calibration.isCalibrated, showConductionTimes, mark.showMeasurementText else { return }
        let value = lround(Double(cursorViewDelegate.markMeasurement(segment: segment)))
        let text = "\(value)"
        var origin = segment.midpoint
        let size = text.size(withAttributes: measurementTextAttributes)
        // Center the origin.
        origin = CGPoint(x: origin.x + 10, y: origin.y - size.height / 2)
        let textRect = CGRect(origin: origin, size: size)
        if textRect.minX > leftMargin {
            text.draw(in: textRect, withAttributes: measurementTextAttributes)
            context.strokePath()
        }

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
        switch mark.mode {
        case .linked:
            return linkedColor.cgColor
        case .attached:
            return attachedColor.cgColor
        case .selected:
            return selectedColor.cgColor
        case .connected:
            return connectedColor.cgColor
        case .normal:
            return normalColor.cgColor
        }
    }

    fileprivate func drawMarks(region: Region, context: CGContext,  rect: CGRect) {
        // Draw marks
        for mark: Mark in region.marks {
            drawMark(mark: mark, region: region, context: context)

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
        if !marksAreHidden {
            drawMarks(region: region, context: context, rect: rect)
        }
        drawBottomLine(context: context, lastRegion: lastRegion, rect: rect)
    }

    func normalizeRegions() {
        ladder.normalizeRegions()
    }

    func normalizeAllMarks() {
        ladder.normalizeAllMarks()
    }

    func normalizeLadder() {
        ladder.normalize()
    }

    func resetSize() {
        os_log("resetSize() - LadderView", log: .action, type: .info)
        ladderViewHeight = self.frame.height
        initializeRegions()
        cursorViewDelegate.setCursorHeight()
    }

    @objc func deleteSelectedMarks() {
        os_log("deleteSelectedMarks() - LadderView", log: OSLog.debugging, type: .debug)
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarks.forEach { mark in self.undoablyDeleteMark(mark: mark) }
        hideCursorAndNormalizeAllMarks()
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func deleteAllInSelectedRegion() {
        os_log("deleteAllInRegion() - LadderView", log: OSLog.debugging, type: .debug)
        let selectedRegions = ladder.allRegionsWithMode(.selected)
        // assume only one selected region
        guard selectedRegions.count > 0 else { return }
        if let selectedRegion = selectedRegions.first {
            currentDocument?.undoManager?.beginUndoGrouping()
            for mark in selectedRegion.marks {
                undoablyDeleteMark(mark: mark)
            }
            currentDocument?.undoManager?.endUndoGrouping()
            hideCursorAndNormalizeAllMarks()
            cursorViewDelegate.refresh()
            setNeedsDisplay()
        }
    }

    func selectedRegion() -> Region? {
        let selectedRegions = ladder.allRegionsWithMode(.selected)
        // assume only one selected region
        guard selectedRegions.count > 0 else { return nil }
        if let region = selectedRegions.first {
            return region
        } else {
            return nil
        }
    }

    func selectedLabelRegion() -> Region? {
        let selectedRegions = ladder.allRegionsWithMode(.labelSelected)
        // assume only one selected region
        guard selectedRegions.count > 0 else { return nil }
        if let region = selectedRegions.first {
            return region
        } else {
            return nil
        }
    }

    @objc func deleteAllInLadder() {
        os_log("deleteAllInLadder() - LadderView", log: OSLog.debugging, type: .debug)
        currentDocument?.undoManager?.beginUndoGrouping()
        for region in ladder.regions {
            for mark in region.marks {
                undoablyDeleteMark(mark: mark)
            }
        }
        currentDocument?.undoManager?.endUndoGrouping()
        hideCursorAndNormalizeAllMarks()
        cursorViewDelegate.refresh()
        setNeedsDisplay()
    }

    @objc func unlinkSelectedMarks() {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarks.forEach { mark in unlinkMarks(mark: mark) }
    }

    func unlinkAllMarks() {
        ladder.unlinkAllMarks()
    }

    func linkAllMarks() {
        // scan all marks, link them if possible
    }

    func unlinkMarks(mark: Mark) {
        normalizeAllMarks()
        mark.linkedMarkIDs = LinkedMarkIDs()
    }

    func soleSelectedMark() -> Mark? {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        if selectedMarks.count == 1 {
            return selectedMarks.first
        }
        return nil
    }

    // FIXME: cursor malpositioned after straightening.
    func straightenToEndpoint(_ endpoint: Mark.Endpoint) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        currentDocument?.undoManager.beginUndoGrouping()
        selectedMarks.forEach { mark in
            let originalSegment = mark.segment
            currentDocument?.undoManager.registerUndo(withTarget: self, handler: { target in
                self.setSegment(segment: originalSegment, forMark: mark)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            let segment: Segment
            switch endpoint {
            case .proximal:
                segment = Segment(proximal: mark.segment.proximal, distal: CGPoint(x: mark.segment.proximal.x, y: mark.segment.distal.y))
            case .distal:
                segment = Segment(proximal: CGPoint(x: mark.segment.distal.x, y: mark.segment.proximal.y), distal: mark.segment.distal)
            case .none:
                fatalError("Endpoint.none inappopriately passed to straightenToEndPoint()")
            }
            self.setSegment(segment: segment, forMark: mark)
        }
        currentDocument?.undoManager.endUndoGrouping()
    }

    func adjustY(_ value: CGFloat, endpoint: Mark.Endpoint, adjustment: Adjustment) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarks.forEach { mark in
            let originalSegment = mark.segment
            currentDocument?.undoManager.registerUndo(withTarget: self, handler: { target in
                self.setSegment(segment: originalSegment, forMark: mark)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            let segment: Segment
            switch adjustment {
            case .trim:
                if endpoint == .proximal {
                    segment = Segment(proximal: CGPoint(x: Geometry.evaluateX(knowingY: value, fromSegment: mark.segment), y: value), distal: mark.segment.distal)
                } else {
                    segment = Segment(proximal: mark.segment.proximal, distal: CGPoint(x: Geometry.evaluateX(knowingY: value, fromSegment: mark.segment), y: value))
                }
            case .adjust:
                if endpoint == .proximal {
                    segment = Segment(proximal: CGPoint(x: mark.segment.proximal.x, y: value), distal: mark.segment.distal)
                } else {
                    segment = Segment(proximal: mark.segment.proximal, distal: CGPoint(x: mark.segment.distal.x, y: value))
                }
            }
            setSegment(segment: segment, forMark: mark)
        }
    }

    func slantSelectedMarks(angle: CGFloat, endpoint: Mark.Endpoint) {
        let selectedMarks = ladder.allMarksWithMode(.selected)
        selectedMarks.forEach { mark in
            let originalSegment = mark.segment
            currentDocument?.undoManager.registerUndo(withTarget: self, handler: { target in
                self.setSegment(segment: originalSegment, forMark: mark)
            })
            NotificationCenter.default.post(name: .didUndoableAction, object: nil)
            slantMark(angle: angle, mark: mark, endpoint: endpoint)
        }
    }

    func slantMark(angle: CGFloat, mark: Mark, endpoint: Mark.Endpoint = .proximal) {
        let region = ladder.region(ofMark: mark)
        let segment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        let height = segment.distal.y - segment.proximal.y
        let delta = Geometry.rightTriangleBase(withAngle: angle, height: height)
        // We add delta to proximal x, not distal x, because we always start with a vertical mark.
        let newSegment: Segment
        switch endpoint {
        case .proximal:
            newSegment = Segment(proximal: segment.proximal, distal: CGPoint(x: segment.proximal.x + delta, y: segment.distal.y))
        case .distal:
            newSegment = Segment(proximal: CGPoint(x: segment.distal.x + delta, y: segment.proximal.y), distal: segment.distal)
        case .none:
            fatalError("Endpoint.none inappopriately passed to slantMark()")
        }
        mark.segment = transformToRegionSegment(scaledViewSegment: newSegment, region: region)
    }

    func slantAngle(mark: Mark, endpoint: Mark.Endpoint) -> CGFloat { 
        let region = ladder.region(ofMark: mark)
        let segment = transformToScaledViewSegment(regionSegment: mark.segment, region: region)
        if endpoint == .proximal {
            return Geometry.oppositeAngle(p1: segment.proximal, p2: segment.distal)
        }
        return  Geometry.oppositeAngle(p1: segment.distal, p2: segment.proximal)
    }

    private func setSegment(segment: Segment, forMark mark: Mark) {
        let originalSegment = mark.segment
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setSegment(segment: originalSegment, forMark: mark)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        mark.segment = segment
    }

    func undoablySetLabel(_ label: String, description: String, forRegion region: Region) {
        let originalName = region.name
        let originalDescription = region.longDescription
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablySetLabel(originalName, description: originalDescription, forRegion: region)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        region.name = label
        region.longDescription = description
        setNeedsDisplay()
    }

    // TODO: skeleton for add/remove region
    // region = new region to add.  Index is where to add.  E.g.
    // 0 is before first region, shift other regions forward by 1
    // If N is last region index, add to N + 1, as long as N + 1 < max number of regions.
    // So need to calculate index before calling, and make sure it is legit.
    func undoablyAddRegion(_ region: Region, atIndex index: Int) {
        let originalRegion = region
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablyRemoveRegion(originalRegion)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        ladder.regions.insert(region, at: index)
        initializeRegions()

        // TODO: reindexing needed?
        //        ladderView.ladder.clearLinkedMarks
        //        ladderView.ladder.linkMarks
        // TODO: need relink mark function
        ladder.reindexMarks()
        // also need to regroup marks
        setNeedsDisplay()
    }

    func undoablyRemoveRegion(_ region: Region) {
        assert(ladder.regions.count > Ladder.minRegionCount)
        let originalRegion = region
        let index = ladder.index(ofRegion: originalRegion)!
        currentDocument?.undoManager.registerUndo(withTarget: self) { target in
            target.undoablyAddRegion(region, atIndex: index)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        ladder.removeRegion(region)
        initializeRegions()
        setNeedsDisplay()
    }

    func addRegion(relation: RegionRelation) {
        guard ladder.regions.count < Ladder.maxRegionCount else { return }
        guard relation == .after || relation == .before else { return }
        guard let selectedRegion = selectedLabelRegion() else { return }
        guard var selectedIndex = ladder.index(ofRegion: selectedRegion) else { return }
        if relation == .after {
            selectedIndex += 1
        }
        var selectedRegionTemplate = selectedRegion.regionTemplate()
        selectedRegionTemplate.name = ""
        selectedRegionTemplate.description = ""
        let newRegion = Region(template: selectedRegionTemplate)
        undoablyAddRegion(newRegion, atIndex: selectedIndex)
    }

    func removeRegion() {
        // Can't remove last region
        guard ladder.regions.count > Ladder.minRegionCount else { return }
        guard let selectedRegion = selectedLabelRegion() else { return }
        undoablyRemoveRegion(selectedRegion)
    }

    func setRegionHeight(_ height: Int, forRegion region: Region) {
        let originalRegion = region
        let originalHeight = region.unitHeight
        currentDocument?.undoManager.registerUndo(withTarget: self) {target in
            target.setRegionHeight(originalHeight, forRegion: originalRegion)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        region.unitHeight = height
        initializeRegions()
        setNeedsDisplay()
    }
}

// MARK: - LadderViewDelegate protocol

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
    func deleteAttachedMark()
    func linkMarksNearbyAttachedMark()
    func addAttachedMark(scaledViewPositionX: CGFloat)
    func unattachAttachedMark()
    func linkNearbyMarks(mark: Mark)
    func moveAttachedMark(position: CGPoint)
    func fixBoundsOfAttachedMark()
    func attachedMarkAnchor() -> Anchor?
    func assessBlockAndImpulseOrigin(mark: Mark?)
    func getAttachedMarkScaledAnchorPosition() -> CGPoint?
    func setAttachedMarkAndLinkedMarksModes()
    func toggleAttachedMarkAnchor()
    func convertPosition(_: CGPoint, toView: UIView) -> CGPoint

}

// MARK: LadderViewDelegate implementation

extension LadderView: LadderViewDelegate {

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionProximalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: activeRegion?.proximalBoundary ?? 0)
        return convert(position, to: view).y
    }

    func getAttachedMarkLadderViewPositionY(view: UIView) -> CGPoint? {
        guard let position = anchorLadderViewPosition(ofMark: ladder.attachedMark) else {
            return nil
        }
        return convert(position, to: view)
    }

    func anchorRegionPosition(ofMark mark: Mark) -> CGPoint {
        let anchor = mark.anchor
        let anchorPosition: CGPoint
        switch anchor {
        case .proximal:
            anchorPosition = mark.segment.proximal
        case .middle:
            anchorPosition = mark.midpoint()
        case .distal:
            anchorPosition = mark.segment.distal
        }
        return anchorPosition
    }

    func anchorLadderViewPosition(ofMark mark: Mark?) -> CGPoint? {
        guard let mark = mark else { return nil }
        let region = ladder.region(ofMark: mark)
        var anchorPosition = anchorRegionPosition(ofMark: mark)
        anchorPosition = transformToScaledViewPosition(regionPosition: anchorPosition, region: region)
        return anchorPosition
    }

    func getTopOfLadder(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: ladder.regions[0].proximalBoundary)
        return convert(position, to: view).y
    }

    func convertPosition(_ position: CGPoint, toView view: UIView) -> CGPoint {
        return convert(position, to: view)
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
        setNeedsDisplay()
    }

    func setActiveRegion(regionNum: Int) {
        activeRegion = ladder.region(atIndex: regionNum)
    }

    func hasActiveRegion() -> Bool {
        return activeRegion != nil
    }

    func addAttachedMark(scaledViewPositionX positionX: CGFloat) {
        ladder.attachedMark = ladder.addMark(at: positionX / scale, toRegion: activeRegion)
        if let attachedMark = ladder.attachedMark {
            undoablyAddMark(mark: attachedMark)
            attachedMark.mode = .attached
        }
    }

    func linkMarksNearbyAttachedMark() {
        guard let attachedMark = ladder.attachedMark else { return }
        // FIXME: out of place
        swapEndsIfNeeded(mark: attachedMark)
        linkNearbyMarks(mark: attachedMark)
        addlinkedMiddleMarks(ofMark: attachedMark)
    }

    func undoablySnapMarkToNearbyMarks(mark: Mark, nearbyMarks: LinkedMarks) {
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.redoablyUnsnapMarkFromNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        snapMarkToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
    }

    func redoablyUnsnapMarkFromNearbyMarks(mark: Mark, nearbyMarks: LinkedMarks) {
        currentDocument?.undoManager?.registerUndo(withTarget: self) { target in
            target.undoablySnapMarkToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
        }
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        unsnapMarkFromNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
    }

    func unsnapMarkFromNearbyMarks(mark: Mark, nearbyMarks: LinkedMarks) {
        os_log("unsnapMarkFromNearbyMarks(mark:nearbyMarks:))", log: .action, type: .info)
        guard snapMarks else { return }
        for proxMark in nearbyMarks.proximal {
            mark.linkedMarkIDs.proximal.remove(proxMark.id)
            proxMark.linkedMarkIDs.distal.remove(mark.id)
        }
        for distalMark in nearbyMarks.distal {
            mark.linkedMarkIDs.distal.remove(distalMark.id)
            distalMark.linkedMarkIDs.proximal.remove(mark.id)
        }
        for middleMark in nearbyMarks.middle {
            mark.linkedMarkIDs.middle.remove(middleMark.id)
            middleMark.linkedMarkIDs.middle.remove(mark.id)
        }
    }

    // Adjust ends of marks to connect after dragging.
    func snapMarkToNearbyMarks(mark: Mark, nearbyMarks: LinkedMarks) {
        os_log("SnapMarkToNearbyMarks(mark:nearbyMarks:))", log: .action, type: .info)
        guard snapMarks else { return }
        for proxMark in nearbyMarks.proximal {
            mark.linkedMarkIDs.proximal.insert(proxMark.id)
            proxMark.linkedMarkIDs.distal.insert(mark.id)
            mark.segment.proximal.x = proxMark.segment.distal.x
            if mark.anchor == .proximal {
                cursorViewDelegate.moveCursor(cursorViewPositionX: mark.segment.proximal.x)
            }
            else if mark.anchor == .middle {
                cursorViewDelegate.moveCursor(cursorViewPositionX: mark.midpoint().x)
            }
        }
        for distalMark in nearbyMarks.distal {
            mark.linkedMarkIDs.distal.insert(distalMark.id)
            distalMark.linkedMarkIDs.proximal.insert(mark.id)
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
            mark.linkedMarkIDs.middle.insert(middleMark.id)
            middleMark.linkedMarkIDs.middle.insert(mark.id)
            var distanceToProximal = Geometry.distanceSegmentToPoint(segment: middleMark.segment, point: mark.segment.proximal)
            distanceToProximal = min(distanceToProximal, Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.proximal))
            var distanceToDistal = Geometry.distanceSegmentToPoint(segment: middleMark.segment, point: mark.segment.distal)
            distanceToDistal = min(distanceToDistal, Geometry.distanceSegmentToPoint(segment: mark.segment, point: middleMark.segment.distal))
            if distanceToProximal < distanceToDistal {
                let x = middleMark.segment.getX(fromY: mark.segment.proximal.y)
                if let x = x {
                    mark.segment.proximal.x = x
                }
                // FIXME: This causes unexpected straightening of mark
                // Should not link vertical marks.  Handle in assessCloseness.50
                else { // vertical mark
                    //                    mark.segment.proximal.x = middleMark.segment.proximal.x
                    //                    mark.segment.distal.x = middleMark.segment.proximal.x
                }
            }
            else {
                let x = middleMark.segment.getX(fromY: mark.segment.distal.y)
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

    func reregisterAllMarks() {
        ladder.reregisterAllMarks()
    }

    func linkNearbyMarks(mark: Mark) {
        os_log("linkNearbyMarks(mark:) - LadderView", log: .action, type: .info)
        guard snapMarks else { return }
        let minimum: CGFloat = nearbyMarkAccuracy / scale
        let markIds = nearbyMarkIds(mark: mark, nearbyDistance: minimum)
        let nearbyMarks = ladder.getLinkedMarks(fromLinkedMarkIDs: markIds)
        undoablySnapMarkToNearbyMarks(mark: mark, nearbyMarks: nearbyMarks)
    }

    // FIXME: this should add all linked middle marks together, but doesn't seem to work.
    func addlinkedMiddleMarks(ofMark mark: Mark) {
        var middleMarkIds = mark.linkedMarkIDs.middle
        for id in middleMarkIds {
            if let middleSet = ladder.lookup(id: id)?.linkedMarkIDs.middle {
                middleMarkIds = middleMarkIds.union(middleSet)
            }
        }
        mark.linkedMarkIDs.middle = middleMarkIds
    }

    func getPositionYInView(positionY: CGFloat, view: UIView) -> CGFloat {
        let point = CGPoint(x: 0, y: positionY)
        return convert(point, to: view).y
    }

    func getAttachedMarkScaledAnchorPosition() -> CGPoint? {
        return getMarkScaledAnchorPosition(ladder.attachedMark)
    }

    func getMarkScaledAnchorPosition(_ mark: Mark?) -> CGPoint? {
        guard let mark = mark, let activeRegion = activeRegion else { return nil}
        return transformToScaledViewPosition(regionPosition: mark.getAnchorPosition(), region: activeRegion)
    }

    func attachedMarkAnchor() -> Anchor? {
        guard let attachedMark = ladder.attachedMark else { return nil }
        return attachedMark.anchor
    }

    func unattachAttachedMark() {
        assessBlockAndImpulseOrigin(mark: ladder.attachedMark)
        ladder.attachedMark?.mode = .normal
        ladder.attachedMark = nil
    }

    func deleteAttachedMark() {
        os_log("deleteAttachedMark() - LadderView", log: OSLog.debugging, type: .debug)
        if let mark = ladder.attachedMark {
            undoablyDeleteMark(mark: mark)
        }
    }

    func toggleAttachedMarkAnchor() {
        toggleAnchor(mark: ladder.attachedMark)
        if let attachedMark = ladder.attachedMark {
            adjustCursor(mark: attachedMark)
        }
    }

    func saveState() {
        os_log("saveState() - LadderView", log: .default, type: .default)
        savedActiveRegion = activeRegion
        if mode == .normal {
            activeRegion = nil
        }
        savedMode = mode
    }

    @discardableResult func restoreState() -> Mode {
        os_log("restoreState() - LadderView", log: .default, type: .default)
        mode = savedMode
        if mode == .normal {
            activeRegion = savedActiveRegion
        }
        return mode
    }
}

// MARK: - enums

enum TextVisibility: Int, Codable {
    case visibility
    case invisible
    case visibleIfFits
}

enum Adjustment {
    case adjust
    case trim
}


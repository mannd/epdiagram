//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderViewDelegate: AnyObject {
    func makeMark(positionX: CGFloat) -> Mark?
    func deleteMark(mark: Mark, region: Region?)
    func deleteMark(mark: Mark)
    func getRegionProximalBoundary(view: UIView) -> CGFloat
    func getRegionDistalBoundary(view: UIView) -> CGFloat
    func getRegionMidPoint(view: UIView) -> CGFloat
    func moveMark(mark: Mark, position: CGPoint, moveCursor: Bool)
    func refresh()
    func findMarkNearby(positionX: CGFloat) -> Mark?
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
    func getHeight() -> CGFloat
    func getTopOfLadder(view: UIView) -> CGFloat
}

// FIXME: Proof of concept on how to use new context menu.  Will need to
// adjust menu depending on what was pressed.  Nice alternative to old-fashioned
// menus in iOS.
@available(iOS 13.0, *)
extension LadderView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let markFound = getLocationInLadder(position: location, ladderViewModel: ladderViewModel).markWasTapped
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in

            let solid = UIAction(title: L("Solid")) { action in
                let locationInLadder = self.getLocationInLadder(position: location, ladderViewModel: self.ladderViewModel)
                if let mark = locationInLadder.mark {
                    self.pressedMark = mark
                    self.setSolid()
                }
            }

            let dashed = UIAction(title: L("Dashed")) { action in
                let locationInLadder = self.getLocationInLadder(position: location, ladderViewModel: self.ladderViewModel)
                if let mark = locationInLadder.mark {
                    self.pressedMark = mark
                    self.setDashed()
                }
            }

            let dotted = UIAction(title: L("Dotted")) { action in
                let locationInLadder = self.getLocationInLadder(position: location, ladderViewModel: self.ladderViewModel)
                if let mark = locationInLadder.mark {
                    self.pressedMark = mark
                    self.setDotted()
                }
            }

            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])

            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                let locationInLadder = self.getLocationInLadder(position: location, ladderViewModel: self.ladderViewModel)
                if let mark = locationInLadder.mark {
                    self.deleteMark(mark: mark)
                }
            }

            // Create and return a UIMenu with all of the actions as children
            if markFound {
                return UIMenu(title: L("Edit mark"), children: [style, delete])
            }
            else {
                return UIMenu(title: "", children: [delete])
            }
        }
    }}

// TODO: Marks only know absolute positioning (not affected by offset or scale and with
// y position between 0 and 1.0), but need to seemless convert all screen positions
// so that LadderView never has to worry about the raw Mark level.  Perhaps need a
// MarkViewModel class for this.
// OR: Maybe Mark should just handle this.
class LadderView: UIView, LadderViewDelegate {

    /// Struct that pinpoints a point in a ladder.  Note that these tapped areas overlap (labels and marks are in regions).
    struct LocationInLadder {
        var region: Region?
        var mark: Mark?
        var regionSection: RegionSection
        var regionDivision: RegionDivision
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


    var pressedMark: Mark? = nil
    var movingMark: Mark? = nil
    var regionOfDragOrigin: Region? = nil

    // These are passed from the viewController, and in turn passed to the ladderViewModel
    var leftMargin: CGFloat = 0 {
        didSet {
            ladderViewModel.margin = leftMargin
        }
    }
    var offset: CGFloat = 0 {
        didSet {
            ladderViewModel.offset = offset
        }
    }
    var scale: CGFloat = 1 {
        didSet {
            ladderViewModel.scale = scale
        }
    }

    // FIXME: Take out viewController if we don't use it for UIAlertControllers.
    // LadderView needs a weak copy of the calling VC in order to display UIAlertControllers.
    weak var viewController: ViewController? = nil
    weak var cursorViewDelegate: CursorViewDelegate?
    var ladderViewModel: LadderViewModel

    // How close a touch has to be to count: +/- accuracy.
    let accuracy: CGFloat = 20

    required init?(coder aDecoder: NSCoder) {
        P("ladderView init")

        ladderViewModel = LadderViewModel()
        super.init(coder: aDecoder)
        ladderViewModel.height = self.frame.height
        ladderViewModel.initialize()

        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.systemBlue.cgColor
        self.layer.borderWidth = 2

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


    // Touches
    fileprivate func labelWasTapped(_ tapLocationInLadder: LadderView.LocationInLadder) {
        if let tappedRegion = tapLocationInLadder.region {
            if tappedRegion.selected {
                tappedRegion.selected = false
                ladderViewModel.activeRegion = nil
            }
            else { // !tappedRegion.selected
                ladderViewModel.activeRegion = tappedRegion
                cursorViewDelegate?.hideCursor(hide: true)
            }
            cursorViewDelegate?.hideCursor(hide: true)
            cursorViewDelegate?.unattachMark()
        }
    }

    fileprivate func markWasTapped(mark: Mark, _ tapLocationInLadder: LadderView.LocationInLadder) {
        if mark.attached {
            // FIXME: attached and selected maybe the same thing, eliminate duplication.
            let anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
            P(">>>>>Mark location = \(anchor)")
            // Just reanchor cursor
            if anchor != mark.anchor {
                mark.anchor = anchor
            }
            else {
                // Unattach mark and hide cursor
                P("Unattaching mark")
                mark.attached = false
                mark.highlight = .none
                unselectMark(mark)
                cursorViewDelegate?.hideCursor(hide: true)
                cursorViewDelegate?.unattachMark()
            }
        }
        else {
            P("Attaching mark")
            mark.attached = true
            mark.anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
            selectMark(mark)
            cursorViewDelegate?.attachMark(mark: mark)
            let anchorPositionX = getAnchorPositionX(mark: mark)
            cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
            cursorViewDelegate?.hideCursor(hide: false)
        }
    }

    fileprivate func regionWasTapped(_ tapLocationInLadder: LadderView.LocationInLadder, _ tap: UITapGestureRecognizer) {
        if let tappedRegion = tapLocationInLadder.region {
            if !tappedRegion.selected {
                ladderViewModel.activeRegion = tappedRegion
            }
            if let mark = tapLocationInLadder.mark {
                markWasTapped(mark: mark, tapLocationInLadder)
            }
            else { // make mark and attach cursor
                P("make mark and attach cursor")
                let mark = makeMark(positionX: tap.location(in: self).x)
                if let mark = mark {
                    ladderViewModel.inactivateMarks()
                    mark.attached = true
                    mark.anchor = getAnchor(regionDivision: tapLocationInLadder.regionDivision)
                    selectMark(mark)
                    cursorViewDelegate?.attachMark(mark: mark)
                    cursorViewDelegate?.moveCursor(positionX: mark.position.proximal.x)
                    cursorViewDelegate?.hideCursor(hide: false)
                }
            }
        }
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        P("LadderView.singleTap()")
        let tapLocationInLadder = getLocationInLadder(position: tap.location(in: self), ladderViewModel: ladderViewModel)
        if tapLocationInLadder.labelWasTapped {
            labelWasTapped(tapLocationInLadder)
        }
        else if (tapLocationInLadder.regionWasTapped) {
            regionWasTapped(tapLocationInLadder, tap)
        }
        setNeedsDisplay()
        cursorViewDelegate?.refresh()
    }

    func markMidpoint(mark: Mark) -> CGFloat {
        return (mark.position.distal.x - mark.position.proximal.x) / 2.0 + mark.position.proximal.x
    }

    fileprivate func getAnchor(regionDivision: RegionDivision) -> Anchor {
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

    fileprivate func selectMark(_ mark: Mark) {
        mark.highlight = .all
    }

    fileprivate func unselectMark(_ mark: Mark) {
        mark.highlight = .none
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        P("Double tap on ladder view")
        // delete mark
        let tapLocationInLadder = getLocationInLadder(position: tap.location(in: self), ladderViewModel: ladderViewModel)
        if tapLocationInLadder.markWasTapped {
            if let mark = tapLocationInLadder.mark {
                let region = tapLocationInLadder.region
                deleteMark(mark: mark, region: region)
                cursorViewDelegate?.hideCursor(hide: true)
            }
        }
    }

    // See below.  We get relative points for relevent regions and return them in an dictionary
    /*
     Need proximalRegion?, distalRegion?
     for each mark in proximal region, get mark and distal relative location
     for each mark in distal region, get mark and proximal relative location
     get moving mark compare proximal relative location with 1st set above and compare distal location with
     2nd set above.
     If either location is + or - connectionAccuracy value, then highlight and snap moving mark to the
     immovable mark above or below.
     If drag ends, connect the marks.
     */


    // TODO: Need some connection logic here.  If the proximal end of the mark or the distal end of
    // the mark, or both, brush a makr in a region proximal or distal to it, it becomes "potentiallyConnected."
    // This means the two marks are highlighted, and if the drag ends there, the marks become connected, (and
    // snap into position if there is a gap between them, favoring the position of A and V over AV, i.e. over
    // a conduction region) with some animation or coloration to show this.
    // Connected marks move together.  Long press is needed to disconnect the marks.

    // To do this, we need an array of proximal relative points and distal relative points.  So we need
    // the marks of the region proximal and region distal (if they exist).  From these marks, we need the
    // distal points of the proximal region's marks, and the proximal points of the distal region's marks.
    // We also need any connected marks to make sure we move them to (i.e. update their positions).
    @objc func dragging(pan: UIPanGestureRecognizer) {
        P("Dragging on ladder view")
        if pan.state == .began {
            P("dragging began")
            let locationInLadder = getLocationInLadder(position: pan.location(in: self), ladderViewModel: ladderViewModel)
            if let mark = locationInLadder.mark {
                movingMark = mark
                if let region = locationInLadder.region {
                    regionOfDragOrigin = region
                }
            }
        }
        if pan.state == .changed {
            P("dragging state changed")
            if let mark = movingMark {
                if mark.attached {
                    moveMark(mark: mark, position: pan.location(in: self), moveCursor: true)
                }
                else {
                    P("dragging mark without cursor.")
                    let locationInLadder = getLocationInLadder(position: pan.location(in: self), ladderViewModel: ladderViewModel)
                    if let region = locationInLadder.region {
                        let regionName = region.name
                        let originalRegionName = regionOfDragOrigin?.name
                        P("Region of origin = \(String(describing: originalRegionName))")
                        P("Region dragged into = \(regionName)")
                        /* Logic here:
                         drag started near a mark
                         mark has no attached cursor
                         drag enters region different from region of origin
                         region is conduction region
                         drag is in the forward time direction (at least not negative!)
                         THEN
                         Add connection to mark
                         Draw line from end of mark to drag point
                         ON pan.state.ended
                         if near next region (non conducting)
                         attach to mark nearby otherwise create mark
                         BUT if in middle of region
                         offer popup menu with choices

                         More logic
                         single tap in conduction region create ectopic with two connections
                         drag on these connections to connect
                         flash mark about to be connected or created
                         double tap on connector to delete it
                         double tap on mark deletes its connectors too


                         */
                    }
                }
                setNeedsDisplay()
            }
        }
        if pan.state == .ended {
            P("dragging state ended")
            movingMark = nil
            regionOfDragOrigin = nil
        }
    }

    fileprivate func longPressMarkOldOS(_ position: CGPoint) {
        // TODO: internationalize
        // Note: it doesn't look like you can add a submenu to a UIMenuController like
        // you can do with context menus available in iOS 13.
        let solidMenuItem = UIMenuItem(title: "Solid", action: #selector(setSolid))
        let dashedMenuItem = UIMenuItem(title: "Dashed", action: #selector(setDashed))
        let dottedMenuItem = UIMenuItem(title: "Dotted", action: #selector(setDotted))
        let deleteMenuItem = UIMenuItem(title: "Delete", action: #selector(deletePressedMark))
        UIMenuController.shared.menuItems = [solidMenuItem, dashedMenuItem, dottedMenuItem, deleteMenuItem]
        let rect = CGRect(x: position.x, y: position.y, width: 0, height: 0)
        if #available(iOS 13.0, *) {
            UIMenuController.shared.showMenu(from: self, rect: rect)
        } else {
            UIMenuController.shared.setTargetRect(rect, in: self)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        self.becomeFirstResponder()
        let locationInLadder = getLocationInLadder(position: press.location(in: self), ladderViewModel: ladderViewModel)
        P("long press at \(locationInLadder) ")
        if let mark = locationInLadder.mark {
            P("you pressed a mark")
            pressedMark = mark
            let position = press.location(in: self)
            if #available(iOS 13.0, *) {
                // use LadderView extensions
            }
            else {
                longPressMarkOldOS(position)
            }
        }
    }

    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }

    @objc func setSolid() {
        if let pressedMark = pressedMark {
            pressedMark.lineStyle = .solid
        }
        pressedMark = nil
        setNeedsDisplay()
    }

    @objc func setDashed() {
        if let pressedMark = pressedMark {
            pressedMark.lineStyle = .dashed
        }
        pressedMark = nil
        setNeedsDisplay()
    }

    @objc func setDotted() {
        if let pressedMark = pressedMark {
            pressedMark.lineStyle = .dotted
        }
        pressedMark = nil
        setNeedsDisplay()
    }

    /// Magic function that returns struct indicating in what part of ladder a point is.
    /// - Parameter position: point to be processed
    /// - Parameter ladderViewModel: ladderViewModel in use
    func getLocationInLadder(position: CGPoint, ladderViewModel: LadderViewModel) -> LocationInLadder {
        var tappedRegion: Region?
        var tappedMark: Mark?
        var tappedRegionSection: RegionSection = .markSection
        var tappedRegionDivision: RegionDivision = .none
        for region in ladderViewModel.regions {
            if position.y > region.proximalBoundary && position.y < region.distalBoundary {
                tappedRegion = region
                tappedRegionDivision = getTappedRegionDivision(region: region, positionY: position.y)
                P("tappedRegionDivision = \(tappedRegionDivision)")
            }
        }
        if let tappedRegion = tappedRegion {
            if position.x < leftMargin {
                tappedRegionSection = .labelSection
            }
            else {
                tappedRegionSection = .markSection
                outerLoop: for mark in tappedRegion.marks {
                    if nearMark(positionX: position.x, mark: mark) {
                        P("tap near mark")
                        tappedMark = mark
                        break outerLoop
                    }
                }
            }
        }
        return LocationInLadder(region: tappedRegion, mark: tappedMark, regionSection: tappedRegionSection, regionDivision: tappedRegionDivision)
    }

    private func nearMark(positionX: CGFloat, mark: Mark) -> Bool {
        return ladderViewModel.nearMark(positionX: positionX, mark: mark, accuracy: accuracy)
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

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        P("LadderView draw()")
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel.draw(rect: rect, context: context)
        }
    }

    func resetSize() {
        ladderViewModel.height = self.frame.height
        ladderViewModel.reinit()
    }

    // MARK: - LadderView delegate methods
    // convert region upper boundary to view's coordinates and return to view
    func getRegionProximalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: ladderViewModel.activeRegion?.proximalBoundary ?? 0)
        return convert(position, to: view).y
    }

    func getTopOfLadder(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: ladderViewModel.regions[0].proximalBoundary)
        return convert(position, to: view).y
    }

    func getRegionMidPoint(view: UIView) -> CGFloat {
        guard let activeRegion = ladderViewModel.activeRegion else { return 0 }
        let position = CGPoint(x: 0, y: (activeRegion.distalBoundary -  activeRegion.proximalBoundary) / 2 + activeRegion.proximalBoundary)
        return convert(position, to: view).y
    }

    func getRegionDistalBoundary(view: UIView) -> CGFloat {
        let position = CGPoint(x: 0, y: ladderViewModel.activeRegion?.distalBoundary ?? 0)
        return convert(position, to: view).y
    }

    func getHeight() -> CGFloat {
        return ladderViewModel.height
    }

    func makeMark(positionX: CGFloat) -> Mark? {
        return ladderViewModel.makeMark(positionX: positionX)
    }

    func addMark(positionX: CGFloat) -> Mark? {
        return ladderViewModel.addMark(positionX: positionX)
    }

    private func unscaledPositionX(positionX: CGFloat) -> CGFloat {
        return positionX / scale
    }

    func deleteMark(mark: Mark, region: Region?) {
        P("Delete mark \(mark)")
        ladderViewModel.deleteMark(mark: mark, region: region)
        cursorViewDelegate?.hideCursor(hide: true)
        cursorViewDelegate?.refresh()
        setNeedsDisplay()
    }

    func deleteMark(mark: Mark) {
        ladderViewModel.deleteMark(mark: mark)
        cursorViewDelegate?.hideCursor(hide: true)
        cursorViewDelegate?.refresh()
        setNeedsDisplay()
    }

    @objc func deletePressedMark() {
        if let pressedMark = pressedMark {
            deleteMark(mark: pressedMark)
        }
    }

    func refresh() {
        cursorViewDelegate?.refresh()
        setNeedsDisplay()
    }

    func moveMark(mark: Mark, position: CGPoint, moveCursor: Bool) {
        ladderViewModel.moveMark(mark: mark, relativePositionX: position.x)
        if moveCursor {
            let anchorPositionX = getAnchorPositionX(mark: mark)
            cursorViewDelegate?.moveCursor(positionX: anchorPositionX)
            cursorViewDelegate?.refresh()
        }
    }

    func getAnchorPositionX(mark: Mark) -> CGFloat {
        let anchorPositionX: CGFloat
        switch mark.anchor {
        case .distal:
            anchorPositionX = mark.position.distal.x
        case .middle:
            anchorPositionX = mark.midpoint().x
        case .proximal:
            anchorPositionX = mark.position.proximal.x
        case .none:
            anchorPositionX = mark.position.proximal.x
        }
        return anchorPositionX

    }

    // FIXME: Not called by anyone.  Redundant with nearMark()?
    func findMarkNearby(positionX: CGFloat) -> Mark? {
        return ladderViewModel.findMarkNearby(positionX: positionX, accuracy: accuracy)
    }

    func setActiveRegion(regionNum: Int) {
        ladderViewModel.activeRegion = ladderViewModel.regions[regionNum]
        ladderViewModel.activeRegion?.selected = true
    }

    func hasActiveRegion() -> Bool {
        return ladderViewModel.activeRegion != nil
    }
}

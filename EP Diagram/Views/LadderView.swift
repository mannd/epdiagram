//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol LadderViewDelegate: AnyObject {
    func getRegionProximalBoundary(view: UIView) -> CGFloat
    func getRegionDistalBoundary(view: UIView) -> CGFloat
    func getRegionMidPoint(view: UIView) -> CGFloat
    func refresh()
    func setActiveRegion(regionNum: Int)
    func hasActiveRegion() -> Bool
    func getHeight() -> CGFloat
    func getTopOfLadder(view: UIView) -> CGFloat
    func getViewModel() -> LadderViewModel
}

@available(iOS 13.0, *)
extension LadderView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        let markFound = ladderViewModel.markWasTapped(position: location)
        ladderViewModel.setPressedMark(position: location)
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let solid = UIAction(title: L("Solid")) { action in
                self.setSolid()
            }
            let dashed = UIAction(title: L("Dashed")) { action in
                self.setDashed()
            }
            let dotted = UIAction(title: L("Dotted")) { action in
                self.setDotted()
            }
            let style = UIMenu(title: L("Style..."), children: [solid, dashed, dotted])
            // Use .displayInline option to show menu inline with separator.
//           let style = UIMenu(title: L("Style..."), options: .displayInline,  children: [solid, dashed, dotted])
            let unlink = UIAction(title: L("Unlink")) { action in
                self.ladderViewModel.unlinkPressedMark()
            }
            let delete = UIAction(title: L("Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { action in
                self.deletePressedMark()
            }
            // Create and return a UIMenu with all of the actions as children
            if markFound {
                return UIMenu(title: L("Edit mark"), children: [style, unlink, delete])
            }
            else {
                return UIMenu(title: "", children: [delete])
            }
        }
    }}

class LadderView: UIView, LadderViewDelegate {
    weak var cursorViewDelegate: CursorViewDelegate?
    var ladderViewModel = LadderViewModel()

    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
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

    // How close a touch has to be to count: +/- accuracy.
    let accuracy: CGFloat = 20

    // MARK: - init

    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoad()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didLoad()
    }

    fileprivate func didLoad() {
        ladderViewModel.height = self.frame.height
        ladderViewModel.initialize()

        // Draw border around view.
        self.layer.masksToBounds = true
        self.layer.borderColor = UIColor.systemBlue.cgColor
        self.layer.borderWidth = 2

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

    // MARK: - Touches

    @objc func singleTap(tap: UITapGestureRecognizer) {
        ladderViewModel.singleTap(position: tap.location(in: self), cursorViewDelegate: cursorViewDelegate)
        setNeedsDisplay()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        if ladderViewModel.deleteMark(position: tap.location(in: self), cursorViewDelegate: cursorViewDelegate) {
            setNeedsDisplay()
        }
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        if ladderViewModel.dragMark(position: pan.location(in: self), state: pan.state, cursorViewDelegate: cursorViewDelegate) {
            setNeedsDisplay()
        }
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        self.becomeFirstResponder()
        let position = press.location(in: self)
        let locationInLadder = ladderViewModel.getLocationInLadder(position: position)
        P("long press at \(locationInLadder) ")
        if locationInLadder.markWasTapped {
            P("you pressed a mark")
            if #available(iOS 13.0, *) {
                // use LadderView extensions
            }
            else {
                ladderViewModel.setPressedMark(position: position)
                longPressMarkOldOS(position)
            }
        }
    }

    fileprivate func longPressMarkOldOS(_ position: CGPoint) {
        // Note: it doesn't look like you can add a submenu to a UIMenuController like
        // you can do with context menus available in iOS 13.
        let solidMenuItem = UIMenuItem(title: L("Solid"), action: #selector(setSolid))
        let dashedMenuItem = UIMenuItem(title: L("Dashed"), action: #selector(setDashed))
        let dottedMenuItem = UIMenuItem(title: L("Dotted"), action: #selector(setDotted))
        let unlinkMenuItem = UIMenuItem(title: L("Unlink"), action: #selector(unlinkPressedMark))
        let deleteMenuItem = UIMenuItem(title: L("Delete"), action: #selector(deletePressedMark))
        UIMenuController.shared.menuItems = [solidMenuItem, dashedMenuItem, dottedMenuItem, unlinkMenuItem, deleteMenuItem]
        let rect = CGRect(x: position.x, y: position.y, width: 0, height: 0)
        if #available(iOS 13.0, *) {
            UIMenuController.shared.showMenu(from: self, rect: rect)
        } else {
            UIMenuController.shared.setTargetRect(rect, in: self)
            UIMenuController.shared.setMenuVisible(true, animated: true)
        }
    }

    @objc func setSolid() {
        ladderViewModel.setPressedMarkStyle(style: .solid)
        ladderViewModel.nullifyPressedMark()
        setNeedsDisplay()
    }

    @objc func setDashed() {
        ladderViewModel.setPressedMarkStyle(style: .dashed)
        ladderViewModel.nullifyPressedMark()
        setNeedsDisplay()
    }

    @objc func setDotted() {
        ladderViewModel.setPressedMarkStyle(style: .dotted)
        ladderViewModel.nullifyPressedMark()
        setNeedsDisplay()
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

    func addAttachedMark(positionX: CGFloat) {
        ladderViewModel.addAttachedMark(positionX: positionX)
    }

    private func unscaledPositionX(positionX: CGFloat) -> CGFloat {
        return positionX / scale
    }

    @objc func deletePressedMark() {
        ladderViewModel.deletePressedMark()
        cursorViewDelegate?.hideCursor(true)
        refresh()
    }

    @objc func unlinkPressedMark() {
        ladderViewModel.unlinkPressedMark()
    }

    func refresh() {
        cursorViewDelegate?.refresh()
        setNeedsDisplay()
    }

    func setActiveRegion(regionNum: Int) {
        ladderViewModel.setActiveRegion(regionNum: regionNum)
    }

    func hasActiveRegion() -> Bool {
        return ladderViewModel.hasActiveRegion()
    }

    // We expose the underlying view model to avoid exposing elements of the model.
    func getViewModel() -> LadderViewModel {
        return ladderViewModel
    }
}


//
//  CursorView.swift
//  EP Diagram
//
//  Created by David Mann on 5/9/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

protocol CursorViewDelegate: AnyObject {
    func refresh()
    func unattachAttachedMark()
    func moveCursor(positionX: CGFloat)
    func highlightCursor(_ on: Bool)
    func hideCursor(_ hide: Bool)
    func cursorIsVisible() -> Bool
    func getViewModel() -> CursorViewModel
    func view() -> UIView
    func convertPoint(_ point: CGPoint) -> CGPoint
    func setHeight(_ height: CGFloat)
}

class CursorView: UIView {
    var cursorViewModel: CursorViewModel = CursorViewModel()
    weak var ladderViewDelegate: LadderViewDelegate?

    var leftMargin: CGFloat = 0 {
        didSet {
            cursorViewModel.leftMargin = leftMargin
        }
    }
    var scale: CGFloat = 1.0 {
        didSet {
            cursorViewModel.scale = scale
        }
    }
    var offset: CGFloat = 0 {
        didSet {
            cursorViewModel.offsetX = offset
        }
    }

    // How close a tap has to be to a cursor to register.
    let accuracy: CGFloat = 20
    var calibrating = false

    // MARK: - init

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        didLoad()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoad()
    }

    fileprivate func didLoad() {
        // CursorView is mostly transparent, so let iOS know.
        self.isOpaque = false

        // Draw a border around the view.
        self.layer.masksToBounds = true
        if #available(iOS 13.0, *) {
            self.layer.borderColor = UIColor.label.cgColor
        } else {
            self.layer.borderColor = UIColor.black.cgColor
        }
        self.layer.borderWidth = 1

        cursorViewModel = CursorViewModel(leftMargin: leftMargin, width: self.frame.width, height: self.frame.width)

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

    // MARK: - draw

    override func draw(_ rect: CGRect) {
        if let context = UIGraphicsGetCurrentContext() {
            cursorViewModel.height = getCursorHeight(anchor: cursorViewModel.getAttachedMarkAnchor())
            cursorViewModel.draw(rect: rect, context: context, defaultHeight: ladderViewDelegate?.getTopOfLadder(view: self))
        }
    }

    fileprivate func getAnchorY(_ anchor: Anchor, _ ladderViewDelegate: LadderViewDelegate) -> CGFloat {
        let anchorY: CGFloat
        switch anchor {
        case .proximal:
            anchorY = ladderViewDelegate.getRegionProximalBoundary(view: self)
        case .middle:
            anchorY = ladderViewDelegate.getRegionMidPoint(view: self)
        case .distal:
            anchorY = ladderViewDelegate.getRegionDistalBoundary(view: self)
        case .none:
            anchorY = ladderViewDelegate.getHeight()
        }
        return anchorY
    }

    private func getCursorHeight(anchor: Anchor) -> CGFloat {
        guard let ladderViewDelegate = ladderViewDelegate else { return self.frame.height }
        return getAnchorY(anchor, ladderViewDelegate)
    }

    // MARK: - touches

    // This function passes touch events to the views below if the point is not
    // near the cursor.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard cursorViewModel.cursorVisible, let ladderViewDelegate = ladderViewDelegate else { return false }
        if cursorViewModel.isNearCursor(positionX: point.x, accuracy: accuracy) && point.y < ladderViewDelegate.getRegionProximalBoundary(view: self) {
            return true
        }
        return false
    }

    @objc func singleTap(tap: UITapGestureRecognizer) {
        if calibrating {
            doCalibration()
            return
        }
        hideCursor(cursorViewModel.cursorVisible)
        unattachAttachedMark()
        setNeedsDisplay()
    }

    @objc func doubleTap(tap: UITapGestureRecognizer) {
        cursorViewModel.doubleTap(ladderViewDelegate: ladderViewDelegate)
        hideCursor(true)
        setNeedsDisplay()
    }

    @objc func dragging(pan: UIPanGestureRecognizer) {
        if pan.state == .changed {
            let delta = pan.translation(in: self)
            cursorViewModel.cursorMove(delta: delta.x)
            cursorViewModel.dragMark(ladderViewDelegate: ladderViewDelegate, cursorViewDelegate: self)
            pan.setTranslation(CGPoint(x: 0,y: 0), in: self)
        }
        if pan.state == .ended {
            if let attachedMark = cursorViewModel.attachedMark {
                ladderViewDelegate?.getViewModel().linkNearbyMarks(mark: attachedMark)
                ladderViewDelegate?.refresh()
            }
        }
        setNeedsDisplay()
    }

    @objc func longPress(press: UILongPressGestureRecognizer) {
        P("Long press on cursor")
    }

    func doCalibration() {
        P("Do calibration")
    }

    func putCursor(positionX: CGFloat) {
        cursorViewModel.cursorPosition = positionX / scale
        hideCursor(false)
    }
}

extension CursorView: CursorViewDelegate {
    // MARK: - CursorView delegate methods
    func refresh() {
        setNeedsDisplay()
    }

    func attachMark(_ mark: Mark?) {
        cursorViewModel.attachMark(mark)
    }

    func unattachAttachedMark() {
        cursorViewModel.unattachAttachedMark(ladderViewDelegate: ladderViewDelegate)
    }

    func moveCursor(positionX: CGFloat) {
        cursorViewModel.cursorPosition = positionX
    }

    func highlightCursor(_ on: Bool) {
        cursorViewModel.cursorState = on ? .attached : .unattached
    }

    func hideCursor(_ hide: Bool) {
        cursorViewModel.cursorVisible = !hide
    }

    func cursorIsVisible() -> Bool {
        return cursorViewModel.cursorVisible
    }

    func attachMark(positionX: CGFloat) {
        cursorViewModel.attachMark(positionX: positionX, ladderViewDelegate: ladderViewDelegate)
    }

    // We expose the underlying view model to avoid exposing elements of the model.
    func getViewModel() -> CursorViewModel {
        return cursorViewModel
    }

    func view() -> UIView {
        return self
    }

    func convertPoint(_ point: CGPoint) -> CGPoint {
        return convert(point, to: self)
    }

    func setHeight(_ height: CGFloat) {
        cursorViewModel.height = height
    }
}

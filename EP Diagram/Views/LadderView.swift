//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderView: UIView, LadderDelegate {

    public weak var scrollView: UIScrollView!
    public var leftMargin: CGFloat = 0
    public var scale: CGFloat = 1.0

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
        func getMarkStartPositionInView(_ view: UIView) -> CGFloat {
            let position = CGPoint(x: 0, y: ladderViewModel?.activeRegion()?.startPosition ?? 0)
            NSLog("StartPosition = \(position)")
            return convert(position, to: view).y
    }

    func deleteMark(location: CGFloat) {
        print("Delete mark at \(location)")
    }

    func makeMark(location: CGFloat) {
        print("Make mark at \(location)")
        // FIXME: Need to convert cursor location to a mark location, which
        // depends on scale and scolling!
        ladderViewModel?.addMark(location: translatePosition(location))
        setNeedsDisplay()
    }

    func translatePosition(_ location: CGFloat) -> CGFloat {
        return (location + scrollView.contentOffset.x) / scale
    }

    // Touches
    @objc func singleTap(tap: UITapGestureRecognizer) {
        print("Single tap on ladder view")
        // select region tapped or select mark
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

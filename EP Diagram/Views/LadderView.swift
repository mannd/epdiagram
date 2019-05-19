//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderView: UIView {
    public var lineXPosition: Double = 0.0
    public var scrollViewBounds = CGRect(x: 0, y: 0 , width: 0, height: 0)
    let margin: CGFloat = 50

    let ladderViewModel: LadderViewModel?

    required init?(coder aDecoder: NSCoder) {
        ladderViewModel = LadderViewModel()
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        // Note rect doesn't change during scroll or zoom.
        // print("Drawing rect is \(rect)")
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel?.draw(rect: rect, scrollViewBounds: scrollViewBounds, context: context)
        }
    }

}

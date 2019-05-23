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
    public let margin: CGFloat = 50
    public var scale: CGFloat {
        get {
            return ladderViewModel.scale
        }
        set(value) {
            ladderViewModel.scale = value
        }
    }

    var unzoomedViewHeight: CGFloat?
    override func layoutSubviews() {
        print("layoutSubviews in LadderView")
        super.layoutSubviews()
        unzoomedViewHeight = frame.size.height
    }

    override var transform: CGAffineTransform {
        get {
            return super.transform
        }
        set {
            print("transform set in LadderView")
            if let unzoomedViewHeight = unzoomedViewHeight {
                var t = newValue
                t.d = 1.0
                t.ty = (1.0 - t.a) * unzoomedViewHeight/2
                super.transform = t
            }
        }
    }

    let ladderViewModel: LadderViewModel

    required init?(coder aDecoder: NSCoder) {
        ladderViewModel = LadderViewModel()
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel.draw(rect: rect, scrollViewBounds: scrollViewBounds, context: context)
        }
    }

}

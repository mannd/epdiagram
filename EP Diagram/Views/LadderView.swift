//
//  LadderView.swift
//  EP Diagram
//
//  Created by David Mann on 4/30/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class LadderView: UIView, MarkDelegate {
    func deleteMark(location: CGFloat) {
        print("Delete mark at \(location)")
    }

    func makeMark(location: CGFloat) {
        print("Make mark at \(location)")
    }

    public weak var scrollView: UIScrollView!
    public let margin: CGFloat = 40
    public var scale: CGFloat = 1.0

    let ladderViewModel: LadderViewModel

    required init?(coder aDecoder: NSCoder) {
        ladderViewModel = LadderViewModel()
        super.init(coder: aDecoder)
    }

    override func draw(_ rect: CGRect) {
        // Drawing code - note not necessary to call super.draw.
        if let context = UIGraphicsGetCurrentContext() {
            ladderViewModel.draw(rect: rect, margin: margin, offset: scrollView.contentOffset.x, scale: scale, context: context)
        }
    }



}

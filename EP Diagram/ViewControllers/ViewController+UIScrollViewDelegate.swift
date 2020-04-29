//
//  ViewController+UIScrollViewDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

extension ViewController: UIScrollViewDelegate {

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView == imageScrollView {
            return imageView
        }
        else {
            return nil
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == imageScrollView {
            scrollViewAdjustViews(scrollView)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == imageScrollView {
            scrollFinished()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if scrollView == imageScrollView && !decelerate {
            scrollFinished()
        }
    }

    fileprivate func scrollFinished() {
        os_log("scrollFinished", log: OSLog.viewCycle, type: .info)
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        os_log("scrollViewWillBeginZooming", log: OSLog.viewCycle, type: .info)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        os_log("scrollViewDidEndZooming", log: OSLog.viewCycle, type: .info)
        scrollViewAdjustViews(scrollView)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        //os_log("scrollViewDidZoom", log: OSLog.viewCycle, type: .info)
    }

    func scrollViewAdjustViews(_ scrollView: UIScrollView) {
        ladderView.offsetX = scrollView.contentOffset.x
        cursorView.offsetX = scrollView.contentOffset.x
        cursorView.scale = scrollView.zoomScale
        ladderView.scale = scrollView.zoomScale
        setViewsNeedDisplay()
    }

}

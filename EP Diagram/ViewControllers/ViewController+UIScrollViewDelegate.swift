//
//  ViewController+UIScrollViewDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

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
            P("scrollViewDidScroll")
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
        P("scroll finished")
    }

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        P("scrollViewDidEndZooming")
        scrollViewAdjustViews(scrollView)
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        P("scrollViewDidZoom")
    }

    func scrollViewAdjustViews(_ scrollView: UIScrollView) {
        ladderView.offsetX = scrollView.contentOffset.x
        cursorView.offsetX = scrollView.contentOffset.x
        cursorView.scale = scrollView.zoomScale
        ladderView.scale = scrollView.zoomScale
        setViewsNeedDisplay()
    }

    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "HamburgerSegue" {
            let hamburgerController = segue.destination as? HamburgerTableViewController
            hamburgerController?.delegate = self
        }
    }
}

    //
    //  ViewController.swift
    //  EP Diagram
    //
    //  Created by David Mann on 4/29/19.
    //  Copyright © 2019 EP Studios. All rights reserved.
    //

    import UIKit

    class ViewController: UIViewController, UIScrollViewDelegate {

        @IBOutlet var imageScrollView: UIScrollView!
        @IBOutlet var imageView: UIImageView!
        @IBOutlet var ladderView: LadderView!
        @IBOutlet var ladderScrollView: UIScrollView!
        var zoom: CGFloat = 1.0

        override func viewDidLoad() {
            super.viewDidLoad()
            // Do any additional setup after loading the view.
            title = "EP Diagram"
            imageScrollView.delegate = self
            ladderView.backgroundColor = UIColor.white
            ladderScrollView.isScrollEnabled = false
            ladderView.lineXPosition = 100
            displayLadder()
        }

        // This is just temporary testing code
        fileprivate func displayLadder() {
            ladderScrollView.bounds.origin.x = imageScrollView.bounds.origin.x
            ladderView.scrollViewBounds = ladderScrollView.bounds
            ladderView.setNeedsDisplay()
        }

        // Functions below fire during scrolling of imageView and at end
        // of scrolling.  Relabeling might best occur at end of scrolling,
        // while redrawing of ladder can be done during scrolling.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                print(scrollView.bounds)
                displayLadder()
            }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
                print("End decelerating")
                scrollFinished()
            }
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if scrollView == imageScrollView && !decelerate {
                print("End dragging")
                scrollFinished()
            }
        }

        fileprivate func scrollFinished() {
            print("Scroll finished")
        }

        // Not clear if there is any simple way to maintain relationship between
        // image and ladder during zooming.
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            if scrollView == imageScrollView {
                return imageView
            }
            else {
                return nil
            }
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            print("Zoom = \(scale)")
            ladderView.lineXPosition = ladderView.lineXPosition * Double(scale / zoom)
            zoom = scale

            ladderView.setNeedsDisplay()
        }

    }


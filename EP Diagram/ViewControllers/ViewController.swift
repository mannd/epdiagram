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
        var zoom: CGFloat = 1.0

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "EP Diagram"
            imageScrollView.delegate = self
            // Ensure there is a space for labels at the left margin.
            imageScrollView.contentInset = UIEdgeInsets(top: 0, left: ladderView.margin, bottom: 0, right: 0)
            // Distinguish the two views.
            imageScrollView.backgroundColor = UIColor.lightGray
            ladderView.backgroundColor = UIColor.white
            // just a temp mark
            ladderView.lineXPosition = 100
            displayLadder()
        }

        override func viewDidAppear(_ animated: Bool) {
            // This centers image, as opposed to starting with it at the upper left
            // hand corner of the screen.
            let newContentOffsetX = (imageScrollView.contentSize.width/2) - (imageScrollView.bounds.size.width/2);
            imageScrollView.contentOffset = CGPoint(x: newContentOffsetX, y: 0)
        }

        fileprivate func displayLadder() {
            ladderView.setNeedsDisplay()
        }

        // Functions below fire during scrolling of imageView and at end
        // of scrolling.  Relabeling might best occur at end of scrolling,
        // while redrawing of ladder can be done during scrolling.
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if scrollView == imageScrollView {
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
            //ladderView.lineXPosition = ladderView.lineXPosition * Double(scale / zoom)
            // FIXME: Doesn't work: lineXPosition not fixed, ladderView width doesn't increase!!
            // TODO: Fix adjust width of ladderView after zoom
            // To do this, will need to pass scale or zoom to LadderView and adjust the rectangle width so that the full width of the ladder is drawn.  Will also need to adjust the mark location based on the scale.
            zoom = scale

            ladderView.setNeedsDisplay()
        }

    }


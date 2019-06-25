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
        @IBOutlet var cursorView: CursorView!
        var zoom: CGFloat = 1.0
        var isZooming = false

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "EP Diagram"
            imageScrollView.delegate = self
            // Ensure there is a space for labels at the left margin.
            imageScrollView.contentInset = UIEdgeInsets(top: 0, left: ladderView.margin, bottom: 0, right: 0)
            // Distinguish the two views.
            imageScrollView.backgroundColor = UIColor.lightGray
            ladderView.backgroundColor = UIColor.white
            ladderView.scrollView = imageScrollView
            cursorView.delegate = ladderView
            cursorView.height = ladderView.frame.height
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
            print("Scrolling")
            if scrollView == imageScrollView {
                if !isZooming {
                    displayLadder()
                }
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

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            isZooming = true
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            print("Zoom = \(scale)")
            print("imageView width = \(imageView.frame.width)")
            print("imageScrollView bounds = \(imageScrollView.bounds)")
            print("imageScrollView contentOffset = \(imageScrollView.contentOffset)")
            isZooming = false
            ladderView.scale = scale
            zoom = scale

            ladderView.setNeedsDisplay()
        }

        // TODO: This doesn't work right.
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)
            coordinator.animate(alongsideTransition: nil, completion: {
                _ in
                print("Transitioning")
                self.ladderView.setNeedsDisplay()
            })
        }

    }


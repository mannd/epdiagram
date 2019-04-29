//
//  ViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var ladderView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title = "EP Diagram"
        scrollView.delegate = self
        ladderView.backgroundColor = UIColor.gray
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print(scrollView.bounds)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

}


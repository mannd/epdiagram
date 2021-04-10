//
//  OnboardingViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/8/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit

class OnboardingViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    var images: [UIImage?] = [
        UIImage(named: "test-onboard-1"),
        UIImage(named: "test-onboard-2")
    ]
    var index: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        view.backgroundColor = .systemBackground
        index = 0
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if index > 0 {
            index -= 1
        }
        return page(at: index)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if index < images.count - 1 {
            index += 1
        }
        return page(at: index)
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return images.count
    }

    func page(at index: Int) -> UIViewController {
        let vc = UIViewController()
        let imageView = UIImageView(image: images[index])
        vc.view.addSubview(imageView)
        return vc
    }

    

    

}

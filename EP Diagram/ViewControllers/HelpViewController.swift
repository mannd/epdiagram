//
//  HelpViewController.swift
//  EP Diagram
//
//  Created by David Mann on 7/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import WebKit
import os.log

class HelpViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet var helpWebView: WKWebView!
    @IBOutlet var loadingLabel: UILabel!

    static let inHelpKey = "inHelpKey"
    static let contentOffsetYKey = "contentOffsetYKey"
    var restorationInfo: [AnyHashable: Any]?

    override func viewDidLoad() {
    super.viewDidLoad()

        loadingLabel.text = L("Loading...")
        guard let url = Bundle.main.url(forResource: "help", withExtension: "html") else { return }
        helpWebView.navigationDelegate = self
        helpWebView.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        helpWebView.load(request)
        title = L("Help")

        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.userActivity = self.view.window?.windowScene?.userActivity
        self.restorationInfo = nil
    }

    var didFirstLayout = false
    override func viewDidLayoutSubviews() {
        if didFirstLayout { return }
        didFirstLayout = true
        // FIXME: scrolling to y offset not working, ? why.  Not crucial though.
//        let info = restorationInfo
//        if let contentOffsetY = info?[HelpViewController.contentOffsetYKey] as? CGFloat {
////            helpWebView.scrollView.setContentOffset(CGPoint(x: 0, y: contentOffsetY), animated: false)
////            helpWebView.evaluateJavaScript("window.scrollTo(0,\(contentOffsetY)", completionHandler: nil)
//        }
    }

    override func updateUserActivityState(_ activity: NSUserActivity) {
        os_log("updateUserActivityState(activity:) - HelpViewController", log: .lifeCycle, type: .info)
        super.updateUserActivityState(activity)
        let contentOffset = helpWebView.scrollView.contentOffset
        activity.addUserInfoEntries(from: [HelpViewController.contentOffsetYKey: contentOffset.y])
        activity.addUserInfoEntries(from: [HelpViewController.inHelpKey: true])
    }
    

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingLabel.isHidden = false

    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingLabel.isHidden = true

    }

}

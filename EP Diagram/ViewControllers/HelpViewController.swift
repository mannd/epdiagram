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

    override func viewDidLoad() {
        os_log("viewDidLoad() - HelpViewConroller", log: .viewCycle, type: .info)
        super.viewDidLoad()

        loadingLabel.text = L("Loading...")
        guard let url = Bundle.main.url(forResource: "help", withExtension: "html") else { return }
        helpWebView.navigationDelegate = self
        helpWebView.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        helpWebView.load(request)
        title = L("Help")
    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear - HelpViewController", log: .viewCycle, type: .info)
        super.viewDidAppear(animated)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingLabel.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingLabel.isHidden = true
        // animated: must be true or will not scroll to position.
    }

}

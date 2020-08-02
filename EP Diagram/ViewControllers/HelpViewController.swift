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
    

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingLabel.isHidden = false

    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingLabel.isHidden = true

    }

}

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

    var backButton: UIBarButtonItem!
    var forwardButton: UIBarButtonItem!

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

        backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack(_:)))
        forwardButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goForward(_:)))
        navigationItem.setRightBarButtonItems([forwardButton, backButton], animated: true)

        helpWebView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
        helpWebView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
        updateButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        os_log("viewDidAppear - HelpViewController", log: .viewCycle, type: .info)
        super.viewDidAppear(animated)

    }

    override func viewDidDisappear(_ animated: Bool) {
        helpWebView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack))
        helpWebView.removeObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward))
        super.viewDidDisappear(animated)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadingLabel.isHidden = false
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingLabel.isHidden = true
    }

    @objc func goBack(_ sender: UIBarButtonItem) {
        if helpWebView.canGoBack {
            helpWebView.goBack()
        }
    }

    @objc func goForward(_ sender: UIBarButtonItem) {
        if helpWebView.canGoForward {
            helpWebView.goForward()
        }
    }

    func updateButtons() {
        backButton.isEnabled = helpWebView.canGoBack
        forwardButton.isEnabled = helpWebView.canGoForward
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == #keyPath(WKWebView.canGoBack) || keyPath == #keyPath(WKWebView.canGoForward) {
                  updateButtons()
            }
        }
}

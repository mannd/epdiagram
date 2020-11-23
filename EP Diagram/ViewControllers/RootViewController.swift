//
//  RootViewController.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

enum NavigationContext {
  case launched
  case browsing
  case editing
}

class RootViewController: UIViewController {

    var presentationContext: NavigationContext = .launched
    lazy var documentBrowser: DocumentBrowserViewController = {
        return DocumentBrowserViewController()
    }()
    // These arrive from SceneDelegate and have to eventually get to the diagram vc.
    var restorationInfo: [AnyHashable: Any]?
    var persistentID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        displayDocumentBrowser()
//        displayDiagramViewController(presenter: self)
    }

    func displayDocumentBrowser(inboundURL: URL? = nil, importIfNeeded: Bool = true) {
      if presentationContext == .launched {
        documentBrowser.modalPresentationStyle = .fullScreen
        present(documentBrowser, animated: false)
      }
      presentationContext = .browsing
    }

    func displayDiagramViewController(presenter: UIViewController) {
        presentationContext = .editing
        let controller = ViewController.freshController()
        if let vc = controller.viewControllers.first as? ViewController {
            vc.restorationInfo = restorationInfo
            vc.persistentID = persistentID
        }
        // Best if diagram vc covers whole screen.
        controller.modalPresentationStyle = .fullScreen
        presenter.present(controller, animated: true)

    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

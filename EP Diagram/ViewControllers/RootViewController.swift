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
        // Fail gently if cached file no longer exists.
        if let lastDocumentURLPath = restorationInfo?[DiagramViewController.restorationFileNameKey] as? String,
           !lastDocumentURLPath.isEmpty,
           restorationInfo?[DiagramViewController.restorationDoRestorationKey] as? Bool ?? false  {
            if let docURL = FileIO.getDocumentsURL() {
                let fileURL = docURL.appendingPathComponent(lastDocumentURLPath)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    openRemoteDocument(fileURL, importIfNeeded: true)
                } else {
                    displayDocumentBrowser()
                }
            }
        } else {
            displayDocumentBrowser()
        }
    }

    func displayDocumentBrowser(inboundURL: URL? = nil, importIfNeeded: Bool = true) {
        if presentationContext == .launched {
            documentBrowser.restorationInfo = restorationInfo
            documentBrowser.persistentID = persistentID
            documentBrowser.modalPresentationStyle = .fullScreen
            present(documentBrowser, animated: false)
        }
        presentationContext = .browsing
        if let inbound = inboundURL {
          documentBrowser.openRemoteDocument(inbound, importIfNeeded: importIfNeeded)
        }
    }

    func displayDiagramViewController(presenter: UIViewController) {
        presentationContext = .editing
        let navigationViewController = DiagramViewController.navigationControllerFactory()
        guard let diagramViewController = navigationViewController.viewControllers.first as? DiagramViewController else {
            fatalError("Project fault - could not instantiate DiagramViewController")
        }
        diagramViewController.restorationInfo = restorationInfo
        // Best if view covers whole screen.
        navigationViewController.modalPresentationStyle = .fullScreen
        presenter.present(navigationViewController, animated: true)
    }

    func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
        displayDocumentBrowser(inboundURL: inboundURL, importIfNeeded: importIfNeeded)
    }

}

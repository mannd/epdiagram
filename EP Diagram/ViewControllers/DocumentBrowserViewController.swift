//
//  DocumentBrowserViewController.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import OSLog

class DocumentBrowserViewController: UIViewController {

    var currentDocument: DiagramDocument?
    var editingDocument = false
    var browserDelegate = DocumentBrowserDelegate()
    lazy var documentBrowser: UIDocumentBrowserViewController = {
      let browser = UIDocumentBrowserViewController()
        browser.allowsDocumentCreation = true
        browser.browserUserInterfaceStyle = .dark
        browser.delegate = browserDelegate
        browser.view.tintColor = .green
        return browser
    }()
    var restorationInfo: [AnyHashable: Any]?
    var persistentID: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        installDocumentBrowser()

        // Do any additional setup after loading the view.
    }

    func installDocumentBrowser() {
        view.pinToInside(view: documentBrowser.view)
        browserDelegate.presentationHandler = { [weak self] url, error in
            guard error == nil else {
                //present error to user e.g UIAlertController
                let alert = UIAlertController(title: L("Error opening document"), message: L("Could not open document."), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                    NSLog("The \"OK\" alert occured.")
                }))
                self?.present(alert, animated: true)
                return
            }

          if let url = url, let self = self {
            self.openDocument(url: url)
          }
        }

    }
}

protocol DiagramEditorDelegate {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram)
    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram)
}

extension DocumentBrowserViewController: DiagramEditorDelegate {
    func diagramEditorDidFinishEditing(_ controller: DiagramViewController, diagram: Diagram) {
        currentDocument?.diagram = diagram
        closeDiagramController()
    }

    func diagramEditorDidUpdateContent(_ controller: DiagramViewController, diagram: Diagram) {
        currentDocument?.diagram = diagram
    }

    func displayDiagramController() {
        guard !editingDocument, let document = currentDocument else { return }
        editingDocument = true
        let controller = DiagramViewController.freshController(diagram: document.diagram, delegate: self)
        let diagramViewController = controller.viewControllers[0] as? DiagramViewController
        diagramViewController?.restorationInfo = restorationInfo
        diagramViewController?.restorationIdentifier = restorationIdentifier
        diagramViewController?.currentDocument = currentDocument
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
    }

    func closeDiagramController(completion: (()->Void)? = nil) {
        let compositeClosure = {
            self.closeCurrentDocument()
            self.editingDocument = false
            completion?()
        }

        if editingDocument {
            dismiss(animated: true) {
                compositeClosure()
            }
        } else {
            compositeClosure()
        }
    }

    private func closeCurrentDocument() {
        currentDocument?.close()
        currentDocument = nil
    }

    func openRemoteDocument(_ inboundURL: URL, importIfNeeded: Bool) {
        documentBrowser.revealDocument(at: inboundURL, importIfNeeded: importIfNeeded) { (url, error) in
            if let error = error {
                let alert = UIAlertController(title: L("Could Not Open Document"), message: L("EP Diagram could not open this document due to error \(error.localizedDescription)"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                NSLog("The \"OK\" alert occured.")
                }))
                self.present(alert, animated: true)
                print("import did fail - \(error)")
            } else if let url = url {
                self.openDocument(url: url)
            }
        }
    }
}

extension DocumentBrowserViewController {
    func openDocument(url: URL) {
        guard !isDocumentCurrentlyOpen(url: url) else { return }
        closeDiagramController {
            let document = DiagramDocument(fileURL: url)
            document.open { openSuccess in
                guard openSuccess else {
                    print ("could not open \(url)")
                    return
                }
                self.currentDocument = document
                self.displayDiagramController()
            }
        }
    }

    private func isDocumentCurrentlyOpen(url: URL) -> Bool {
        if let document = currentDocument {
            if document.fileURL == url && document.documentState != .closed {
                return true
            }
        }
        return false
    }
}

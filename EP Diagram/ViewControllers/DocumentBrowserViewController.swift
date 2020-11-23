//
//  DocumentBrowserViewController.swift
//  EP Diagram
//
//  Created by David Mann on 11/21/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

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
            return
          }

          if let url = url, let self = self {
            self.openDocument(url: url)
          }
        }

    }
}

protocol DiagramEditorDelegate {
    func diagramEditorDidFinishEditing(_ controller: ViewController, diagram: Diagram)
    func diagramEditorDidUpdateContent(_ controller: ViewController, diagram: Diagram)
}

extension DocumentBrowserViewController: DiagramEditorDelegate {
    func diagramEditorDidFinishEditing(_ controller: ViewController, diagram: Diagram) {
        currentDocument?.diagram = diagram
        closeDiagramController()
    }

    func diagramEditorDidUpdateContent(_ controller: ViewController, diagram: Diagram) {
        currentDocument?.diagram = diagram
    }

    func displayDiagramController() {
        guard !editingDocument, let document = currentDocument else { return }
        editingDocument = true
        let controller = ViewController.freshController(diagram: document.diagram, delegate: self)
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

}

extension DocumentBrowserViewController {
    func openDocument(url: URL) {
        guard !isDocumentCurrentlyOpen(url: url) else { return }
        closeDiagramController {
            let document = DiagramDocument(fileURL: url)
            // FIXME: open fails here.
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

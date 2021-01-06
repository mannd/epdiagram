//
//  DocumentBrowserDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 11/22/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

class DocumentBrowserDelegate: NSObject, UIDocumentBrowserViewControllerDelegate {
    var presentationHandler: ((URL?, Error?) -> Void)?

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {

        let documentName = getDocumentName()
        let cacheDocumentURL = self.createNewDocumentURL(name: documentName)
        let newDocument = DiagramDocument(fileURL: cacheDocumentURL)
        newDocument.save(to: cacheDocumentURL, for: .forCreating) { saveSuccess in
            guard saveSuccess else {
                importHandler(nil, .none)
                return
            }
            newDocument.close { closeSuccess in
                guard closeSuccess else {
                    importHandler(nil, .none)
                    return
                }
                importHandler(cacheDocumentURL, .move)
            }
        }
    }

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        guard let pickedURL = documentURLs.first else { return }
        presentationHandler?(pickedURL, nil)
    }

    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        presentationHandler?(destinationURL, nil)
    }

    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        presentationHandler?(documentURL, error)
    }

}

extension DocumentBrowserDelegate {
    static let newDocumentNumberKey = "newDocumentNumberKey"

    private func getDocumentName() -> String {
        let newDocNumber = UserDefaults.standard.integer(forKey: DocumentBrowserDelegate.newDocumentNumberKey)
        return "Untitled \(newDocNumber)"
    }

    private func incrementNameCount() {
        var newDocNumber = UserDefaults.standard.integer(forKey: DocumentBrowserDelegate.newDocumentNumberKey) + 1
        // This is really paranoid
        if newDocNumber >= Int.max {
            newDocNumber = 1
        }
        UserDefaults.standard.set(newDocNumber, forKey: DocumentBrowserDelegate.newDocumentNumberKey)
    }

    func createNewDocumentURL(name: String? = nil) -> URL {
        guard let cachePath = FileIO.getCacheURL() else {
            fatalError()
        }
        let newName = name ?? getDocumentName()
        let tempURL = cachePath
            .appendingPathComponent(newName)
            .appendingPathExtension(DiagramDocument.extensionName)
        incrementNameCount()
        return tempURL
    }
}



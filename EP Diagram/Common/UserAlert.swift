//
//  UserAlert.swift
//  EP Diagram
//
//  Created by David Mann on 1/1/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import OSLog

enum UserAlert {
    // UI alerts
    static func showMessage(viewController: UIViewController, title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: L("OK"), style: .cancel, handler: nil)
        alert.addAction(okAction)
        viewController.present(alert, animated: true)
    }

    static func showWarning(viewController: UIViewController, title: String, message: String, okActionButtonTitle: String = L("OK"), action: ((UIAlertAction) -> Void)?, completion: (()->Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: okActionButtonTitle, style: .default, handler: action)
        let cancelAction = UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        viewController.present(alert, animated: true, completion: completion)
    }

    static func showFileError(viewController: UIViewController, error: Error) {
        showMessage(viewController: viewController, title: L("File Error"), message: L("Error: \(error.localizedDescription)"))
        os_log("File error %s", log: .errors, type: .error, error.localizedDescription)
    }

    static func showTextAlert(viewController vc: UIViewController, title: String, message: String, placeholder: String? = nil, defaultText: String? = nil, preferredStyle: UIAlertController.Style, handler: ((String) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            if let placeholder = placeholder {
                textField.placeholder = placeholder
            }
            if let defaultText = defaultText {
                textField.text = defaultText
            }
        }
        alert.addAction(UIAlertAction(title: L("Save"), style: .default) { action in
            if let text = alert.textFields?.first?.text {
                if let handler = handler {
                    handler(text)
                }
            }
        })
        vc.present(alert, animated: true)
    }

    static func showNameDiagramAlert(viewController vc: UIViewController, diagram: Diagram, handler: ((String, String) -> Void)?) {
        let alert = UIAlertController(title: L("Name Diagram"), message: L("Give a name and optional description to this diagram"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = L("Diagram name")
            textField.text = diagram.name
        }
        alert.addTextField { textField in
            textField.placeholder = L("Diagram description")
            textField.text = diagram.longDescription
        }
        alert.addAction(UIAlertAction(title: L("Save"), style: .default) { action in
            if let name = alert.textFields?.first?.text, let description = alert.textFields?[1].text {
                if let handler = handler {
                    handler(name, description)
                }
                else {
                    P("name = \(name), description = \(description)")
                }
            }
        })
        vc.present(alert, animated: true)
    }

    static func showEditRegionLabelAlert(viewController vc: UIViewController, region: Region, handler: ((String, String) -> Void)?) {
        let alert = UIAlertController(title: L("Edit Region Label"), message: L("Give a name and optional description to this region"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = L("Region name")
            textField.text = region.name
        }
        alert.addTextField { textField in
            textField.placeholder = L("Region description")
            textField.text = region.longDescription
        }
        alert.addAction(UIAlertAction(title: L("Save"), style: .default) { action in
            if let name = alert.textFields?.first?.text, let description = alert.textFields?[1].text {
                if let handler = handler {
                    handler(name, description)
                }
                else {
                    P("name = \(name), description = \(description)")
                }
            }
        })
        vc.present(alert, animated: true)
    }

    static func showEditMarkLabelAlert(viewController vc: UIViewController, defaultLabel: String, handler: ((String) -> Void)?) {
        let alert = UIAlertController(title: L("Edit Mark Label(s)"), message: L("Give a name to the mark(s)."), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L("Cancel"), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = L("Mark name")
            textField.text = defaultLabel
            textField.clearButtonMode = .always
        }
        alert.addAction(UIAlertAction(title: L("Save"), style: .default) { action in
            if let name = alert.textFields?.first?.text {
                if let handler = handler {
                    handler(name)
                }
                else {
                    P("mark label name = \(name)")
                }
            }
        })
        vc.present(alert, animated: true)
    }


}

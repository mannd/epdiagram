//
//  ViewController+HamburgerTableDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/17/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

protocol HamburgerTableDelegate {
    var hamburgerMenuIsOpen: Bool { get set }
    func takePhoto()
    func selectPhoto()
    func about()
    func openDiagram()
    func saveDiagram()
    func help()
    func hideHamburgerMenu()
    func showHamburgerMenu()
}

extension ViewController: HamburgerTableDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {

    func takePhoto() {
        print("take photo")
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            showMessage(title: L("Camera error"), message: "Camera not available")
            return
        }
        picker.sourceType = .camera
        present(picker, animated: true, completion: nil)
    }

    func selectPhoto() {
        print("select photo")
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }

    func about() {
        let versionBuild = Version.getAppVersion()
        let version = versionBuild.version ?? L("unknown")
        let build = versionBuild.build ?? L("unknown")
        print("About EP Diagram: version = \(version) build = \(build)")
        showMessage(title: L("About EP Diagram"), message: "Copyright 2020 EP Studios, Inc.\nVersion " + version)
    }

    func openDiagram() {
        print("open diagram")
    }

    func saveDiagram() {
        print("save diagram")
    }

    func help() {
        print("help")
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let chosenImage = info[.editedImage] as? UIImage
        imageView.image = chosenImage
        picker.dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}


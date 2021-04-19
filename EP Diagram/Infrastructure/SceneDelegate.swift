//
//  SceneDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 10/23/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        os_log("scene(scene:willConnectTo:options:) - SceneDelegate", log: .lifeCycle, type: .info)
        guard let scene = (scene as? UIWindowScene) else { return }
        scene.title = L("EP Diagram")
        scene.userActivity = session.stateRestorationActivity ?? NSUserActivity(activityType: "org.epstudios.epdiagram.mainActivity")
        self.scene(scene, openURLContexts: connectionOptions.urlContexts)

        if let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController {
            documentBrowserViewController.restorationInfo = scene.userActivity?.userInfo
        }
    }

    func stateRestorationActivity(for scene: UIScene) -> NSUserActivity? {
        os_log("stateRestorationActivity(scene:) - SceneDelegate", log: .lifeCycle, type: .info)
        return scene.userActivity
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        os_log("scene(_:openURLContexts:) - SceneDelegate", log: .lifeCycle, type: .info)
        guard let documentBrowserViewController = self.window?.rootViewController as? DocumentBrowserViewController else { return }
        for context in URLContexts {
            let url = context.url
            if url.isFileURL {
                documentBrowserViewController.externalURL = url
            }
        }
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        os_log("scene(_:continue:) - SceneDelegate, %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)

        if let window = self.window {
            window.rootViewController?.restoreUserActivityState(userActivity)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        os_log("sceneDidDisconnect(_:) - SceneDelegate, %s", log: .lifeCycle, type: .info, scene.session.persistentIdentifier)
    }

    //    override func buildMenu(with builder: UIMenuBuilder) {
    //        super.buildMenu(with: builder)
    //
    //        if builder.system == .main {
    //            builder.remove(menu: .format)
    //            let imageMenu = UIMenu(title: L("Image"))
    //            builder.insertSibling(imageMenu, afterMenu: .view)
    //            let diagramMenu = UIMenu(title: L("Diagram"))
    //            builder.insertSibling(diagramMenu, afterMenu: imageMenu.identifier)
    //
    //            let preferencesCommand = UIKeyCommand(title: L("Preferences..."), action: #selector(ViewController.showPreferencesCommand(_:)), input: ",", modifierFlags: [.command])
    //            let openPreferences = UIMenu(title: "Preferences...", image: nil, identifier: UIMenu.Identifier("openPreferences"), options: .displayInline, children: [preferencesCommand])
    //            builder.insertSibling(openPreferences, afterMenu: .about)
    //
    //            let openImageCommand = UIKeyCommand(title: L("Open..."), action: #selector(ViewController.openImage(_:)), input: "O", modifierFlags: [.command])
    //            let openImageMenu = UIMenu(title: "OpenImage", image: nil, identifier: UIMenu.Identifier("openImage"), options: .displayInline, children: [openImageCommand])
    //            builder.insertSibling(openImageMenu, afterMenu: .newScene)
    //
    //            let newDiagramCommand = UIKeyCommand(title: L("New"), action: #selector(ViewController.newDiagram(_:)), input: "D", modifierFlags: [.command])
    //            let selectDiagramCommand = UICommand(title: L("Select..."), action: #selector(ViewController.selectDiagram(_:)))
    //            let saveDiagramCommand = UIKeyCommand(title: L("Save"), action: #selector(ViewController.saveDiagram(_:)), input: "S", modifierFlags: [.command])
    //            let renameDiagramCommand = UICommand(title: L("Rename"), action: #selector(ViewController.renameDiagram(_:)))
    //            let duplicateDiagramCommand = UICommand(title: L("Duplicate"), action: #selector(ViewController.duplicateDiagram(_:)))
    //
    //            let diagramSubMenu1 = UIMenu(title: "diagramSubMenu1", image: nil, identifier: UIMenu.Identifier("diagramSubMenu1"), options: .displayInline, children: [newDiagramCommand, selectDiagramCommand, saveDiagramCommand, renameDiagramCommand, duplicateDiagramCommand])
    //            builder.insertChild(diagramSubMenu1, atStartOfMenu: diagramMenu.identifier)
    //
    //            let getDiagramInfoCommand = UICommand(title: L("Get Info"), action: #selector(ViewController.getDiagramInfo(_:)))
    //            let diagramSubMenu2 = UIMenu(title: "diagramSubMenu2", image: nil, identifier: UIMenu.Identifier("diagramSubMenu2"), options: .displayInline, children: [getDiagramInfoCommand])
    //            builder.insertSibling(diagramSubMenu2, afterMenu: diagramSubMenu1.identifier)
    //
    //            let sampleDiagramsCommand = UICommand(title: L("Samples..."), action: #selector(ViewController.sampleDiagrams(_:)))
    //            let snapShotDiagramCommand = UICommand(title: L("Snapshot"), action: #selector(ViewController.snapShotDiagram(_:)))
    //            let diagramSubMenu3 = UIMenu(title: "diagramSubMenu3", image: nil, identifier: UIMenu.Identifier("diagramSubMenu3"), options: .displayInline, children: [sampleDiagramsCommand, snapShotDiagramCommand])
    //            builder.insertSibling(diagramSubMenu3, afterMenu: diagramSubMenu2.identifier)
    //
    //
    //
    //
    //        }
    //    }
 
 
}

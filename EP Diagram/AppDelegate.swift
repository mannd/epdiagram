//
//  AppDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        UserDefaults.standard.register(defaults: [
            Preferences.defaultLineWidthKey: 2,
            Preferences.defaultShowImpulseOriginKey: false,
            Preferences.defaultShowBlockKey: true,
            Preferences.defaultShowIntervalsKey: false,
            Preferences.defaultLastDiagramKey: ""
        ])
        return true
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

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        return sceneConfiguration
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}



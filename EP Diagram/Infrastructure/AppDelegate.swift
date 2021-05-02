//
//  AppDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var ubiqURL: URL?
    var preferencesDialogIsOpen: Bool = false

    static let mainActivityType = "org.epstudios.epdiagram.mainActivity"
    static let preferencesActivityType = "org.epstudios.epdiagram.preferencesActivity"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        os_log("application(_:didFinishLaunchingWithOptions:) - AppDelegate", log: .lifeCycle, type: .info)

        // Register defaults for preferences.
        UserDefaults.standard.register(defaults: Preferences.defaults())

        // Check for iCloud availability.
        DispatchQueue.global(qos: .background).async {
            let fileManager = FileManager.default
            let ubiqURL = fileManager.url(forUbiquityContainerIdentifier: nil)
            DispatchQueue.main.async {
                self.ubiqURL = ubiqURL
            }
        }
        return true
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        os_log("application(_:configurationForConnecting:options:)", log: .lifeCycle, type: .info)
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        if options.userActivities.first?.activityType == Self.preferencesActivityType {
            let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            //            configuration.delegateClass = CustomSceneDelegate.self
            configuration.storyboard = UIStoryboard(name: "Preferences", bundle: Bundle.main)
            return configuration
        } else { // if options.userActivities.first?.activityType == Self.mainActivityType {
            let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            return sceneConfiguration
        }
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        os_log("application(_:didDiscardSceneSessions:)", log: .lifeCycle, type: .info)
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        // Close diagram view controllers?
        for session in sceneSessions {
            print("session", session as Any)
            print("configuration", session.configuration as Any)
        }
        
    }

    // MARK: - macOS menu

    #if targetEnvironment(macCatalyst)

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }

        // Remove unwanted menus
        builder.remove(menu: .format)
//        builder.remove(menu: .openRecent)

        // Preferences menu
        let preferencesCommand = UIKeyCommand(
            title: L("Preferences..."),
            action: #selector(showMacPreferences(_:)),
            input: ",",
            modifierFlags: [.command]
        )
        let openPreferencesMenu = UIMenu(
            title: "",
            image: nil,
            identifier: UIMenu.Identifier("openPreferences"),
            options: .displayInline,
            children: [preferencesCommand]
        )
        builder.insertSibling(openPreferencesMenu, afterMenu: .about)

        // Diagram Info
        let diagramInfoCommand = UICommand(
            title: L("Diagram Info..."),
            action: #selector(DiagramViewController.getDiagramInfo(_:))
        )
        let diagramInfoMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("diagramInfoMenu"),
            options: .displayInline,
            children: [diagramInfoCommand]
        )
//        builder.insertSibling(diagramInfoMenu, afterMenu: .close)

        // View menu
        let zoomInCommand = UIKeyCommand(
            title: L("Zoom In"),
            action: #selector(DiagramViewController.doZoom(_:)),
            input: "+",
            modifierFlags: [.command],
            propertyList: "zoomIn"
        )
        let zoomOutCommand = UIKeyCommand(
            title: L("Zoom Out"),
            action: #selector(DiagramViewController.doZoom(_:)),
            input: "-",
            modifierFlags: [.command],
            propertyList: "zoomOut"
        )
        let resetZoomCommand = UIKeyCommand(
            title: L("Reset Zoom"),
            action: #selector(DiagramViewController.doZoom(_:)),
            input: "0",
            modifierFlags: [.command],
            propertyList: "resetZoom"
        )
        let zoomMenu = UIMenu(
            title: L("Zoom..."),
            identifier: UIMenu.Identifier("zoomMenu"),
            options: .displayInline,
            children: [zoomInCommand, zoomOutCommand, resetZoomCommand]
        )
        builder.insertChild(zoomMenu, atStartOfMenu: .view)

        // Images menu
        let importPhotoCommand = UICommand(
            title: L("Photo"),
            action: #selector(DiagramViewController.importPhoto(_:))
        )

        let importImageFileCommand = UICommand(
            title: L("Image File"),
            action: #selector(DiagramViewController.importImageFile(_:))
        )
        let importMenu = UIMenu(
            title: L("Import"),
            image: nil,
            identifier: UIMenu.Identifier("importMenu"),
            children: [importPhotoCommand, importImageFileCommand]
        )

//        var lockImageCommand = UICommand(
//            title: L("Lock Image"),
//            action: #selector(DiagramViewController.lockImage(_:)),
//            state: .off
//        )
//        // FIXME: Need notification to convey state of this and lock ladder to menu
////        lockImageCommand.state = .on

        let sampleCommand = UICommand(
            title: L("Samples"),
            action: #selector(DiagramViewController.sampleDiagrams(_:))
        )

        let imageMenu = UIMenu(
            title: L("Diagram"),
            identifier: UIMenu.Identifier("imageMenu"),
            children: [importMenu, sampleCommand, diagramInfoMenu]
        )
        builder.insertSibling(imageMenu, afterMenu: .view)
//        builder.insertSibling(diagramInfoMenu, afterMenu: UIMenu.Identifier("imageMenu"))

        let editLadderCommand = UICommand(
            title: L("Edit Ladder"),
            action: #selector(DiagramViewController.editMacLadder(_:))
        )
        let selectLadderCommand = UICommand(
            title: L("Select Ladder"),
            action: #selector(DiagramViewController.selectLadder)
        )
//        let lockLadderCommand = UICommand(
//            title: L("Lock Ladder"),
//            action: #selector(DiagramViewController.lockLadder)
//        )

        let ladderMenu = UIMenu(title: L("Ladder"), children: [selectLadderCommand, editLadderCommand])
        builder.insertSibling(ladderMenu, afterMenu: UIMenu.Identifier("imageMenu"))

        let openFileCommand = UIKeyCommand(
            title: "Open...",
//            action: #selector(DocumentBrowserViewController.displayDiagramController),
            action: #selector(newScene(_:)),
            input: "o",
            modifierFlags: [.command]
        )
        let openFileMenu = UIMenu(
            title: "",
            image: nil,
            identifier: UIMenu.Identifier("myOpenFile"),
            options: .displayInline,
            children: [openFileCommand]
        )
        builder.replace(menu: .newScene, with: openFileMenu)

//        let newFileCommand = UIKeyCommand(
//            title: "New",
//            action: #selector(newFile(_:)),
//            input: "n",
//            modifierFlags: [.command]
//        )
//        let newFileMenu = UIMenu(
//            title: "",
//            image: nil,
//            identifier: UIMenu.Identifier("myNewFile"),
//            options: .displayInline,
//            children: [openFileCommand]
//        )
//        builder.insertChild(newFileMenu, atStartOfMenu: .file)

//        let openFileCommand = UIKeyCommand(
//            title: "Open Image...",
//            action: #selector(DocumentBrowserViewController.openImageFile(_:)),
//            input: "o",
//            modifierFlags: [.command]
//        )
//        let openFileMenu = UIMenu(
//            title: "",
//            image: nil,
//            identifier: UIMenu.Identifier("openImage"),
//            options: .displayInline,
//            children: [openFileCommand]
//        )
//        builder.insertSibling(openFileMenu, afterMenu: .newScene)

    }

    @IBAction func newScene(_ sender: Any) {
        print("newScene")
        let activity = NSUserActivity(activityType: Self.mainActivityType)
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { (error) in
            print("Error launching new main activity scene", error.localizedDescription)
        }
    }

    // See https://stackoverflow.com/questions/58882047/open-a-new-window-in-mac-catalyst
    @IBAction func showMacPreferences(_ sender: Any) {
        // prevent the menu from opening more than one.
        guard !preferencesDialogIsOpen else { return }
        let activity = NSUserActivity(activityType: Self.preferencesActivityType)
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { (error) in
            print("Error showing Mac preferences", error.localizedDescription)
        }
        preferencesDialogIsOpen = true
    }

    #endif

}



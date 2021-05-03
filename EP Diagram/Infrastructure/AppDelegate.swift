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
            let sceneConfiguration = UISceneConfiguration(name: "Preferences Configuration", sessionRole: connectingSceneSession.role)
            return sceneConfiguration
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
    }

    // MARK: - macOS menu

    #if targetEnvironment(macCatalyst)

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }

        // Remove unwanted menus
        builder.remove(menu: .format)
        builder.remove(menu: .openRecent) // Just doesn't seem to work with Catalyst

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

        // File menu
        let openFileCommand = UIKeyCommand(
            title: "Open...",
            action: #selector(newScene(_:)),
            input: "o",
            modifierFlags: [.command]
        )
        let openFileMenu = UIMenu(
            title: "",
            image: nil,
            identifier: UIMenu.Identifier("CustomOpenFile"),
            options: .displayInline,
            children: [openFileCommand]
        )
        builder.insertSibling(openFileMenu, afterMenu: .newScene)
//        builder.replace(menu: .newScene, with: openFileMenu)

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

        // Diagram menu
        let importPhotoCommand = UICommand(
            title: L("Photo"),
            action: #selector(DiagramViewController.importPhoto(_:))
        )

        let importImageFileCommand = UICommand(
            title: L("File"),
            action: #selector(DiagramViewController.importImageFile(_:))
        )

        let importMenu = UIMenu(
            title: L("Import Image"),
            image: nil,
            identifier: UIMenu.Identifier("importMenu"),
            children: [importPhotoCommand, importImageFileCommand]
        )

        let sampleCommand = UICommand(
            title: L("Samples"),
            action: #selector(DiagramViewController.sampleDiagrams(_:))
        )

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

        let editLadderCommand = UICommand(
            title: L("Edit Ladder"),
            action: #selector(DiagramViewController.editMacLadder(_:))
        )
        let selectLadderCommand = UICommand(
            title: L("Select Ladder"),
            action: #selector(DiagramViewController.selectLadder)
        )

        let ladderMenu = UIMenu(title: L("Ladder"), children: [selectLadderCommand, editLadderCommand])

        let diagramMenu = UIMenu(
            title: L("Diagram"),
            identifier: UIMenu.Identifier("diagramMenu"),
            children: [importMenu, ladderMenu, sampleCommand, diagramInfoMenu]
        )
        builder.insertSibling(diagramMenu, afterMenu: .view)
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



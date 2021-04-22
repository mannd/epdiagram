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

    // MARK: - macOS menu

    #if targetEnvironment(macCatalyst)

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }
        builder.remove(menu: .format)
        builder.remove(menu: .newScene)
        let preferencesCommand = UIKeyCommand(
            title: "Preferences...",
//            action: #selector(DiagramViewController.showNewPreferences(_:)),
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

        let openFileCommand = UIKeyCommand(
            title: "Open...",
            action: #selector(newScene(_:)),
            input: "o",
            modifierFlags: [.command]
        )
//        let openFileMenu = UIMenu(
//            title: "",
//            image: nil,
//            identifier: UIMenu.Identifier("myOpenFile"),
//            options: .displayInline,
//            children: [openFileCommand]
//        )
//        builder.replace(menu: .newScene, with: openFileMenu)

//        let newFileCommand = UIKeyCommand(
//            title: "New",
//            action: #selector(newFile(_:)),
//            input: "n",
//            modifierFlags: [.command]
//        )
        let newFileMenu = UIMenu(
            title: "",
            image: nil,
            identifier: UIMenu.Identifier("myNewFile"),
            options: .displayInline,
            children: [openFileCommand]
        )
        builder.insertChild(newFileMenu, atStartOfMenu: .file)

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

//    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
//        if action == #selector(showMacPreferences(_:)) {
//            return !preferencesDialogIsOpen
//        }
//      return super.canPerformAction(action, withSender: sender)
//    }


    #endif

}



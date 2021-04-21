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
        if options.userActivities.first?.activityType == "preferences" {
            let configuration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//            configuration.delegateClass = CustomSceneDelegate.self
            configuration.storyboard = UIStoryboard(name: "Preferences", bundle: Bundle.main)
            return configuration
        } else {
            let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            return sceneConfiguration
        }
    }

    // MARK: - macOS menu

    #if targetEnvironment(macCatalyst)

    // See https://stackoverflow.com/questions/58882047/open-a-new-window-in-mac-catalyst
    @IBAction func showMacPreferences(_ sender: Any) {
        // prevent the menu from opening more than one.
        guard !preferencesDialogIsOpen else { return }
        let activity = NSUserActivity(activityType: "preferences")
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

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }
        builder.remove(menu: .format)
        let preferencesCommand = UIKeyCommand(
            title: "Preferences...",
            action: #selector(DiagramViewController.showNewPreferences(_:)),
//            action: #selector(showMacPreferences(_:)),
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
            title: "Open Image...",
            action: #selector(DocumentBrowserViewController.openImageFile(_:)),
            input: "o",
            modifierFlags: [.command]
        )
        let openFileMenu = UIMenu(
            title: "",
            image: nil,
            identifier: UIMenu.Identifier("openImage"),
            options: .displayInline,
            children: [openFileCommand]
        )
        builder.insertSibling(openFileMenu, afterMenu: .newScene)

    }


    #endif

}



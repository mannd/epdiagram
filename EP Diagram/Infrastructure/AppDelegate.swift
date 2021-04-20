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

    // See https://stackoverflow.com/questions/58882047/open-a-new-window-in-mac-catalyst
    @IBAction func showMacPreferences(_ sender: Any) {
        var activity = NSUserActivity(activityType: "preferences")
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { (error) in
        }
        // TODO: inactivate Preferences menu item if preferences already open.
    }

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        builder.remove(menu: .format)
        let preferencesCommand = UIKeyCommand(input: ",", modifierFlags: [.command], action: #selector(showMacPreferences(_:)))
        preferencesCommand.title = "Preferences..."
        let openPreferences = UIMenu(title: "Preferences...", image: nil, identifier: UIMenu.Identifier("openPreferences"), options: .displayInline, children: [preferencesCommand])
        builder.insertSibling(openPreferences, afterMenu: .about)

    }

//    @objc func showPreferencesTest(_ sender: Any) {
//        print("showing preferences")
//        let view = PreferencesView(diagramController: DiagramModelController(diagram: Diagram.defaultDiagram()))
//        var topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
//        topWindow?.rootViewController = UIViewController()
//        topWindow?.windowLevel = UIWindow.Level.alert + 1
//
//        let alert = UIAlertController(title: "APNS", message: "received Notification", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
//            // continue your work
//
//            // important to hide the window after work completed.
//            // this also keeps a reference to the window until the action is invoked.
//            topWindow?.isHidden = true // if you want to hide the topwindow then use this
//            topWindow = nil // if you want to hide the topwindow then use this
//         })
//
//        topWindow?.makeKeyAndVisible()
//        topWindow?.rootViewController?.present(alert, animated: true, completion: nil)

        
//    }

}



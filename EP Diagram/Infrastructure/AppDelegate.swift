//
//  AppDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 4/29/19.
//  Copyright © 2019 EP Studios. All rights reserved.
//

import UIKit
import os.log
#if targetEnvironment(macCatalyst)
import AppKit
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var ubiqURL: URL?
    var preferencesDialogIsOpen: Bool = false
    var appKitPlugin: SharedAppKitProtocol?

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
        #if targetEnvironment(macCatalyst)
        loadAppKitPlugin()
        #endif

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
        } else { //if options.userActivities.first?.activityType == Self.mainActivityType {
            let sceneConfiguration = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
            return sceneConfiguration
        }
    }
}


#if targetEnvironment(macCatalyst)
extension AppDelegate {

    // MARK: - Mac support app kit plugin

    @objc func loadAppKitPlugin() {
        let bundleFileName = "MacSupport.bundle"
        guard let bundleURL = Bundle.main.builtInPlugInsURL?
                .appendingPathComponent(bundleFileName) else { return }

        guard let bundle = Bundle(url: bundleURL) else { return }

        let className = "MacSupport.MacSupport"
        guard let pluginClass = bundle.classNamed(className) as? SharedAppKitProtocol.Type else { return }

        self.appKitPlugin = pluginClass.init()
    }

    // MARK: - macOS menu

    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }

        // Remove unwanted menus
        builder.remove(menu: .format)

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
        let saveScreenshotCommand = UIKeyCommand(
            title: "Save Screenshot",
            action: #selector(DiagramViewController.macSnapshotDiagram),
            input: "s",
            modifierFlags: [.command]
        )
        let saveScreenshotMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("saveScreenshotMenu"),
            options: .displayInline,
            children: [saveScreenshotCommand]
        )

        let addDirectoryToSandboxCommand = UICommand(
            title: L("Add Folder to Sandbox"),
            action: #selector(DiagramViewController.addDirectoryToSandbox(_:))
        )
        let clearSandbox = UICommand(
            title: L("Reset Sandbox"),
            action: #selector(DiagramViewController.clearSandbox(_:))
        )
        let sandboxMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("sandboxMenu"),
            options: .displayInline,
            children: [addDirectoryToSandboxCommand, clearSandbox]
        )

        let renameCommand = UIKeyCommand(
            title: L("Rename Diagram..."),
            action: #selector(DiagramViewController.renameDiagram),
            input: "r",
            modifierFlags: [.command]
        )

        let closeDiagramCommand = UIKeyCommand(
            title: L("Close Diagram"),
            action: #selector(DiagramViewController.macCloseDocument(_:)),
            input: "w",
            modifierFlags: [.command]
        )
        let closeDiagramMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("closeDiagramMenu"),
            options: .displayInline,
            children: [renameCommand, closeDiagramCommand]
        )
        builder.replace(menu: .close, with: closeDiagramMenu)
        builder.insertSibling(saveScreenshotMenu, beforeMenu: UIMenu.Identifier("closeDiagramMenu"))
        builder.insertSibling(sandboxMenu, beforeMenu: UIMenu.Identifier("saveScreenshotMenu"))

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
            action: #selector(DiagramViewController.editLadder(_:))
        )
        let selectLadderCommand = UICommand(
            title: L("Select Ladder"),
            action: #selector(DiagramViewController.selectLadder(_:))
        )

//        let testCommand = UIKeyCommand(
//            title: "Test",
//            action: #selector(DiagramViewController.renameDiagram),
//            input: "t",
//            modifierFlags: [.command]
//        )

        let ladderMenu = UIMenu(title: L("Ladder"), children: [selectLadderCommand, editLadderCommand])

        let diagramMenu = UIMenu(
            title: L("Diagram"),
            identifier: UIMenu.Identifier("diagramMenu"),
            children: [importMenu, ladderMenu, sampleCommand, diagramInfoMenu]
        )
        builder.insertSibling(diagramMenu, afterMenu: .view)

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

}
#endif

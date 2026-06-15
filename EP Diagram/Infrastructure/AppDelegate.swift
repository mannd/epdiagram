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
    static let openDocumentURLKey = "org.epstudios.epdiagram.openDocumentURL"

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

        // Saving a million startup issues, force startup without restoring old windows.
        // Yes, this really exists.
        // See https://stackoverflow.com/questions/69552157/mac-catalyst-prevent-scene-creation-or-create-with-invisible-window
        UserDefaults.standard.set(false, forKey: "NSQuitAlwaysKeepsWindows")
        #endif

        return true
    }

    // MARK: UISceneSession Lifecycle
    // NB: This is only called the first time an application is launched.  If there are windows
    // that are being restored by the operating system (macOS), this is skipped.
    // See https://stackoverflow.com/questions/63520008/why-is-uiapplicationdelegate-method-application-configurationforconnectingop
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        os_log("application(_:configurationForConnecting:options:)", log: .lifeCycle, type: .info)
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
        let newDiagramCommand = UIKeyCommand(
            title: L("New"),
            action: #selector(newDiagramWindow(_:)),
            input: "n",
            modifierFlags: [.command]
        )
        let openDiagramCommand = UIKeyCommand(
            title: L("Open..."),
            action: #selector(openDiagramFromMenu(_:)),
            input: "o",
            modifierFlags: [.command]
        )
        let newOpenMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("newOpenMenu"),
            options: .displayInline,
            children: [newDiagramCommand, openDiagramCommand]
        )
        builder.replaceChildren(ofMenu: .file) { oldChildren in
            func isDuplicateNewOrOpenCommand(_ element: UIMenuElement) -> Bool {
                guard let keyCommand = element as? UIKeyCommand,
                      keyCommand.modifierFlags.contains(.command),
                      let input = keyCommand.input?.lowercased() else { return false }
                return input == "n" || input == "o"
            }

            func removingDuplicateNewAndOpenCommands(from elements: [UIMenuElement]) -> [UIMenuElement] {
                elements.compactMap { element in
                    if isDuplicateNewOrOpenCommand(element) {
                        return nil
                    }
                    if let menu = element as? UIMenu {
                        if menu.identifier == UIMenu.Identifier("newOpenMenu") {
                            return nil
                        }
                        let children = removingDuplicateNewAndOpenCommands(from: menu.children)
                        return menu.replacingChildren(children)
                    }
                    return element
                }
            }

            var newChildren = removingDuplicateNewAndOpenCommands(from: oldChildren)
            newChildren.insert(newOpenMenu, at: 0)
            return newChildren
        }

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

        let closeWindowCommand = UIKeyCommand(
            title: L("Close Window"),
            action: #selector(DocumentBrowserViewController.closeWindow(_:)),
            input: "w",
            modifierFlags: [.command]
        )
        let closeDiagramMenu = UIMenu(
            title: "",
            identifier: UIMenu.Identifier("closeDiagramMenu"),
            options: .displayInline,
            children: [renameCommand, closeWindowCommand]
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
            title: L("Edit Ladders"),
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

    @IBAction func newDiagramWindow(_ sender: Any) {
        requestMainDocumentBrowserScene(errorMessage: "Error showing new diagram window")
    }

    @IBAction func openDiagramFromMenu(_ sender: Any) {
        if let documentBrowserViewController = activeDocumentBrowserViewController() {
            documentBrowserViewController.openDiagramFromMenu(sender)
        } else {
            requestMainDocumentBrowserScene(errorMessage: "Error showing open browser")
        }
    }

    private func requestMainDocumentBrowserScene(errorMessage: String) {
        let activity = NSUserActivity(activityType: Self.mainActivityType)
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: activity, options: nil) { error in
            print(errorMessage, error.localizedDescription)
        }
    }

    private func activeDocumentBrowserViewController() -> DocumentBrowserViewController? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScenes = windowScenes.filter { $0.activationState == .foregroundActive }
        let inactiveScenes = windowScenes.filter { $0.activationState == .foregroundInactive }
        let candidateScenes = activeScenes + inactiveScenes + windowScenes.filter { $0.activationState != .foregroundActive && $0.activationState != .foregroundInactive }

        for scene in candidateScenes {
            if let window = scene.windows.first(where: { $0.isKeyWindow }),
               let documentBrowserViewController = window.rootViewController as? DocumentBrowserViewController {
                return documentBrowserViewController
            }
        }

        for scene in candidateScenes {
            if let documentBrowserViewController = scene.windows.first?.rootViewController as? DocumentBrowserViewController {
                return documentBrowserViewController
            }
        }

        return nil
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

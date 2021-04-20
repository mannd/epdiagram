//
//  MacPreferencesViewController.swift
//  EP Diagram
//
//  Created by David Mann on 4/19/21.
//  Copyright © 2021 EP Studios. All rights reserved.
//

import UIKit
import SwiftUI

struct SecondView: View {
  var body: some View {
        TabView {
                   Text("Hello")
                       .tabItem {
                           Image(systemName: "heart.fill")
                           Text("Tab1")
                       }
                   Text("World")
                       .tabItem {
                           Text("Tab2")
                       }
        }
      }

}

class MacPreferencesViewController: UIHostingController<PreferencesView> {

        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder, rootView: PreferencesView(diagramController: DiagramModelController(diagram: Diagram.defaultDiagram())))
        }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidDisappear(_ animated: Bool) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.preferencesDialogIsOpen = false
    }

}

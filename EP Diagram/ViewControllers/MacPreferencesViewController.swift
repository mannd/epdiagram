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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

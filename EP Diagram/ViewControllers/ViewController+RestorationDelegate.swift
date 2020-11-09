//
//  ViewController+RestorationDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 11/9/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

protocol RestorationDelegate {
    func saveDiagramToCache()
}

extension ViewController: RestorationDelegate {
    func saveDiagramToCache() {
        saveDiagramToCache(fileName: restorationFileName)
    }
}

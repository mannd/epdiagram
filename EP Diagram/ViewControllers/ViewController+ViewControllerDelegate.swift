//
//  ViewController+ViewControllerDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 5/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import os.log

protocol ViewControllerDelegate: class {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?)
}

extension ViewController: ViewControllerDelegate {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?) {
        os_log("selecteLadderTemplate - ViewController", log: OSLog.action, type: .info)
        if let ladderTemplate = ladderTemplate {
            let ladder = Ladder(template: ladderTemplate)
            ladderView.ladder = ladder
            setViewsNeedDisplay()
        }
    }
}

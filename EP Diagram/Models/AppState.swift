//
//  AppState.swift
//  EP Diagram
//
//  Created by David Mann on 10/28/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit

extension Diagram {
    func store(in activity: NSUserActivity) {
        activity.addUserInfoEntries(from: ["ladder": ladder])
    }

    mutating func restore(from activity: NSUserActivity) {
        guard activity.activityType == "org.epstudios.epdiagram.mainActivity" else { return }
        guard let ladder = activity.userInfo?["ladder"] as? Ladder else { return }

        self.ladder = ladder
    }
}

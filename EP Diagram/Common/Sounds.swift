//
//  Sounds.swift
//  EP Diagram
//
//  Created by David Mann on 8/14/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import AudioToolbox

// TODO: consider preference to turn on/off sounds (they can be annoying).
class Sounds {
    static func playShutterSound() {
        // See http://iphonedevwiki.net/index.php/AudioServices for complete list os system sounds.
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil)
    }

    static func playLockSound() {
        // Note that unlock sound (1101, unlock.caf) doesn't do anything anymore,
        // so use the lock sound for both locking and unlocking.
        AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1100), nil)
    }
}

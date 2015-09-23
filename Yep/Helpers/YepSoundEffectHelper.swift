//
//  YepSoundEffectHelper.swift
//  Yep
//
//  Created by zhowkevin on 15/9/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AudioToolbox.AudioServices

class YepSoundEffectHelper: NSObject {
    var soundID: SystemSoundID?
    
    init(soundName: String) {
        super.init()
        
        if let fileURL = NSBundle.mainBundle().URLForResource(soundName, withExtension: "caf") {
            var theSoundID: SystemSoundID = 0
            let error = AudioServicesCreateSystemSoundID(fileURL, &theSoundID)
            if (error == kAudioServicesNoError) {
                soundID = theSoundID
            } else {
                print("Sound Init Error")
            }
            
        }
    }
    
    func play() {
        if let soundID = soundID {
            AudioServicesPlaySystemSound(soundID)
        }
    }
    
    deinit {
        if let soundID = soundID {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }
}

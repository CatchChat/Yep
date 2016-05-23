//
//  SoundEffectHelper.swift
//  Yep
//
//  Created by zhowkevin on 15/9/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import AudioToolbox.AudioServices

final public class SoundEffect: NSObject {

    var soundID: SystemSoundID?
    
    public init(soundName: String) {
        super.init()

        let bundle = NSBundle(forClass: SoundEffect.self)

        if let fileURL = bundle.URLForResource(soundName, withExtension: "caf") {
            var theSoundID: SystemSoundID = 0
            let error = AudioServicesCreateSystemSoundID(fileURL, &theSoundID)
            if (error == kAudioServicesNoError) {
                soundID = theSoundID
            } else {
                fatalError("SoundEffect init failed!")
            }
        }
    }

    deinit {
        if let soundID = soundID {
            AudioServicesDisposeSystemSoundID(soundID)
        }
    }

    public func play() {
        if let soundID = soundID {
            AudioServicesPlaySystemSound(soundID)
        }
    }
}


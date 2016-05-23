//
//  YepSoundEffect.swift
//  Yep
//
//  Created by zhowkevin on 15/9/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import AudioToolbox.AudioServices

final public class YepSoundEffect: NSObject {

    var soundID: SystemSoundID?
    
    public init(soundName: String) {
        super.init()

        guard !soundName.isEmpty else {
            fatalError("YepSoundEffect: no soundName!")
        }

        let bundle = NSBundle.mainBundle()

        guard let fileURL = bundle.URLForResource(soundName, withExtension: "caf") else {
            fatalError("YepSoundEffect: file no found!")
        }

        var theSoundID: SystemSoundID = 0
        let error = AudioServicesCreateSystemSoundID(fileURL, &theSoundID)
        if (error == kAudioServicesNoError) {
            soundID = theSoundID
        } else {
            fatalError("YepSoundEffect: init failed!")
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


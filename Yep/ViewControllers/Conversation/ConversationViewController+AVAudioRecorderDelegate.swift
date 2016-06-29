//
//  ConversationViewController+AVAudioRecorderDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

extension ConversationViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        println("finished recording \(flag)")
    }

    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        println("\(error?.localizedDescription)")
    }
}


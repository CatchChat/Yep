//
//  NewFeedVoiceRecordViewController.swift
//  Yep
//
//  Created by nixzhu on 15/11/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

class NewFeedVoiceRecordViewController: UIViewController {

    @IBOutlet weak var voiceRecordButton: UIButton!

    var isVoiceRecording = false {
        willSet {
            let image = newValue ? UIImage(named: "button_voice_record_stop") : UIImage(named: "button_voice_record")
            voiceRecordButton.setImage(image, forState: .Normal)
        }
    }

    var voiceFileURL: NSURL?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Voice", comment: "")
    }

    // MARK: - Actions

    @IBAction func cancel(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func voiceRecord(sender: UIButton) {

        if isVoiceRecording {
            YepAudioService.sharedManager.endRecord()

        } else {
            let audioFileName = NSUUID().UUIDString
            if let fileURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {

                voiceFileURL = fileURL

                YepAudioService.sharedManager.beginRecordWithFileURL(fileURL, audioRecorderDelegate: self)
                
                isVoiceRecording = true
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

// MARK: AVAudioRecorderDelegate

extension NewFeedVoiceRecordViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {

        isVoiceRecording = false

        println("finished recording \(flag)")
    }

    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {

        isVoiceRecording = false

        println("\(error?.localizedDescription)")
    }
}


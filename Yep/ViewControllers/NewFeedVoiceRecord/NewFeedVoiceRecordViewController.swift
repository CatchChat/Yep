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

    @IBOutlet weak var nextButton: UIBarButtonItem!

    @IBOutlet weak var voiceRecordSampleView: VoiceRecordSampleView!

    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var voiceRecordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    enum State {
        case Default
        case Recording
        case FinishRecord
    }
    var state: State = .Default {
        willSet {
            switch newValue {

            case .Default:

                nextButton.enabled = false

                voiceRecordButton.hidden = false
                let image =  UIImage(named: "button_voice_record")
                voiceRecordButton.setImage(image, forState: .Normal)

                playButton.hidden = true
                resetButton.hidden = true

                voiceRecordSampleView.reset()
                sampleValues = []
                audioPlayer?.stop()

            case .Recording:

                nextButton.enabled = false

                voiceRecordButton.hidden = false
                let image =  UIImage(named: "button_voice_record_stop")
                voiceRecordButton.setImage(image, forState: .Normal)

                playButton.hidden = true
                resetButton.hidden = true

            case .FinishRecord:

                nextButton.enabled = true

                voiceRecordButton.hidden = true
                playButton.hidden = false
                resetButton.hidden = false
            }
        }
    }

    var voiceFileURL: NSURL?
    var audioPlayer: AVAudioPlayer?
    var displayLink: CADisplayLink!

    var sampleValues: [CGFloat] = [] {
        didSet {
            let count = sampleValues.count
            let frequency = 10
            let minutes = count / frequency / 60
            let seconds = count / frequency - minutes * 60
            let subSeconds = count - seconds * frequency - minutes * 60 * frequency

            timeLabel.text = String(format: "%02d:%02d.%d", minutes, seconds, subSeconds)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Voice", comment: "")

        nextButton.title = NSLocalizedString("Next", comment: "")

        displayLink = CADisplayLink(target: self, selector: "checkVoiceRecordValue")
        displayLink.frameInterval = 6 // 频率为每秒 10 次
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

        state = .Default
    }

    // MARK: - Actions

    @IBAction func cancel(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: { [weak self] in

            YepAudioService.sharedManager.endRecord()

            if let voiceFileURL = self?.voiceFileURL {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(voiceFileURL)
                } catch let error {
                    println("delete voiceFileURL error: \(error)")
                }
            }
        })
    }

    @IBAction func next(sender: UIBarButtonItem) {

        guard let fileURL = voiceFileURL where !sampleValues.isEmpty else {
            return
        }

        let feedVoice = FeedVoice(fileURL: fileURL, sampleValues: sampleValues)

        performSegueWithIdentifier("showNewFeed", sender: Box(feedVoice))
    }

    func checkVoiceRecordValue() {

        if let audioRecorder = YepAudioService.sharedManager.audioRecorder {

            if audioRecorder.recording {
                audioRecorder.updateMeters()
                let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)
                let value = CGFloat(normalizedValue)

                sampleValues.append(value)
                voiceRecordSampleView.appendSampleValue(value)
            }
        }
    }

    @IBAction func voiceRecord(sender: UIButton) {

        if state == .Recording {
            YepAudioService.sharedManager.endRecord()

        } else {
            let audioFileName = NSUUID().UUIDString
            if let fileURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {

                voiceFileURL = fileURL

                YepAudioService.sharedManager.shouldIgnoreStart = false

                YepAudioService.sharedManager.beginRecordWithFileURL(fileURL, audioRecorderDelegate: self)
                
                state = .Recording
            }
        }
    }

    @IBAction func play(sender: UIButton) {

        guard let voiceFileURL = voiceFileURL else {
            return
        }

        if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("playVoice setCategory failed: \(error)")
                return
            }
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOfURL: voiceFileURL)

            self.audioPlayer = audioPlayer // hold it

            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()

            if audioPlayer.play() {
                println("do play voice")
            }

        } catch let error {
            println("play voice error: \(error)")
        }
    }

    @IBAction func reset(sender: UIButton) {

        state = .Default
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showNewFeed":

            if let feedVoice = (sender as? Box<FeedVoice>)?.value {

                let vc = segue.destinationViewController as! NewFeedViewController

                vc.attachment = .Voice(feedVoice)
            }

        default:
            break
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension NewFeedVoiceRecordViewController: AVAudioRecorderDelegate {

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {

        state = .FinishRecord

        println("audioRecorderDidFinishRecording: \(flag)")
    }

    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {

        state = .Default

        println("audioRecorderEncodeErrorDidOccur: \(error)")
    }
}

// MARK: - AVAudioPlayerDelegate

extension NewFeedVoiceRecordViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {

        println("audioPlayerDidFinishPlaying: \(flag)")
    }

    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {

        println("audioPlayerDecodeErrorDidOccur: \(error)")
    }
}



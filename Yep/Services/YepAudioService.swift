//
//  YepAudioService.swift
//  Yep
//
//  Created by kevinzhow on 15/3/31.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class YepAudioService: NSObject {
    
    static let sharedManager = YepAudioService()

    var audioFileURL: NSURL?
    var audioRecorder: AVAudioRecorder?
    
    var audioPlayer: AVAudioPlayer?

    func prepareAudioRecorderWithFileURL(fileURL: NSURL, audioRecorderDelegate: AVAudioRecorderDelegate) {
        audioFileURL = fileURL

        let settings = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVEncoderAudioQualityKey : AVAudioQuality.Max.rawValue,
            AVEncoderBitRateKey : 64000,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey : 44100.0
        ]
        
        var error: NSError?
        audioRecorder = AVAudioRecorder(URL: fileURL, settings: settings as [NSObject : AnyObject], error: &error)

        if let error = error {
            println(error.localizedDescription)

        } else {
            if let audioRecorder = audioRecorder {
                audioRecorder.delegate = audioRecorderDelegate

                audioRecorder.meteringEnabled = true
                audioRecorder.prepareToRecord() // creates/overwrites the file at soundFileURL
            }
        }
    }

    var recordTimeoutAction: (() -> Void)?

    var checkRecordTimeoutTimer: NSTimer?

    func startCheckRecordTimeoutTimer() {

        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "checkRecordTimeout:", userInfo: nil, repeats: true)

        checkRecordTimeoutTimer = timer

        timer.fire()
    }

    func checkRecordTimeout(timer: NSTimer) {
        
        if audioRecorder?.currentTime > YepConfig.AudioRecord.longestDuration {

            endRecord()

            recordTimeoutAction?()

            recordTimeoutAction = nil
        }
    }

    func beginRecordWithFileURL(fileURL: NSURL, audioRecorderDelegate: AVAudioRecorderDelegate) {
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in

            if granted {

                self.prepareAudioRecorderWithFileURL(fileURL, audioRecorderDelegate: audioRecorderDelegate)

                if let audioRecorder = self.audioRecorder {

                    if (audioRecorder.recording){
                        audioRecorder.stop()

                    } else {
                        audioRecorder.record()
                        println("Audio Record did begin")
                    }
                }

            } else {
                println("Permission to record not granted")

                if let
                    appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
                    viewController = appDelegate.window?.rootViewController {

                        viewController.alertCanNotAccessMicrophone()
                }
            }
        }
    }
    
    func endRecord() {
        if let audioRecorder = audioRecorder {
            if (audioRecorder.recording){
                audioRecorder.stop()
            }
        }

        checkRecordTimeoutTimer?.invalidate()

        checkRecordTimeoutTimer = nil
    }
    
    // MARK: Audio Player
    var playingMessage: Message?
    var playbackTimer: NSTimer? {
        didSet {
            if let oldPlaybackTimer = oldValue {
                oldPlaybackTimer.invalidate()
            }
        }
    }
    func playAudioWithMessage(message: Message, beginFromTime time: NSTimeInterval, delegate: AVAudioPlayerDelegate, success: () -> Void) {

        let fileName = message.localAttachmentName

        if !fileName.isEmpty {
            
            if let fileURL = NSFileManager.yepMessageAudioURLWithName(fileName) {

                var error: NSError?
                if let audioPlayer = AVAudioPlayer(contentsOfURL: fileURL, error: &error) {
                    self.audioPlayer = audioPlayer
                    audioPlayer.delegate = delegate
                    audioPlayer.prepareToPlay()

                    playingMessage = message

                    audioPlayer.currentTime = time
                    if audioPlayer.play() {
                        println("Do Play audio \(error)")

                        success()
                    }

                } else {
                    println("play audio \(error)")
                }
            }

        } else {
            println("please wait for download") // TODO: Download audio message, check first
        }
    }
}


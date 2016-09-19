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
import YepKit
import Proposer
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


extension AVPlayer {

    var yep_playing: Bool {
        if (rate != 0 && error == nil) {
            return true
        }
        return false
    }
}

final class YepAudioService: NSObject {
    
    static let sharedManager = YepAudioService()
    
    var shouldIgnoreStart = false
    
    let queue = DispatchQueue(label: "YepAudioService", attributes: [])

    var audioFileURL: URL?
    
    var audioRecorder: AVAudioRecorder?
    
    var audioPlayer: AVAudioPlayer?

    var onlineAudioPlayer: AVPlayer?

    var audioPlayCurrentTime: TimeInterval {
        if let audioPlayer = audioPlayer {
            return audioPlayer.currentTime
        }
        return 0
    }

    var aduioOnlinePlayCurrentTime: CMTime {
        if let onlineAudioPlayerItem = onlineAudioPlayer?.currentItem {
            return onlineAudioPlayerItem.currentTime()
        }
        return CMTime()
    }

    func prepareAudioRecorderWithFileURL(_ fileURL: URL, audioRecorderDelegate: AVAudioRecorderDelegate) {

        audioFileURL = fileURL

        let settings: [String: AnyObject] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC) as AnyObject,
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue as AnyObject,
            AVEncoderBitRateKey : 64000 as AnyObject,
            AVNumberOfChannelsKey: 2 as AnyObject,
            AVSampleRateKey : 44100.0 as AnyObject
        ]
        
        do {
            let audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder.delegate = audioRecorderDelegate
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord() // creates/overwrites the file at soundFileURL

            self.audioRecorder = audioRecorder

        } catch let error {
            self.audioRecorder = nil
            println("create AVAudioRecorder error: \(error)")
        }
    }

    var recordTimeoutAction: (() -> Void)?

    var checkRecordTimeoutTimer: Timer?

    func startCheckRecordTimeoutTimer() {

        let timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(YepAudioService.checkRecordTimeout(_:)), userInfo: nil, repeats: true)

        checkRecordTimeoutTimer = timer

        timer.fire()
    }

    func checkRecordTimeout(_ timer: Timer) {
        
        if audioRecorder?.currentTime > YepConfig.AudioRecord.longestDuration {

            endRecord()

            recordTimeoutAction?()
            recordTimeoutAction = nil
        }
    }

    func beginRecordWithFileURL(_ fileURL: URL, audioRecorderDelegate: AVAudioRecorderDelegate) {

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
        } catch let error {
            println("beginRecordWithFileURL setCategory failed: \(error)")
        }

        //dispatch_async(queue) {
        do {
            //AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker,error: nil)
            //AVAudioSession.sharedInstance().setActive(true, error: nil)

            proposeToAccess(.Microphone, agreed: {
                
                self.prepareAudioRecorderWithFileURL(fileURL, audioRecorderDelegate: audioRecorderDelegate)
                
                if let audioRecorder = self.audioRecorder {
                    
                    if (audioRecorder.recording){
                        audioRecorder.stop()
                        
                    } else {
                        if !self.shouldIgnoreStart {
                            audioRecorder.record()
                            println("audio record did begin")
                        }
                    }
                }
                
            }, rejected: {
                if let
                    appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate,
                    let viewController = appDelegate.window?.rootViewController {
                        viewController.alertCanNotAccessMicrophone()
                }
            })
        }
    }
    
    func endRecord() {
        
        if let audioRecorder = self.audioRecorder {
            if audioRecorder.isRecording {
                audioRecorder.stop()
            }
        }

        queue.async {
            //AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord, withOptions: AVAudioSessionCategoryOptions.DefaultToSpeaker,error: nil)
            let _ = try? AVAudioSession.sharedInstance().setActive(false, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
        }

        self.checkRecordTimeoutTimer?.invalidate()
        self.checkRecordTimeoutTimer = nil
    }

    // MARK: Audio Player

    enum PlayingItem {
        case messageType(Message)
        case feedAudioType(FeedAudio)
    }
    var playingItem: PlayingItem?

    var playingMessage: Message? {
        guard let playingItem = playingItem else { return nil }

        if case .MessageType(let message) = playingItem {
            return message
        }

        return nil
    }
    var playingFeedAudio: FeedAudio? {
        guard let playingItem = playingItem else { return nil }

        if case .FeedAudioType(let feedAUdio) = playingItem {
            return feedAUdio
        }

        return nil
    }

    var playbackTimer: Timer? {
        didSet {
            if let oldPlaybackTimer = oldValue {
                oldPlaybackTimer.invalidate()
            }
        }
    }

    func playAudioWithMessage(_ message: Message, beginFromTime time: TimeInterval, delegate: AVAudioPlayerDelegate, success: () -> Void) {

        if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("playAudioWithMessage setCategory failed: \(error)")
            }
        }

        if let audioFileURL = message.audioFileURL {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOfURL: audioFileURL)
                self.audioPlayer = audioPlayer
                audioPlayer.delegate = delegate
                audioPlayer.prepareToPlay()

                audioPlayer.currentTime = time

                if audioPlayer.play() {
                    println("do play audio")

                    playingItem = .MessageType(message)

                    UIDevice.current.isProximityMonitoringEnabled = true

                    if !message.mediaPlayed {
                        if let realm = message.realm {
                            let _ = try? realm.write {
                                message.mediaPlayed = true
                            }
                        }
                    }

                    success()
                }

            } catch let error {
                println("play audio error: \(error)")
            }

        } else {
            println("please wait for download") // TODO: Download audio message, check first
        }
    }

    func playAudioWithFeedAudio(_ feedAudio: FeedAudio, beginFromTime time: TimeInterval, delegate: AVAudioPlayerDelegate, success: () -> Void) {

        if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("playAudioWithMessage setCategory failed: \(error)")
            }
        }

        if let audioFileURL = feedAudio.audioFileURL {
            do {
                let audioPlayer = try AVAudioPlayer(contentsOfURL: audioFileURL)
                self.audioPlayer = audioPlayer
                audioPlayer.delegate = delegate
                audioPlayer.prepareToPlay()

                audioPlayer.currentTime = time

                if audioPlayer.play() {
                    println("do play audio")

                    playingItem = .FeedAudioType(feedAudio)

                    success()
                }

            } catch let error {
                println("play audio error: \(error)")
            }

        } else {
            println("please wait for download") // TODO: Download feed audio, check first
        }
    }

    func playOnlineAudioWithFeedAudio(_ feedAudio: FeedAudio, beginFromTime time: TimeInterval, delegate: AVAudioPlayerDelegate, success: () -> Void) {

        guard let URL = URL(string: feedAudio.URLString) else {
            return
        }

        if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("playAudioWithMessage setCategory failed: \(error)")
            }
        }

        let playerItem = AVPlayerItem(URL: URL)
        let player = AVPlayer(playerItem: playerItem)
        player.rate = 1.0

        let time = CMTime(seconds: time, preferredTimescale: 1)
        playerItem.seekToTime(time)
        player.play()

        playingItem = .FeedAudioType(feedAudio)

        success()

        println("playOnlineAudioWithFeedAudio")

        self.onlineAudioPlayer = player
    }

    func tryNotifyOthersOnDeactivation() {
        // playback 会导致从音乐 App 进来的时候停止音乐，所以需要重置回去

        queue.async {
            let _ = try? AVAudioSession.sharedInstance().setActive(false, with: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation)
        }
    }

    func resetToDefault() {

        tryNotifyOthersOnDeactivation()

        // hack, wait for all observers of AVPlayerItemDidPlayToEndTimeNotification
        // to handle feedAudioDidFinishPlaying (check playingFeedAudio need playingItem)
        doInNextRunLoop { [weak self] in
            self?.playingItem = nil
        }
    }

    // MARK: Proximity

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override init() {
        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(YepAudioService.proximityStateChanged), name: NSNotification.Name.UIDeviceProximityStateDidChange, object: UIDevice.current)
    }

    func proximityStateChanged() {

        if UIDevice.current.proximityState {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            } catch let error {
                println("proximityStateChanged setCategory failed: \(error)")
            }

        } else {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("proximityStateChanged setCategory failed: \(error)")
            }
        }
    }
}


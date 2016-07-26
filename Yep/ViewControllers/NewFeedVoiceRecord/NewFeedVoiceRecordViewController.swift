//
//  NewFeedVoiceRecordViewController.swift
//  Yep
//
//  Created by nixzhu on 15/11/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import YepKit
import Proposer
import AudioBot

final class NewFeedVoiceRecordViewController: SegueViewController {

    var preparedSkill: Skill?

    var beforeUploadingFeedAction: ((feed: DiscoveredFeed, newFeedViewController: NewFeedViewController) -> Void)?
    var afterCreatedFeedAction: ((feed: DiscoveredFeed) -> Void)?
    var getFeedsViewController: (() -> FeedsViewController?)?

    @IBOutlet private weak var nextButton: UIBarButtonItem!

    @IBOutlet private weak var voiceRecordSampleView: VoiceRecordSampleView!
    @IBOutlet private weak var voiceIndicatorImageView: UIImageView!
    @IBOutlet private weak var voiceIndicatorImageViewCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var timeLabel: UILabel!
    
    @IBOutlet private weak var voiceRecordButton: RecordButton!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var resetButton: UIButton!

    private enum State {
        case Default
        case Recording
        case FinishRecord
    }
    private var state: State = .Default {
        willSet {
            switch newValue {

            case .Default:

                nextButton.enabled = false

                voiceIndicatorImageView.alpha = 0

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

                    self?.voiceRecordButton.alpha = 1
                    self?.voiceRecordButton.appearance = .Default

                    self?.playButton.alpha = 0
                    self?.resetButton.alpha = 0

                }, completion: { _ in })

                voiceRecordSampleView.reset()
                sampleValues = []
                audioPlayer?.stop()
                audioPlayer = nil
                audioPlaying = false

                playbackTimer?.invalidate()
                audioPlayedDuration = 0

                voiceIndicatorImageViewCenterXConstraint.constant = 0
                view.layoutIfNeeded()

            case .Recording:

                nextButton.enabled = false

                voiceIndicatorImageView.alpha = 0

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

                    self?.voiceRecordButton.alpha = 1
                    self?.voiceRecordButton.appearance = .Recording

                    self?.playButton.alpha = 0
                    self?.resetButton.alpha = 0

                }, completion: { _ in })

                /*
                displayLink = CADisplayLink(target: self, selector: #selector(NewFeedVoiceRecordViewController.checkVoiceRecordValue(_:)))
                displayLink?.frameInterval = 6 // 频率为每秒 10 次
                displayLink?.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
                 */

            case .FinishRecord:

                nextButton.enabled = true

                voiceIndicatorImageView.alpha = 0

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in

                    self?.voiceRecordButton.alpha = 0
                    self?.playButton.alpha = 1
                    self?.resetButton.alpha = 1
                    
                }, completion: { _ in })

                let fullWidth = voiceRecordSampleView.bounds.width

                if !voiceRecordSampleView.sampleValues.isEmpty {
                    let firstIndexPath = NSIndexPath(forItem: 0, inSection: 0)
                    voiceRecordSampleView.sampleCollectionView.scrollToItemAtIndexPath(firstIndexPath, atScrollPosition: .Left, animated: true)
                }

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.voiceIndicatorImageView.alpha = 1

                }, completion: { _ in

                    UIView.animateWithDuration(0.75, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                        self?.voiceIndicatorImageViewCenterXConstraint.constant = -fullWidth * 0.5 + 2
                        self?.view.layoutIfNeeded()
                    }, completion: { _ in })
                })

                //displayLink?.invalidate()
            }
        }
    }

    //private var voiceFileURL: NSURL?
    private var audioPlayer: AVAudioPlayer?
    //private var displayLink: CADisplayLink?

    private var sampleValues: [CGFloat] = [] {
        didSet {
            let count = sampleValues.count
            let frequency = 10
            let minutes = count / frequency / 60
            let seconds = count / frequency - minutes * 60
            let subSeconds = count - seconds * frequency - minutes * 60 * frequency

            timeLabel.text = String(format: "%02d:%02d.%d", minutes, seconds, subSeconds)
        }
    }

    private var audioPlaying: Bool = false {
        willSet {
            if newValue != audioPlaying {
                if newValue {
                    playButton.setImage(UIImage(named: "button_voice_pause"), forState: .Normal)
                } else {
                    playButton.setImage(UIImage(named: "button_voice_play"), forState: .Normal)
                }
            }
        }
    }

    private var playbackTimer: NSTimer? {
        didSet {
            if let oldPlaybackTimer = oldValue {
                oldPlaybackTimer.invalidate()
            }
        }
    }

    private var audioPlayedDuration: NSTimeInterval = 0 {
        willSet {

            guard newValue != audioPlayedDuration else {
                return
            }

            let sampleStep: CGFloat = (4 + 2)
            let fullWidth = voiceRecordSampleView.bounds.width

            let fullOffsetX = CGFloat(sampleValues.count) * sampleStep

            let currentOffsetX = CGFloat(newValue) * (10 * sampleStep)

            // 0.5 用于回去
            let duration: NSTimeInterval = newValue > audioPlayedDuration ? 0.02 : 0.5

            if fullOffsetX > fullWidth {

                if currentOffsetX <= fullWidth * 0.5 {
                    UIView.animateWithDuration(duration, delay: 0.0, options: .CurveLinear, animations: { [weak self] in
                        self?.voiceIndicatorImageViewCenterXConstraint.constant = -fullWidth * 0.5 + 2 + currentOffsetX
                        self?.view.layoutIfNeeded()
                    }, completion: { _ in })

                } else {
                    voiceRecordSampleView.sampleCollectionView.setContentOffset(CGPoint(x: currentOffsetX - fullWidth * 0.5 , y: 0), animated: false)
                }

            } else {
                UIView.animateWithDuration(duration, delay: 0.0, options: .CurveLinear, animations: { [weak self] in
                    self?.voiceIndicatorImageViewCenterXConstraint.constant = -fullWidth * 0.5 + 2 + currentOffsetX
                    self?.view.layoutIfNeeded()
                }, completion: { _ in })
            }
        }
    }

    var feedVoice: FeedVoice?

    deinit {
        //displayLink?.invalidate()
        playbackTimer?.invalidate()
        println("deinit NewFeedVoiceRecord")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Voice", comment: "")

        nextButton.title = NSLocalizedString("Next", comment: "")

        state = .Default

        // 如果进来前有声音在播放，令其停止
        if let audioPlayer = YepAudioService.sharedManager.audioPlayer where audioPlayer.playing {
            audioPlayer.pause()
        }

        if AudioBot.playing {
            AudioBot.stopPlay()
        }
    }

    // MARK: - Actions

    @IBAction private func cancel(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true) {

            AudioBot.stopRecord { _, _, _ in
            }

            /*
            self?.displayLink?.invalidate()
            self?.playbackTimer?.invalidate()

            YepAudioService.sharedManager.endRecord()

            if let voiceFileURL = self?.voiceFileURL {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(voiceFileURL)
                } catch let error {
                    println("delete voiceFileURL error: \(error)")
                }
            }
             */
        }
    }

    @IBAction private func next(sender: UIBarButtonItem) {

        if let feedVoice = feedVoice {
            performSegueWithIdentifier("showNewFeed", sender: Box(feedVoice))
        }

        /*
        guard let fileURL = voiceFileURL where !sampleValues.isEmpty else {
            return
        }

        let voiceSampleValues = sampleValues

        let finalCount = limitedAudioSamplesCount(voiceSampleValues.count)

        println("voiceSampleValues.count: \(voiceSampleValues.count)")
        println("finalCount: \(finalCount)")

        // 再做一个抽样
        let limitedSampleValues = averageSamplingFrom(voiceSampleValues, withCount: finalCount)
        println("limitedSampleValues: \(limitedSampleValues.count)")

        let feedVoice = FeedVoice(fileURL: fileURL, sampleValuesCount: voiceSampleValues.count, limitedSampleValues: limitedSampleValues)

        performSegueWithIdentifier("showNewFeed", sender: Box(feedVoice))
         */
    }

    /*
    @objc private func checkVoiceRecordValue(sender: AnyObject) {

        if let audioRecorder = YepAudioService.sharedManager.audioRecorder {

            if audioRecorder.recording {
                audioRecorder.updateMeters()
                let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)
                let value = CGFloat(normalizedValue)

                sampleValues.append(value)
                voiceRecordSampleView.appendSampleValue(value)
                //println("value: \(value)")
            }
        }
    }
     */

    @IBAction private func voiceRecord(sender: UIButton) {

        if state == .Recording {

            AudioBot.stopRecord { [weak self] fileURL, duration, decibelSamples in

                guard duration > YepConfig.AudioRecord.shortestDuration else {
                    YepAlert.alertSorry(message: NSLocalizedString("Voice recording time is too short!", comment: ""), inViewController: self, withDismissAction: { [weak self] in
                        self?.state = .Default
                    })
                    return
                }

                let compressedDecibelSamples = AudioBot.compressDecibelSamples(decibelSamples, withSamplingInterval: 1, minNumberOfDecibelSamples: 20, maxNumberOfDecibelSamples: 60)
                let feedVoice = FeedVoice(fileURL: fileURL, sampleValuesCount: decibelSamples.count, limitedSampleValues: compressedDecibelSamples.map({ CGFloat($0) }))
                self?.feedVoice = feedVoice

                self?.state = .FinishRecord
            }

            /*
            if YepAudioService.sharedManager.audioRecorder?.currentTime < YepConfig.AudioRecord.shortestDuration {

                YepAudioService.sharedManager.endRecord()

                YepAlert.alertSorry(message: NSLocalizedString("Voice recording time is too short!", comment: ""), inViewController: self, withDismissAction: { [weak self] in
                    self?.state = .Default
                })

                return
            }
            
            YepAudioService.sharedManager.endRecord()
             */

        } else {
            proposeToAccess(.Microphone, agreed: { [weak self] in

                do {
                    let decibelSamplePeriodicReport: AudioBot.PeriodicReport = (reportingFrequency: 10, report: { decibelSample in

                        SafeDispatch.async { [weak self] in
                            let value = CGFloat(decibelSample)
                            self?.sampleValues.append(value)
                            self?.voiceRecordSampleView.appendSampleValue(value)
                        }
                    })

                    AudioBot.mixWithOthersWhenRecording = true

                    try AudioBot.startRecordAudioToFileURL(nil, forUsage: .Normal, withDecibelSamplePeriodicReport: decibelSamplePeriodicReport)

                    self?.state = .Recording

                } catch let error {
                    println("record error: \(error)")
                }
                
            }, rejected: { [weak self] in
                self?.alertCanNotAccessMicrophone()
            })

            /*
            let audioFileName = NSUUID().UUIDString
            if let fileURL = NSFileManager.yepMessageAudioURLWithName(audioFileName) {

                voiceFileURL = fileURL

                YepAudioService.sharedManager.shouldIgnoreStart = false

                YepAudioService.sharedManager.beginRecordWithFileURL(fileURL, audioRecorderDelegate: self)
                
                state = .Recording
            }
             */
        }
    }

    @objc private func updateAudioPlaybackProgress(timer: NSTimer) {

        if let audioPlayer = audioPlayer {
            let currentTime = audioPlayer.currentTime
            audioPlayedDuration = currentTime
        }
    }

    @IBAction private func playOrPauseAudio(sender: UIButton) {

        guard let voiceFileURL = feedVoice?.fileURL else {
            return
        }

        // 如果在播放，就暂停
        if let audioPlayer = audioPlayer {

            if audioPlayer.playing {

                audioPlayer.pause()
                audioPlaying = false

                playbackTimer?.invalidate()

            } else {
                audioPlayer.currentTime = audioPlayedDuration
                audioPlayer.play()
                audioPlaying = true

                playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: #selector(NewFeedVoiceRecordViewController.updateAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
            }

        } else {

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

                    audioPlaying = true

                    playbackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: #selector(NewFeedVoiceRecordViewController.updateAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
                }

            } catch let error {
                println("play voice error: \(error)")
            }
        }
    }

    @IBAction private func reset(sender: UIButton) {

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

                vc.preparedSkill = preparedSkill

                vc.beforeUploadingFeedAction = beforeUploadingFeedAction
                vc.afterCreatedFeedAction = afterCreatedFeedAction
                vc.getFeedsViewController = getFeedsViewController
            }

        default:
            break
        }
    }
}

/*
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
*/

// MARK: - AVAudioPlayerDelegate

extension NewFeedVoiceRecordViewController: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {

        audioPlaying = false
        audioPlayedDuration = 0
        state = .FinishRecord

        println("audioPlayerDidFinishPlaying: \(flag)")

        YepAudioService.sharedManager.resetToDefault()
    }

    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer, error: NSError?) {

        println("audioPlayerDecodeErrorDidOccur: \(error)")

        YepAudioService.sharedManager.resetToDefault()
    }
}



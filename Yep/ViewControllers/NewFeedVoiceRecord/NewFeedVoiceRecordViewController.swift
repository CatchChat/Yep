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

                do {
                    AudioBot.stopPlay()

                    voiceRecordSampleView.reset()
                    sampleValues = []

                    audioPlaying = false
                    audioPlayedDuration = 0
                }

                nextButton.enabled = false

                voiceIndicatorImageView.alpha = 0

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.voiceRecordButton.alpha = 1
                    self?.voiceRecordButton.appearance = .Default

                    self?.playButton.alpha = 0
                    self?.resetButton.alpha = 0
                }, completion: nil)

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
                }, completion: nil)

            case .FinishRecord:

                nextButton.enabled = true

                voiceIndicatorImageView.alpha = 0

                UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.voiceRecordButton.alpha = 0
                    self?.playButton.alpha = 1
                    self?.resetButton.alpha = 1
                }, completion: nil)

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
            }
        }
    }

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
                    playButton.setImage(UIImage.yep_buttonVoicePause, forState: .Normal)
                } else {
                    playButton.setImage(UIImage.yep_buttonVoicePlay, forState: .Normal)
                }
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

    private var feedVoice: FeedVoice?

    deinit {
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
        } // TODO: delete

        AudioBot.stopPlay()
    }

    // MARK: - Actions

    @IBAction private func cancel(sender: UIBarButtonItem) {

        AudioBot.stopPlay()

        dismissViewControllerAnimated(true) {
            AudioBot.stopRecord { _, _, _ in
            }
        }
    }

    @IBAction private func next(sender: UIBarButtonItem) {

        AudioBot.stopPlay()

        if let feedVoice = feedVoice {
            performSegueWithIdentifier("showNewFeed", sender: Box(feedVoice))
        }
    }

    @IBAction private func voiceRecord(sender: UIButton) {

        if state == .Recording {

            AudioBot.stopRecord { [weak self] fileURL, duration, decibelSamples in

                guard duration > YepConfig.AudioRecord.shortestDuration else {
                    YepAlert.alertSorry(message: NSLocalizedString("Voice recording time is too short!", comment: ""), inViewController: self, withDismissAction: { [weak self] in
                        self?.state = .Default
                    })
                    return
                }

                let compressedDecibelSamples = AudioBot.compressDecibelSamples(decibelSamples, withSamplingInterval: 1, minNumberOfDecibelSamples: 10, maxNumberOfDecibelSamples: 50)
                let feedVoice = FeedVoice(fileURL: fileURL, sampleValuesCount: decibelSamples.count, limitedSampleValues: compressedDecibelSamples.map({ CGFloat($0) }))
                self?.feedVoice = feedVoice

                self?.state = .FinishRecord
            }

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
        }
    }

    @IBAction private func playOrPauseAudio(sender: UIButton) {

        if AudioBot.playing {
            AudioBot.pausePlay()

            audioPlaying = false

        } else {
            guard let fileURL = feedVoice?.fileURL else {
                return
            }

            do {
                let progressPeriodicReport: AudioBot.PeriodicReport = (reportingFrequency: 60, report: { progress in
                    //println("progress: \(progress)")
                })

                try AudioBot.startPlayAudioAtFileURL(fileURL, fromTime: audioPlayedDuration, withProgressPeriodicReport: progressPeriodicReport, finish: { [weak self] success in

                    self?.audioPlayedDuration = 0

                    if success {
                        self?.state = .FinishRecord
                    }
                })

                AudioBot.reportPlayingDuration = { [weak self] duration in
                    self?.audioPlayedDuration = duration
                }

                audioPlaying = true

            } catch let error {
                println("AudioBot: \(error)")
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


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

    var beforeUploadingFeedAction: ((_ feed: DiscoveredFeed, _ newFeedViewController: NewFeedViewController) -> Void)?
    var afterCreatedFeedAction: ((_ feed: DiscoveredFeed) -> Void)?
    var getFeedsViewController: (() -> FeedsViewController?)?

    @IBOutlet fileprivate weak var nextButton: UIBarButtonItem!

    @IBOutlet fileprivate weak var voiceRecordSampleView: VoiceRecordSampleView!
    @IBOutlet fileprivate weak var voiceIndicatorImageView: UIImageView!
    @IBOutlet fileprivate weak var voiceIndicatorImageViewCenterXConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var timeLabel: UILabel! 
    
    @IBOutlet fileprivate weak var voiceRecordButton: RecordButton!
    @IBOutlet fileprivate weak var playButton: UIButton!
    @IBOutlet fileprivate weak var resetButton: UIButton!

    fileprivate enum State {
        case `default`
        case recording
        case finishRecord
    }
    fileprivate var state: State = .default {
        willSet {
            switch newValue {

            case .default:

                do {
                    AudioBot.stopPlay()

                    voiceRecordSampleView.reset()
                    sampleValues = []

                    audioPlaying = false
                    audioPlayedDuration = 0
                }

                nextButton.isEnabled = false

                voiceIndicatorImageView.alpha = 0

                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                    self?.voiceRecordButton.alpha = 1
                    self?.voiceRecordButton.appearance = .default

                    self?.playButton.alpha = 0
                    self?.resetButton.alpha = 0
                }, completion: nil)

                voiceIndicatorImageViewCenterXConstraint.constant = 0
                view.layoutIfNeeded()

            case .recording:

                nextButton.isEnabled = false

                voiceIndicatorImageView.alpha = 0

                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                    self?.voiceRecordButton.alpha = 1
                    self?.voiceRecordButton.appearance = .recording

                    self?.playButton.alpha = 0
                    self?.resetButton.alpha = 0
                }, completion: nil)

            case .finishRecord:

                nextButton.isEnabled = true

                voiceIndicatorImageView.alpha = 0

                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                    self?.voiceRecordButton.alpha = 0
                    self?.playButton.alpha = 1
                    self?.resetButton.alpha = 1
                }, completion: nil)

                let fullWidth = voiceRecordSampleView.bounds.width

                if !voiceRecordSampleView.sampleValues.isEmpty {
                    let firstIndexPath = IndexPath(item: 0, section: 0)
                    voiceRecordSampleView.sampleCollectionView.scrollToItem(at: firstIndexPath, at: .left, animated: true)
                }

                UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                    self?.voiceIndicatorImageView.alpha = 1

                }, completion: { _ in
                    UIView.animate(withDuration: 0.75, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                        self?.voiceIndicatorImageViewCenterXConstraint.constant = -fullWidth * 0.5 + 2
                        self?.view.layoutIfNeeded()
                    }, completion: { _ in })
                })
            }
        }
    }

    fileprivate var sampleValues: [CGFloat] = [] {
        didSet {
            let count = sampleValues.count
            let frequency = 10
            let minutes = count / frequency / 60
            let seconds = count / frequency - minutes * 60
            let subSeconds = count - seconds * frequency - minutes * 60 * frequency

            timeLabel.text = String(format: "%02d:%02d.%d", minutes, seconds, subSeconds)
        }
    }

    fileprivate var audioPlaying: Bool = false {
        willSet {
            if newValue != audioPlaying {
                if newValue {
                    playButton.setImage(UIImage.yep_buttonVoicePause, for: UIControlState())
                } else {
                    playButton.setImage(UIImage.yep_buttonVoicePlay, for: UIControlState())
                }
            }
        }
    }

    fileprivate var audioPlayedDuration: TimeInterval = 0 {
        willSet {
            guard newValue != audioPlayedDuration else {
                return
            }

            let sampleStep: CGFloat = (4 + 2)
            let fullWidth = voiceRecordSampleView.bounds.width

            let fullOffsetX = CGFloat(sampleValues.count) * sampleStep

            let currentOffsetX = CGFloat(newValue) * (10 * sampleStep)

            // 0.5 用于回去
            let duration: TimeInterval = newValue > audioPlayedDuration ? 0.02 : 0.5

            if fullOffsetX > fullWidth {

                if currentOffsetX <= fullWidth * 0.5 {
                    UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: { [weak self] in
                        self?.voiceIndicatorImageViewCenterXConstraint.constant = -fullWidth * 0.5 + 2 + currentOffsetX
                        self?.view.layoutIfNeeded()
                    }, completion: { _ in })

                } else {
                    voiceRecordSampleView.sampleCollectionView.setContentOffset(CGPoint(x: currentOffsetX - fullWidth * 0.5 , y: 0), animated: false)
                }

            } else {
                UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: { [weak self] in
                    self?.voiceIndicatorImageViewCenterXConstraint.constant = -fullWidth * 0.5 + 2 + currentOffsetX
                    self?.view.layoutIfNeeded()
                }, completion: { _ in })
            }
        }
    }

    fileprivate var feedVoice: FeedVoice?

    deinit {
        println("deinit NewFeedVoiceRecord")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleNewVoice

        nextButton.title = String.trans_buttonNextStep

        state = .default

        // 如果进来前有声音在播放，令其停止
        if let audioPlayer = YepAudioService.sharedManager.audioPlayer , audioPlayer.isPlaying {
            audioPlayer.pause()
        } // TODO: delete

        AudioBot.stopPlay()
    }

    // MARK: - Actions

    @IBAction fileprivate func cancel(_ sender: UIBarButtonItem) {

        AudioBot.stopPlay()

        dismiss(animated: true) {
            AudioBot.stopRecord { _, _, _ in
            }
        }
    }

    @IBAction fileprivate func next(_ sender: UIBarButtonItem) {

        AudioBot.stopPlay()

        if let feedVoice = feedVoice {
            performSegue(withIdentifier: "showNewFeed", sender: feedVoice)
        }
    }

    @IBAction fileprivate func voiceRecord(_ sender: UIButton) {

        if state == .recording {

            AudioBot.stopRecord { [weak self] fileURL, duration, decibelSamples in

                guard duration > YepConfig.AudioRecord.shortestDuration else {
                    YepAlert.alertSorry(message: NSLocalizedString("Voice recording time is too short!", comment: ""), inViewController: self, withDismissAction: { [weak self] in
                        self?.state = .default
                    })
                    return
                }

                let compressedDecibelSamples = AudioBot.compressDecibelSamples(decibelSamples, withSamplingInterval: 1, minNumberOfDecibelSamples: 10, maxNumberOfDecibelSamples: 50)
                let feedVoice = FeedVoice(fileURL: fileURL, sampleValuesCount: decibelSamples.count, limitedSampleValues: compressedDecibelSamples.map({ CGFloat($0) }))
                self?.feedVoice = feedVoice

                self?.state = .finishRecord
            }

        } else {
            proposeToAccess(.microphone, agreed: { [weak self] in
                do {
                    let decibelSamplePeriodicReport: AudioBot.PeriodicReport = (reportingFrequency: 10, report: { decibelSample in

                        SafeDispatch.async { [weak self] in
                            let value = CGFloat(decibelSample)
                            self?.sampleValues.append(value)
                            self?.voiceRecordSampleView.appendSampleValue(value)
                        }
                    })

                    AudioBot.mixWithOthersWhenRecording = true

                    try AudioBot.startRecordAudioToFileURL(nil, forUsage: .normal, withDecibelSamplePeriodicReport: decibelSamplePeriodicReport)

                    self?.state = .recording

                } catch let error {
                    println("record error: \(error)")
                }
                
            }, rejected: { [weak self] in
                self?.alertCanNotAccessMicrophone()
            })
        }
    }

    @IBAction fileprivate func playOrPauseAudio(_ sender: UIButton) {

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

                try AudioBot.startPlayAudioAtFileURL(fileURL as URL, fromTime: audioPlayedDuration, withProgressPeriodicReport: progressPeriodicReport, finish: { [weak self] success in

                    self?.audioPlayedDuration = 0

                    if success {
                        self?.state = .finishRecord
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

    @IBAction fileprivate func reset(_ sender: UIButton) {

        state = .default
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showNewFeed":

            let vc = segue.destination as! NewFeedViewController

            let feedVoice = sender as! FeedVoice
            vc.attachment = .voice(feedVoice)

            vc.preparedSkill = preparedSkill

            vc.beforeUploadingFeedAction = beforeUploadingFeedAction
            vc.afterCreatedFeedAction = afterCreatedFeedAction
            vc.getFeedsViewController = getFeedsViewController


        default:
            break
        }
    }
}


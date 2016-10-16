//
//  FeedVoiceCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

final class FeedVoiceCell: FeedBasicCell {

    override class func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (50 + 15)

        return ceil(height)
    }

    lazy var voiceContainerView: FeedVoiceContainerView = {
        let view = FeedVoiceContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    var audioPlaying: Bool = false {
        willSet {
            voiceContainerView.audioPlaying = newValue
        }
    }
    var playOrPauseAudioAction: ((FeedVoiceCell) -> Void)?
    var audioPlayedDuration: TimeInterval = 0 {
        willSet {
            updateVoiceContainerView()
        }
    }
    /*
    private func updateVoiceContainerView() {

        guard let feed = feed, realm = try? Realm(), feedAudio = FeedAudio.feedAudioWithFeedID(feed.id, inRealm: realm) else {
            return
        }

        if let (audioDuration, audioSamples) = feedAudio.audioMetaInfo {

            voiceContainerView.voiceSampleView.samples = audioSamples
            voiceContainerView.voiceSampleView.progress = CGFloat(audioPlayedDuration / audioDuration)
        }

        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio where playingFeedAudio.feedID == feedAudio.feedID, let audioPlayer = YepAudioService.sharedManager.audioPlayer where audioPlayer.playing {
            audioPlaying = true
        } else {
            audioPlaying = false
        }
    }
    */
    fileprivate func updateVoiceContainerView() {

        guard let feed = feed, let realm = try? Realm(), let feedAudio = FeedAudio.feedAudioWithFeedID(feed.id, inRealm: realm) else {
            return
        }

        if let (audioDuration, audioSamples) = feedAudio.audioMetaInfo {

            voiceContainerView.voiceSampleView.samples = audioSamples
            voiceContainerView.voiceSampleView.progress = CGFloat(audioPlayedDuration / audioDuration)
        }

        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, playingFeedAudio.feedID == feedAudio.feedID, let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer, onlineAudioPlayer.yep_playing {
            audioPlaying = true
        } else {
            audioPlaying = false
        }
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(voiceContainerView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configureWithFeed(_ feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        super.configureWithFeed(feed, layout: layout, needShowSkill: needShowSkill)

        if let attachment = feed.attachment {
            if case let .audio(audioInfo) = attachment {

                voiceContainerView.voiceSampleView.sampleColor = UIColor.leftWaveColor()
                voiceContainerView.voiceSampleView.samples = audioInfo.sampleValues

                let timeLengthString = audioInfo.duration.yep_feedAudioTimeLengthString
                voiceContainerView.timeLengthLabel.text = timeLengthString

                let audioLayout = layout.audioLayout!
                voiceContainerView.frame = audioLayout.voiceContainerViewFrame

                if let realm = try? Realm() {

                    let feedAudio = FeedAudio.feedAudioWithFeedID(audioInfo.feedID, inRealm: realm)

                    if let feedAudio = feedAudio, let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, let audioPlayer = YepAudioService.sharedManager.audioPlayer {
                        audioPlaying = (feedAudio.feedID == playingFeedAudio.feedID) && audioPlayer.isPlaying

                    } else {
                        let newFeedAudio = FeedAudio()
                        newFeedAudio.feedID = audioInfo.feedID
                        newFeedAudio.URLString = audioInfo.URLString
                        newFeedAudio.metadata = audioInfo.metaData

                        let _ = try? realm.write {
                            realm.add(newFeedAudio)
                        }

                        audioPlaying = false
                    }

                    /*
                    let needDownload = (feedAudio == nil) || (feedAudio?.fileName ?? "").isEmpty

                    if needDownload {
                        if let URL = NSURL(string: audioInfo.URLString) {
                            YepDownloader.downloadDataFromURL(URL, reportProgress: { progress in
                                println("audio progress: \(progress)")

                            }, finishedAction: { data in
                                println("audio finish: \(data.length)")

                                SafeDispatch.async {
                                    if let realm = try? Realm() {

                                        var feedAudio = FeedAudio.feedAudioWithFeedID(audioInfo.feedID, inRealm: realm)

                                        if feedAudio == nil {
                                            let newFeedAudio = FeedAudio()
                                            newFeedAudio.feedID = audioInfo.feedID
                                            newFeedAudio.URLString = audioInfo.URLString
                                            newFeedAudio.metadata = audioInfo.metaData

                                            let _ = try? realm.write {
                                                realm.add(newFeedAudio)
                                            }

                                            feedAudio = newFeedAudio
                                        }

                                        if let feedAudio = feedAudio where feedAudio.fileName.isEmpty {

                                            let fileName = NSUUID().UUIDString
                                            if let _ = NSFileManager.saveMessageAudioData(data, withName: fileName) {
                                                let _ = try? realm.write {
                                                    feedAudio.fileName = fileName
                                                }
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                    */
                    
                    voiceContainerView.playOrPauseAudioAction = { [weak self] in
                        if let strongSelf = self {
                            strongSelf.playOrPauseAudioAction?(strongSelf)
                        }
                    }
                }
            }
        }
    }
}


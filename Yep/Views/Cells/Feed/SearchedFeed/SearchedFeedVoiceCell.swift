//
//  SearchedFeedVoiceCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

final class SearchedFeedVoiceCell: SearchedFeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (10 + 50)

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
    var playOrPauseAudioAction: (SearchedFeedVoiceCell -> Void)?
    var audioPlayedDuration: NSTimeInterval = 0 {
        willSet {
            updateVoiceContainerView()
        }
    }

    private func updateVoiceContainerView() {

        guard let feed = feed, realm = try? Realm(), feedAudio = FeedAudio.feedAudioWithFeedID(feed.id, inRealm: realm) else {
            return
        }

        if let (audioDuration, audioSamples) = feedAudio.audioMetaInfo {

            voiceContainerView.voiceSampleView.samples = audioSamples
            voiceContainerView.voiceSampleView.progress = CGFloat(audioPlayedDuration / audioDuration)
        }

        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio where playingFeedAudio.feedID == feedAudio.feedID, let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer where onlineAudioPlayer.yep_playing {
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

    override func configureWithFeed(feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        super.configureWithFeed(feed, layout: layout, keyword: keyword)

        if let attachment = feed.attachment {
            if case let .Audio(audioInfo) = attachment {

                voiceContainerView.voiceSampleView.sampleColor = UIColor.leftWaveColor()
                voiceContainerView.voiceSampleView.samples = audioInfo.sampleValues

                let timeLengthString = audioInfo.duration.yep_feedAudioTimeLengthString
                voiceContainerView.timeLengthLabel.text = timeLengthString

                let audioLayout = layout.audioLayout!
                voiceContainerView.frame = audioLayout.voiceContainerViewFrame

                if let realm = try? Realm() {

                    let feedAudio = FeedAudio.feedAudioWithFeedID(audioInfo.feedID, inRealm: realm)

                    if let feedAudio = feedAudio, playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, audioPlayer = YepAudioService.sharedManager.audioPlayer {
                        audioPlaying = (feedAudio.feedID == playingFeedAudio.feedID) && audioPlayer.playing

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


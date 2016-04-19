//
//  SearchedFeedVoiceCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class SearchedFeedVoiceCell: SearchedFeedBasicCell {

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

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
    var playOrPauseAudioAction: (FeedVoiceCell -> Void)?
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

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func configureWithFeed(feed: DiscoveredFeed, layout: SearchedFeedCellLayout) {

    }

}

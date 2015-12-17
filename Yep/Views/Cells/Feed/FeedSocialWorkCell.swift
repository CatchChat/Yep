//
//  FeedSocialWorkCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/19.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher
import Ruler
import RealmSwift
import MapKit

private let dribbbleShotHeight: CGFloat = Ruler.iPhoneHorizontal(160, 200, 220).value
private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

class FeedSocialWorkCell: FeedBasicCell {

    /*
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var logoImageViewTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var socialWorkContainerView: UIView!

    @IBOutlet weak var mediaContainerView: FeedMediaContainerView!

    @IBOutlet weak var githubRepoContainerView: FeedGithubRepoContainerView!

    @IBOutlet weak var voiceContainerView: FeedVoiceContainerView!
    @IBOutlet weak var voiceContainerViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var locationContainerView: FeedLocationContainerView!

    @IBOutlet weak var socialWorkBorderImageView: UIImageView!
    @IBOutlet weak var socialWorkContainerViewHeightConstraint: NSLayoutConstraint!
    */

    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_github")
        imageView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        return imageView
    }()

    lazy var mediaContainerView: FeedMediaContainerView = {
        let view = FeedMediaContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var githubRepoContainerView: FeedGithubRepoContainerView = {
        let view = FeedGithubRepoContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var voiceContainerView: FeedVoiceContainerView = {
        let view = FeedVoiceContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var locationContainerView: FeedLocationContainerView = {
        let view = FeedLocationContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var socialWorkBorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "social_work_border")
        return imageView
    }()








    lazy var halfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask"))
        return imageView
    }()

    var feed: DiscoveredFeed?

    var tapGithubRepoLinkAction: (NSURL -> Void)?
    var tapDribbbleShotLinkAction: (NSURL -> Void)?
    var tapDribbbleShotMediaAction: ((transitionView: UIView, image: UIImage?, imageURL: NSURL, linkURL: NSURL) -> Void)?
    var tapLocationAction: ((locationName: String, locationCoordinate: CLLocationCoordinate2D) -> Void)?

    var audioPlaying: Bool = false {
        willSet {
            voiceContainerView.audioPlaying = newValue
        }
    }
    var playOrPauseAudioAction: (FeedSocialWorkCell -> Void)?
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

        if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio where playingFeedAudio.feedID == feedAudio.feedID, let audioPlayer = YepAudioService.sharedManager.audioPlayer where audioPlayer.playing {
            audioPlaying = true
        } else {
            audioPlaying = false
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if feed?.hasSocialImage ?? false {
            halfMaskImageView.frame = mediaContainerView.mediaImageView.bounds
        }

        if feed?.hasMapImage ?? false {
            halfMaskImageView.frame = locationContainerView.mapImageView.bounds
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaContainerView.mediaImageView.image = nil
        locationContainerView.mapImageView.image = nil
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(logoImageView)
        contentView.addSubview(mediaContainerView)
        contentView.addSubview(githubRepoContainerView)
        contentView.addSubview(voiceContainerView)
        contentView.addSubview(locationContainerView)
        contentView.addSubview(socialWorkBorderImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        var height = super.heightOfFeed(feed)

        switch feed.kind {
        case .GithubRepo:
            height += (80 + 15)
        case .DribbbleShot:
            height += (dribbbleShotHeight + 15)
        case .Audio:
            height += (44 + 15)
        case .Location:
            height += (110 + 15)
        default:
            break
        }

        return ceil(height)
    }

    override func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {
        super.configureWithFeed(feed, needShowSkill: needShowSkill)

        self.feed = feed

        if let
            accountName = feed.kind.accountName,
            socialAccount = SocialAccount(rawValue: accountName) {
                logoImageView.image = UIImage(named: socialAccount.iconName)
                logoImageView.tintColor = socialAccount.tintColor
                logoImageView.hidden = false

                if needShowSkill, let _ = feed.skill {
                    logoImageView.frame.origin.x = skillButton.frame.origin.x - 8 - 18
                    logoImageView.frame.origin.y = nicknameLabel.frame.origin.y
                } else {
                    logoImageView.frame.origin.x = screenWidth - 18 - 15
                    logoImageView.frame.origin.y = nicknameLabel.frame.origin.y
                }

        } else {
            logoImageView.hidden = true
        }

        var socialWorkImageURL: NSURL?

        switch feed.kind {

        case .GithubRepo:

            mediaContainerView.hidden = true
            githubRepoContainerView.hidden = false
            voiceContainerView.hidden = true
            locationContainerView.hidden = true
            socialWorkBorderImageView.hidden = false

            if let attachment = feed.attachment {
                if case let .Github(githubRepo) = attachment {
                    githubRepoContainerView.nameLabel.text = githubRepo.name
                    githubRepoContainerView.descriptionLabel.text = githubRepo.description
                }
            }

            githubRepoContainerView.tapAction = { [weak self] in
                guard let attachment = feed.attachment else {
                    return
                }

                if case .GithubRepo = feed.kind {
                    if case let .Github(repo) = attachment, let URL = NSURL(string: repo.URLString) {
                        self?.tapGithubRepoLinkAction?(URL)
                    }
                }
            }

            //socialWorkContainerViewHeightConstraint.constant = 80
            let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
            let height: CGFloat = leftBottomLabel.frame.origin.y - y - 15
            githubRepoContainerView.frame = CGRect(x: 65, y: y, width: screenWidth - 65 - 60, height: height)

            socialWorkBorderImageView.frame = githubRepoContainerView.frame

        case .DribbbleShot:

            mediaContainerView.hidden = false
            githubRepoContainerView.hidden = true
            voiceContainerView.hidden = true
            locationContainerView.hidden = true
            socialWorkBorderImageView.hidden = false

            if let attachment = feed.attachment {
                if case let .Dribbble(dribbbleShot) = attachment {
                    socialWorkImageURL = NSURL(string: dribbbleShot.imageURLString)
                    mediaContainerView.linkContainerView.textLabel.text = dribbbleShot.title
                }
            }

            mediaContainerView.tapMediaAction = { [weak self] mediaImageView in

                guard let attachment = feed.attachment else {
                    return
                }

                if case .DribbbleShot = feed.kind {
                    if case let .Dribbble(shot) = attachment, let imageURL = NSURL(string: shot.imageURLString), let linkURL = NSURL(string: shot.htmlURLString) {
                        self?.tapDribbbleShotMediaAction?(transitionView: mediaImageView, image: mediaImageView.image, imageURL: imageURL, linkURL: linkURL)
                    }
                }
            }

            mediaContainerView.linkContainerView.tapAction = { [weak self] in

                guard let attachment = feed.attachment else {
                    return
                }

                if case .DribbbleShot = feed.kind {
                    if case let .Dribbble(shot) = attachment, let URL = NSURL(string: shot.htmlURLString) {
                        self?.tapDribbbleShotLinkAction?(URL)
                    }
                }
            }

            mediaContainerView.mediaImageView.maskView = halfMaskImageView

            //socialWorkContainerViewHeightConstraint.constant = dribbbleShotHeight
            //contentView.layoutIfNeeded()
            let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
            let height: CGFloat = leftBottomLabel.frame.origin.y - y - 15
            mediaContainerView.frame = CGRect(x: 65, y: y, width: screenWidth - 65 - 60, height: height)
            mediaContainerView.layoutIfNeeded()

            socialWorkBorderImageView.frame = mediaContainerView.frame

        case .Audio:

            mediaContainerView.hidden = true
            githubRepoContainerView.hidden = true
            voiceContainerView.hidden = false
            locationContainerView.hidden = true
            socialWorkBorderImageView.hidden = true

            if let attachment = feed.attachment {
                if case let .Audio(audioInfo) = attachment {

                    voiceContainerView.voiceSampleView.sampleColor = UIColor.leftWaveColor()
                    voiceContainerView.voiceSampleView.samples = audioInfo.sampleValues

                    let timeLengthString = String(format: "%.1f\"", audioInfo.duration)
                    voiceContainerView.timeLengthLabel.text = timeLengthString

                    let rect = timeLengthString.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.voiceTimeLengthTextAttributes, context: nil)

                    //voiceContainerViewWidthConstraint.constant = 7 + 30 + 5 + CGFloat(audioInfo.sampleValues.count) * 3 + 5 + rect.width + 5
                    let width = 7 + 30 + 5 + CGFloat(audioInfo.sampleValues.count) * 3 + 5 + rect.width + 5
                    let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15 + 2
                    voiceContainerView.frame = CGRect(x: 65, y: y, width: width, height: 40)

                    if let realm = try? Realm() {

                        let feedAudio = FeedAudio.feedAudioWithFeedID(audioInfo.feedID, inRealm: realm)

                        if let feedAudio = feedAudio, playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, audioPlayer = YepAudioService.sharedManager.audioPlayer {
                            audioPlaying = (feedAudio.feedID == playingFeedAudio.feedID) && audioPlayer.playing
                        } else {
                            audioPlaying = false
                        }

                        let needDownload = (feedAudio == nil) || (feedAudio?.fileName ?? "").isEmpty

                        if needDownload {
                            if let URL = NSURL(string: audioInfo.URLString) {
                                YepDownloader.downloadDataFromURL(URL, reportProgress: { progress in
                                    println("audio progress: \(progress)")

                                }, finishedAction: { data in
                                    println("audio finish: \(data.length)")

                                    dispatch_async(dispatch_get_main_queue()) {
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

                        voiceContainerView.playOrPauseAudioAction = { [weak self] in
                            if let strongSelf = self {
                                strongSelf.playOrPauseAudioAction?(strongSelf)
                            }
                        }
                    }
                }
            }

            //socialWorkContainerViewHeightConstraint.constant = 44

        case .Location:

            mediaContainerView.hidden = true
            githubRepoContainerView.hidden = true
            voiceContainerView.hidden = true
            locationContainerView.hidden = false
            socialWorkBorderImageView.hidden = false

            if let attachment = feed.attachment {
                if case let .Location(locationInfo) = attachment {

                    let location = CLLocation(latitude: locationInfo.latitude, longitude: locationInfo.longitude)
                    let size = CGSize(width: UIScreen.mainScreen().bounds.width - 65 - 60, height: 110 - locationContainerView.nameLabel.bounds.height)
                    locationContainerView.mapImageView.yep_showActivityIndicatorWhenLoading = true
                    locationContainerView.mapImageView.yep_setImageOfLocation(location, withSize: size)

                    if locationInfo.name.isEmpty {
                        locationContainerView.nameLabel.text = NSLocalizedString("Unknown location", comment: "")

                    } else {
                        locationContainerView.nameLabel.text = locationInfo.name
                    }
                }
            }

            locationContainerView.mapImageView.maskView = halfMaskImageView

            locationContainerView.tapAction = { [weak self] in
                guard let attachment = feed.attachment else {
                    return
                }

                if case .Location = feed.kind {
                    if case let .Location(locationInfo) = attachment {
                        self?.tapLocationAction?(locationName: locationInfo.name, locationCoordinate: locationInfo.coordinate)
                    }
                }
            }

            //socialWorkContainerViewHeightConstraint.constant = 110
            //contentView.layoutIfNeeded()
            let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
            let height: CGFloat = leftBottomLabel.frame.origin.y - y - 15
            locationContainerView.frame = CGRect(x: 65, y: y, width: screenWidth - 65 - 60, height: height)
            locationContainerView.layoutIfNeeded()

            socialWorkBorderImageView.frame = locationContainerView.frame

        default:
            break
        }

        if let URL = socialWorkImageURL {
            // ref https://github.com/onevcat/Kingfisher/pull/171
            mediaContainerView.mediaImageView.kf_showIndicatorWhenLoading = true
            mediaContainerView.mediaImageView.kf_setImageWithURL(URL, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
        }
    }
}


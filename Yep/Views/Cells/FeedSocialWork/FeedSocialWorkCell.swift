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

private let dribbbleShotHeight: CGFloat = Ruler.iPhoneHorizontal(160, 200, 220).value
private let linkContainerViewHeight: CGFloat = Ruler.iPhoneHorizontal(44, 50, 50).value

class FeedSocialWorkCell: FeedBasicCell {

    @IBOutlet weak var logoImageView: UIImageView!

    @IBOutlet weak var socialWorkContainerView: UIView!

    @IBOutlet weak var mediaContainerView: UIView!
    @IBOutlet weak var socialWorkImageView: UIImageView!

    @IBOutlet weak var linkContainerView: UIView!
    @IBOutlet weak var linkImageView: UIImageView!
    @IBOutlet weak var linkLabel: UILabel!
    @IBOutlet weak var linkAccessoryImageView: UIImageView!
    @IBOutlet weak var linkContainerViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var githubRepoContainerView: UIView!
    @IBOutlet weak var githubRepoImageView: UIImageView!
    @IBOutlet weak var githubRepoNameLabel: UILabel!
    @IBOutlet weak var githubRepoDescriptionLabel: UILabel!
    @IBOutlet weak var githubRepoAccessoryImageView: UIImageView!

    @IBOutlet weak var voiceContainerView: UIView!
    @IBOutlet weak var voiceBubbleImageVIew: UIImageView!
    @IBOutlet weak var voicePlayButton: UIButton!
    @IBOutlet weak var voiceSampleView: SampleView!
    @IBOutlet weak var voiceTimeLabel: UILabel!

    @IBOutlet weak var voiceSampleViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var socialWorkBorderImageView: UIImageView!
    @IBOutlet weak var socialWorkContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var githubRepoImageViewTrailingConstraint: NSLayoutConstraint!

    lazy var socialWorkMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask"))
        return imageView
    }()

    var feed: DiscoveredFeed?

    var tapGithubRepoLinkAction: (NSURL -> Void)?
    var tapDribbbleShotLinkAction: (NSURL -> Void)?
    var tapDribbbleShotMediaAction: ((transitionView: UIView, image: UIImage?, imageURL: NSURL, linkURL: NSURL) -> Void)?

    var audioPlaying: Bool = false {
        willSet {
            if newValue != audioPlaying {
                if newValue {
                    voicePlayButton.setImage(UIImage(named: "icon_pause"), forState: .Normal)
                } else {
                    voicePlayButton.setImage(UIImage(named: "icon_play"), forState: .Normal)
                }
            }
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

            voiceSampleView.samples = audioSamples
            voiceSampleView.progress = CGFloat(audioPlayedDuration / audioDuration)
        }
    }

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        if feed?.hasSocialImage ?? false {
            socialWorkMaskImageView.frame = socialWorkImageView.bounds
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        githubRepoAccessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        linkAccessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        voiceBubbleImageVIew.tintColor = UIColor.leftBubbleTintColor()
        voicePlayButton.tintColor = UIColor.lightGrayColor()
        voicePlayButton.tintAdjustmentMode = .Normal
        voiceTimeLabel.textColor = UIColor.lightGrayColor()

        let tapDribbbleMedia = UITapGestureRecognizer(target: self, action: "tapDribbbleMedia:")
        mediaContainerView.addGestureRecognizer(tapDribbbleMedia)

        let tapDribbbleLink = UITapGestureRecognizer(target: self, action: "tapDribbbleLink:")
        linkContainerView.addGestureRecognizer(tapDribbbleLink)

        let tapGithubLink = UITapGestureRecognizer(target: self, action: "tapGithubLink:")
        githubRepoContainerView.addGestureRecognizer(tapGithubLink)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedSocialWorkCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        var height: CGFloat = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        switch feed.kind {
        case .GithubRepo:
            height += (80 + 15)
        case .DribbbleShot:
            height += (dribbbleShotHeight + 15)
        case .Audio:
            height += (44 + 15)
        default:
            break
        }

        return ceil(height)
    }

    override func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {
        super.configureWithFeed(feed, needShowSkill: needShowSkill)

        self.feed = feed

        if needShowSkill, let skill = feed.skill {
            let rect = skill.localName.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.skillTextAttributes, context: nil)
            githubRepoImageViewTrailingConstraint.constant = 10 + (10 + rect.width + 10) + 15
        } else {
            githubRepoImageViewTrailingConstraint.constant = 15
        }

        if let
            accountName = feed.kind.accountName,
            socialAccount = SocialAccount(rawValue: accountName) {
                logoImageView.image = UIImage(named: socialAccount.iconName)
                logoImageView.tintColor = socialAccount.tintColor
                logoImageView.hidden = false

        } else {
            logoImageView.hidden = true
        }

        var socialWorkImageURL: NSURL?

        switch feed.kind {

        case .GithubRepo:

            mediaContainerView.hidden = true
            githubRepoContainerView.hidden = false
            voiceContainerView.hidden = true
            socialWorkBorderImageView.hidden = false

            githubRepoImageView.tintColor = UIColor.yepIconImageViewTintColor()

            if let attachment = feed.attachment {
                if case let .Github(githubRepo) = attachment {
                    githubRepoNameLabel.text = githubRepo.name
                    githubRepoDescriptionLabel.text = githubRepo.description
                }
            }

            socialWorkContainerViewHeightConstraint.constant = 80

        case .DribbbleShot:

            mediaContainerView.hidden = false
            githubRepoContainerView.hidden = true
            voiceContainerView.hidden = true
            socialWorkBorderImageView.hidden = false

            linkImageView.tintColor = UIColor.yepIconImageViewTintColor()

            if let attachment = feed.attachment {
                if case let .Dribbble(dribbbleShot) = attachment {
                    socialWorkImageURL = NSURL(string: dribbbleShot.imageURLString)
                    linkLabel.text = dribbbleShot.title
                }
            }

            socialWorkImageView.maskView = socialWorkMaskImageView

            linkContainerViewHeightConstraint.constant = linkContainerViewHeight
            socialWorkContainerViewHeightConstraint.constant = dribbbleShotHeight
            contentView.layoutIfNeeded()

        case .Audio:

            mediaContainerView.hidden = true
            githubRepoContainerView.hidden = true
            voiceContainerView.hidden = false
            socialWorkBorderImageView.hidden = true

            if let attachment = feed.attachment {
                if case let .Audio(audioInfo) = attachment {

                    voiceSampleView.sampleColor = UIColor.leftWaveColor()
                    voiceSampleView.samples = audioInfo.sampleValues

                    voiceTimeLabel.text = String(format: "%.1f\"", audioInfo.duration)

                    voiceSampleViewWidthConstraint.constant = CGFloat(audioInfo.sampleValues.count) * 3

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
                    }
                }
            }

            socialWorkContainerViewHeightConstraint.constant = 44

        default:
            break
        }

        if let URL = socialWorkImageURL {
            socialWorkImageView.kf_setImageWithURL(URL, placeholderImage: nil)
        }
    }

    // MARK: Actions

    @IBAction func playOrPauseAudio(sender: UIButton) {

        playOrPauseAudioAction?(self)
    }

    func tapGithubLink(sender: UITapGestureRecognizer) {

        guard let feed = feed, attachment = feed.attachment else {
            return
        }

        if case .GithubRepo = feed.kind {
            if case let .Github(repo) = attachment, let URL = NSURL(string: repo.URLString) {
                tapGithubRepoLinkAction?(URL)
            }
        }
    }

    func tapDribbbleLink(sender: UITapGestureRecognizer) {

        guard let feed = feed, attachment = feed.attachment else {
            return
        }

        if case .DribbbleShot = feed.kind {
            if case let .Dribbble(shot) = attachment, let URL = NSURL(string: shot.htmlURLString) {
                tapDribbbleShotLinkAction?(URL)
            }
        }
    }

    func tapDribbbleMedia(sender: UITapGestureRecognizer) {

        guard let feed = feed, attachment = feed.attachment else {
            return
        }

        if case .DribbbleShot = feed.kind {
            if case let .Dribbble(shot) = attachment, let imageURL = NSURL(string: shot.imageURLString), let linkURL = NSURL(string: shot.htmlURLString) {
                tapDribbbleShotMediaAction?(transitionView: socialWorkImageView, image: socialWorkImageView.image, imageURL: imageURL, linkURL: linkURL)
            }
        }
    }
}


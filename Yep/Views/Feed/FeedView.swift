//
//  FeedView.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher
import AVFoundation
import RealmSwift
import MapKit

class FeedView: UIView {

    var feed: ConversationFeed? {
        willSet {
            if let feed = newValue {
                configureWithFeed(feed)
            }
        }
    }

    var audioPlaying: Bool = false {
        willSet {
            self.voiceContainerView.audioPlaying = newValue
        }
    }
    var audioPlayedDuration: NSTimeInterval = 0 {
        willSet {
            guard let feed = feed, realm = try? Realm(), feedAudio = FeedAudio.feedAudioWithFeedID(feed.feedID, inRealm: realm) else {
                return
            }

            if let (audioDuration, _) = feedAudio.audioMetaInfo {
                self.voiceContainerView.voiceSampleView.progress = CGFloat(newValue / audioDuration)
            }
        }
    }

    var tapMediaAction: ((transitionView: UIView, image: UIImage?, attachments: [DiscoveredAttachment], index: Int) -> Void)?
    var tapGithubRepoAction: (NSURL -> Void)?
    var tapDribbbleShotAction: (NSURL -> Void)?
    var tapLocationAction: ((locationName: String, locationCoordinate: CLLocationCoordinate2D) -> Void)?
    var tapURLInfoAction: ((URL: NSURL) -> Void)?

    static let foldHeight: CGFloat = 60

    weak var heightConstraint: NSLayoutConstraint?

    class func instanceFromNib() -> FeedView {
        return UINib(nibName: "FeedView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! FeedView
    }

    var foldProgress: CGFloat = 0 {
        willSet {
            if newValue >= 0 && newValue <= 1 {

                let normalHeight = self.normalHeight
                let attachmentURLsIsEmpty = attachments.isEmpty

                UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { [weak self] in

                    self?.nicknameLabelCenterYConstraint.constant = -10 * newValue
                    self?.messageTextViewTopConstraint.constant = -25 * newValue + 4

                    if newValue == 1.0 {
                        self?.nicknameLabelTrailingConstraint.constant = attachmentURLsIsEmpty ? 15 : (5 + 40 + 15)
                        self?.messageTextViewTrailingConstraint.constant = attachmentURLsIsEmpty ? 15 : (5 + 40 + 15)
                        self?.messageTextViewHeightConstraint.constant = 20
                    }

                    if newValue == 0.0 {
                        self?.nicknameLabelTrailingConstraint.constant = 15
                        self?.messageTextViewTrailingConstraint.constant = 15
                        self?.calHeightOfMessageTextView()
                    }


                    self?.heightConstraint?.constant = FeedView.foldHeight + (normalHeight - FeedView.foldHeight) * (1 - newValue)

                    self?.layoutIfNeeded()

                    let foldingAlpha = (1 - newValue)
                    self?.distanceLabel.alpha = foldingAlpha
                    self?.mediaCollectionView.alpha = foldingAlpha
                    self?.timeLabel.alpha = foldingAlpha
                    self?.mediaView.alpha = newValue

                    self?.messageLabel.alpha = newValue
                    self?.messageTextView.alpha = foldingAlpha

                }, completion: { _ in
                })

                if newValue == 1.0 {
                    foldAction?()
                }

                if newValue == 0.0 {
                    unfoldAction?(self)
                }
            }
        }
    }

    var tapAvatarAction: (() -> Void)?
    var foldAction: (() -> Void)?
    var unfoldAction: (FeedView -> Void)?

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameLabelCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var nicknameLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var dotLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var mediaView: FeedMediaView!

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageTextView: FeedTextView!
    @IBOutlet weak var messageTextViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var mediaCollectionView: UICollectionView!

    @IBOutlet weak var socialWorkContainerView: UIView!
    @IBOutlet weak var socialWorkContainerViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var socialWorkImageView: UIImageView!

    lazy var githubRepoContainerView: FeedGithubRepoContainerView = {
        let view = FeedGithubRepoContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        view.needShowAccessoryImageView = false

        view.userInteractionEnabled = false

        view.translatesAutoresizingMaskIntoConstraints = false
        self.socialWorkContainerView.addSubview(view)

        let views = [
            "view": view
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
        
        return view
    }()

    weak var voiceContainerViewWidthConstraint: NSLayoutConstraint?
    lazy var voiceContainerView: FeedVoiceContainerView = {
        let view = FeedVoiceContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)

        view.translatesAutoresizingMaskIntoConstraints = false
        self.socialWorkContainerView.addSubview(view)

        let centerY = NSLayoutConstraint(item: view, attribute: .CenterY, relatedBy: .Equal, toItem: self.socialWorkContainerView, attribute: .CenterY, multiplier: 1.0, constant: 0)

        let leading = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self.socialWorkContainerView, attribute: .Leading, multiplier: 1.0, constant: 0)

        let width = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 160)

        self.voiceContainerViewWidthConstraint = width

        NSLayoutConstraint.activateConstraints([centerY, leading, width])

        view.playOrPauseAudioAction = { [weak self] in
            self?.playOrPauseAudio()
        }

        return view
    }()

    lazy var locationContainerView: FeedLocationContainerView = {
        let view = FeedLocationContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        view.needCompressNameLabel = true

        view.translatesAutoresizingMaskIntoConstraints = false
        self.socialWorkContainerView.addSubview(view)

        let views = [
            "view": view
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)

        let tapLocation = UITapGestureRecognizer(target: self, action: "tapLocation:")
        view.addGestureRecognizer(tapLocation)

        return view
    }()
    
    @IBOutlet weak var socialWorkBorderImageView: UIImageView!

    lazy var feedURLContainerView: FeedURLContainerView = {
        let view = FeedURLContainerView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        view.compressionMode = true

        view.translatesAutoresizingMaskIntoConstraints = false
        self.socialWorkContainerView.addSubview(view)

        let views = [
            "view": view
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)

        let tapURLInfo = UITapGestureRecognizer(target: self, action: "tapURLInfo:")
        view.addGestureRecognizer(tapURLInfo)

        return view
    }()
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!

    lazy var socialWorkHalfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask"))
        return imageView
    }()

    lazy var socialWorkFullMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask_full"))
        return imageView
    }()
    
    var attachments = [DiscoveredAttachment]() {
        didSet {
            mediaCollectionView.reloadData()
            mediaView.setImagesWithAttachments(attachments)
        }
    }

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
        }()

    let feedMediaCellID = "FeedMediaCell"

    override func layoutSubviews() {
        super.layoutSubviews()

        if feed?.hasSocialImage ?? false {
            socialWorkFullMaskImageView.frame = socialWorkImageView.bounds
        }

        if feed?.hasMapImage ?? false {
            socialWorkHalfMaskImageView.frame = locationContainerView.bounds
        }
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        println("deinit FeedView")
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = true

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageLabel.textColor = UIColor.darkGrayColor()
        messageTextView.textColor = UIColor.darkGrayColor()
        distanceLabel.textColor = UIColor.grayColor()
        timeLabel.textColor = UIColor.grayColor()
        dotLabel.textColor = UIColor.grayColor()

        messageLabel.font = UIFont.feedMessageFont()
        messageLabel.alpha = 0

        messageTextView.scrollsToTop = false
        messageTextView.font = UIFont.feedMessageFont()
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        mediaView.alpha = 0

        mediaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.backgroundColor = UIColor.clearColor()
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        let tapSwitchFold = UITapGestureRecognizer(target: self, action: "switchFold:")
        addGestureRecognizer(tapSwitchFold)
        tapSwitchFold.delegate = self

        let tapAvatar = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapAvatar)

        let tapSocialWork = UITapGestureRecognizer(target: self, action: "tapSocialWork:")
        socialWorkContainerView.addGestureRecognizer(tapSocialWork)
    }

    func switchFold(sender: UITapGestureRecognizer) {

        if foldProgress == 1 {
            foldProgress = 0
        } else if foldProgress == 0 {
            foldProgress = 1
        }
    }

    func tapAvatar(sender: UITapGestureRecognizer) {

        tapAvatarAction?()
    }
    
    var normalHeight: CGFloat {

        guard let feed = feed else {
            return FeedView.foldHeight
        }

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedView.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedView.textAttributes, context: nil)

        var height: CGFloat = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        
        if feed.hasAttachment {
            if feed.kind == .Audio {
                height += 44 + 15
            } else {
                height += 80 + 15
            }
        }

        return ceil(height)
    }

    var height: CGFloat {
        return bounds.height
    }

    private func calHeightOfMessageTextView() {

        let rect = messageTextView.text.boundingRectWithSize(CGSize(width: FeedView.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedView.textAttributes, context: nil)
        messageTextViewHeightConstraint.constant = ceil(rect.height)
    }

    private weak var audioPlaybackTimer: NSTimer?

    private func configureWithFeed(feed: ConversationFeed) {

        let message = feed.body
        messageLabel.text = message
        messageTextView.text = message

        calHeightOfMessageTextView()

        let hasAttachment = feed.hasAttachment
        timeLabelTopConstraint.constant = hasAttachment ? (15 + (feed.kind == .Audio ? 44 : 80) + 15) : 15

        attachments = feed.attachments.map({
            //DiscoveredAttachment(kind: AttachmentKind(rawValue: $0.kind)!, metadata: $0.metadata, URLString: $0.URLString)
            DiscoveredAttachment(metadata: $0.metadata, URLString: $0.URLString, image: nil)
        })

        messageLabelTrailingConstraint.constant = attachments.isEmpty ? 15 : 60

        if let creator = feed.creator {
            let userAvatar = UserAvatar(userID: creator.userID, avatarURLString: creator.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

            nicknameLabel.text = creator.nickname
        }
        
        if let distance = feed.distance {
            if distance < 1 {
                distanceLabel.text = NSLocalizedString("Nearby", comment: "")
            } else {
                distanceLabel.text = "\(distance.format(".1")) km"
            }
        }

        timeLabel.text = "\(NSDate(timeIntervalSince1970: feed.createdUnixTime).timeAgo)"


        // social works

        guard let kind = feed.kind else {
            return
        }

        var socialWorkImageURL: NSURL?

        switch kind {

        case .Text:

            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = true

        case .URL:

            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = false

            socialWorkBorderImageView.hidden = true

            socialWorkContainerViewHeightConstraint.constant = 80

            if let openGraphInfo = feed.openGraphInfo {
                feedURLContainerView.configureWithOpenGraphInfoType(openGraphInfo)
            }

        case .Image:

            mediaCollectionView.hidden = false
            socialWorkContainerView.hidden = true

            socialWorkBorderImageView.hidden = false

            socialWorkContainerViewHeightConstraint.constant = 80

        case .GithubRepo:

            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = false

            socialWorkImageView.hidden = true

            socialWorkBorderImageView.hidden = false

            socialWorkContainerViewHeightConstraint.constant = 80

            githubRepoContainerView.nameLabel.text = feed.githubRepoName
            githubRepoContainerView.descriptionLabel.text = feed.githubRepoDescription

            socialWorkBorderImageView.hidden = false
            socialWorkContainerView.bringSubviewToFront(socialWorkBorderImageView)

        case .DribbbleShot:

            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = false

            socialWorkImageView.hidden = false

            socialWorkBorderImageView.hidden = false

            socialWorkContainerViewHeightConstraint.constant = 80

            socialWorkImageView.maskView = socialWorkFullMaskImageView
            socialWorkBorderImageView.hidden = false

            socialWorkImageURL = feed.dribbbleShotImageURL

        case .Audio:

            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = false

            socialWorkImageView.hidden = true

            socialWorkBorderImageView.hidden = true

            socialWorkContainerViewHeightConstraint.constant = 44

            if let (audioDuration, audioSampleValues) = feed.audioMetaInfo {
                voiceContainerView.voiceSampleView.sampleColor = UIColor.leftWaveColor()
                let timeLengthString = audioDuration.yep_feedAudioTimeLengthString
                voiceContainerView.timeLengthLabel.text = timeLengthString
                voiceContainerView.voiceSampleView.samples = audioSampleValues

                let width = FeedVoiceContainerView.fullWidthWithSampleValuesCount(audioSampleValues.count, timeLengthString: timeLengthString)
                voiceContainerViewWidthConstraint?.constant = width
            }

            /*
            if let audioPlayer = YepAudioService.sharedManager.audioPlayer where audioPlayer.playing {
                if let feedID = YepAudioService.sharedManager.playingFeedAudio?.feedID where feedID == feed.feedID {
                    audioPlaying = true

                    audioPlaybackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateAudioPlaybackProgress:", userInfo: nil, repeats: true)
                }
            }
            */

            if let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer where onlineAudioPlayer.yep_playing {
                if let feedID = YepAudioService.sharedManager.playingFeedAudio?.feedID where feedID == feed.feedID {
                    audioPlaying = true

                    audioPlaybackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: self, selector: "updateOnlineAudioPlaybackProgress:", userInfo: nil, repeats: true)
                }
            }

        case .Location:

            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = false

            socialWorkImageView.hidden = true

            if let locationCoordinate = feed.locationCoordinate {

                locationContainerView.layoutIfNeeded()

                let size = CGSize(width: UIScreen.mainScreen().bounds.width - 65 - 60, height: 80 - locationContainerView.nameLabel.bounds.height)

                ImageCache.sharedInstance.mapImageOfLocationCoordinate(locationCoordinate, withSize: size, completion: { [weak self] image in
                    self?.locationContainerView.mapImageView.image = image
                })
            }

            locationContainerView.nameLabel.text = feed.locationName
            locationContainerView.mapImageView.maskView = socialWorkHalfMaskImageView

            socialWorkBorderImageView.hidden = false
            socialWorkContainerView.bringSubviewToFront(socialWorkBorderImageView)

        default:
            break
        }
        
        if let URL = socialWorkImageURL {
            socialWorkImageView.kf_setImageWithURL(URL, placeholderImage: nil)
        }
    }

    func tapSocialWork(sender: UITapGestureRecognizer) {

        guard let kind = feed?.kind else {
            return
        }

        switch kind {

        case .GithubRepo:

            if let URL = feed?.githubRepoURL {
                tapGithubRepoAction?(URL)
            }

        case .DribbbleShot:

            if let URL = feed?.dribbbleShotURL {
                tapDribbbleShotAction?(URL)

            }
            
        default:
            break
        }
    }

    func tapLocation(sender: UITapGestureRecognizer) {

        guard let locationName = feed?.locationName, locationCoordinate = feed?.locationCoordinate else {
            return
        }

        tapLocationAction?(locationName: locationName, locationCoordinate: locationCoordinate)
    }

    func tapURLInfo(sender: UITapGestureRecognizer) {
        guard let URL = feed?.openGraphInfo?.URL else {
            return
        }

        tapURLInfoAction?(URL: URL)
    }

    var syncPlayAudioAction: (() -> Void)?

    /*
    @IBAction func playOrPauseAudio(sender: UIButton) {

        if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("playVoice setCategory failed: \(error)")
                return
            }
        }

        guard let realm = try? Realm(), feed = feed, feedAudio = FeedAudio.feedAudioWithFeedID(feed.feedID, inRealm: realm) else {
            return
        }

        func play() {

            YepAudioService.sharedManager.playAudioWithFeedAudio(feedAudio, beginFromTime: audioPlayedDuration, delegate: self, success: { [weak self] in
                println("playAudioWithFeedAudio success!")

                if let strongSelf = self {

                    strongSelf.audioPlaybackTimer?.invalidate()
                    strongSelf.audioPlaybackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: strongSelf, selector: "updateAudioPlaybackProgress:", userInfo: nil, repeats: true)

                    YepAudioService.sharedManager.playbackTimer = strongSelf.audioPlaybackTimer

                    strongSelf.audioPlaying = true

                    strongSelf.syncPlayAudioAction?()
                }
            })
        }

        // 如果在播放，就暂停
        if let audioPlayer = YepAudioService.sharedManager.audioPlayer where audioPlayer.playing {

            audioPlayer.pause()

            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                playbackTimer.invalidate()
            }

            audioPlaying = false

            if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio where playingFeedAudio.feedID == feed.feedID {
            } else {
                // 暂停的是别人，咱开始播放
                play()
            }

        } else {
            // 直接播放
            play()
        }
    }

    func updateAudioPlaybackProgress(timer: NSTimer) {

        audioPlayedDuration = YepAudioService.sharedManager.audioPlayCurrentTime
    }
    */

    private func playOrPauseAudio() {

        if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("playVoice setCategory failed: \(error)")
                return
            }
        }

        guard let realm = try? Realm(), feed = feed, feedAudio = FeedAudio.feedAudioWithFeedID(feed.feedID, inRealm: realm) else {
            return
        }

        func play() {

            YepAudioService.sharedManager.playOnlineAudioWithFeedAudio(feedAudio, beginFromTime: audioPlayedDuration, delegate: self, success: { [weak self] in
                println("playOnlineAudioWithFeedAudio success!")

                if let strongSelf = self {

                    NSNotificationCenter.defaultCenter().addObserver(strongSelf, selector: "feedAudioDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)

                    strongSelf.audioPlaybackTimer?.invalidate()
                    strongSelf.audioPlaybackTimer = NSTimer.scheduledTimerWithTimeInterval(0.02, target: strongSelf, selector: "updateOnlineAudioPlaybackProgress:", userInfo: nil, repeats: true)

                    YepAudioService.sharedManager.playbackTimer = strongSelf.audioPlaybackTimer

                    strongSelf.audioPlaying = true

                    strongSelf.syncPlayAudioAction?()
                }
            })
        }

        // 如果在播放，就暂停
        if let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer where onlineAudioPlayer.yep_playing {

            onlineAudioPlayer.pause()

            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                playbackTimer.invalidate()
            }

            audioPlaying = false

            if let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio where playingFeedAudio.feedID == feed.feedID {
                YepAudioService.sharedManager.tryNotifyOthersOnDeactivation()

            } else {
                // 暂停的是别人，咱开始播放
                play()
            }
            
        } else {
            // 直接播放
            play()
        }
    }

    @objc private func updateOnlineAudioPlaybackProgress(timer: NSTimer) {

        audioPlayedDuration = YepAudioService.sharedManager.aduioOnlinePlayCurrentTime.seconds
    }
}

// MARK: - UIGestureRecognizerDelegate

extension FeedView: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        let location = touch.locationInView(mediaCollectionView)

        if CGRectContainsPoint(mediaCollectionView.bounds, location) {
            return false
        }

        return true
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension FeedView: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedMediaCellID, forIndexPath: indexPath) as! FeedMediaCell

        let attachment = attachments[indexPath.item]

        //println("attachment imageURL: \(imageURL)")
        
        cell.configureWithAttachment(attachment, bigger: (attachments.count == 1))

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSize(width: 80, height: 80)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FeedMediaCell

        let transitionView = cell.imageView
        tapMediaAction?(transitionView: transitionView, image: cell.imageView.image, attachments: attachments, index: indexPath.item)
    }
}

// MARK: Audio Finish Playing

extension FeedView {

    private func feedAudioDidFinishPlaying() {

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        audioPlayedDuration = 0
        audioPlaying = false

        YepAudioService.sharedManager.resetToDefault()
    }

    @objc private func feedAudioDidFinishPlaying(notification: NSNotification) {
        feedAudioDidFinishPlaying()
    }
}

// MARK: AVAudioPlayerDelegate

extension FeedView: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {

        println("audioPlayerDidFinishPlaying \(flag)")

        feedAudioDidFinishPlaying()
    }
}


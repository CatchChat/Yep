//
//  FeedView.swift
//  Yep
//
//  Created by nixzhu on 15/9/25.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation
import MapKit
import YepKit
import YepPreview
import RealmSwift
import Kingfisher
import RxSwift

final class FeedView: UIView {

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
    var audioPlayedDuration: TimeInterval = 0 {
        willSet {
            guard let feedID = feed?.feedID, let realm = try? Realm(), let feedAudio = FeedAudio.feedAudioWithFeedID(feedID, inRealm: realm) else {
                return
            }

            if let (audioDuration, _) = feedAudio.audioMetaInfo {
                self.voiceContainerView.voiceSampleView.progress = CGFloat(newValue / audioDuration)
            }
        }
    }

    var tapImagesAction: ((_ references: [Reference?], _ attachments: [DiscoveredAttachment], _ image: UIImage?, _ index: Int) -> Void)?

    var tapGithubRepoAction: ((URL) -> Void)?
    var tapDribbbleShotAction: ((URL) -> Void)?
    var tapLocationAction: ((_ locationName: String, _ locationCoordinate: CLLocationCoordinate2D) -> Void)?
    var tapURLInfoAction: ((_ URL: URL) -> Void)?

    static let foldHeight: CGFloat = 60

    weak var heightConstraint: NSLayoutConstraint?

    class func instanceFromNib() -> FeedView {
        return UINib(nibName: "FeedView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! FeedView
    }

    var foldProgress: CGFloat = 0 {
        willSet {
            guard newValue >= 0 && newValue <= 1 else {
                return
            }

            let normalHeight = self.normalHeight
            let attachmentURLsIsEmpty = attachments.isEmpty

            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(rawValue: 0), animations: { [weak self] in

                self?.nicknameLabelCenterYConstraint.constant = -10 * newValue
                self?.messageTextViewTopConstraint.constant = -25 * newValue + 4

                if newValue == 1.0 {
                    self?.usernameLabelTrailingConstraint.constant = attachmentURLsIsEmpty ? 15 : (5 + 40 + 15)
                    self?.messageTextViewTrailingConstraint.constant = attachmentURLsIsEmpty ? 15 : (5 + 40 + 15)
                    self?.messageTextViewHeightConstraint.constant = 20
                }

                if newValue == 0.0 {
                    self?.usernameLabelTrailingConstraint.constant = 15
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

    var tapAvatarAction: (() -> Void)?
    var foldAction: (() -> Void)?
    var unfoldAction: ((FeedView) -> Void)?

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameLabelCenterYConstraint: NSLayoutConstraint!
    @IBOutlet weak var usernameLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var dotLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var mediaView: FeedMediaView!

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var messageLabelTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageTextView: FeedTextView! {
        didSet {
            messageTextView.isScrollEnabled = false
        }
    }
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

        view.isUserInteractionEnabled = false

        view.translatesAutoresizingMaskIntoConstraints = false
        self.socialWorkContainerView.addSubview(view)

        let views: [String: Any] = [
            "view": view
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)
        
        return view
    }()

    weak var voiceContainerViewWidthConstraint: NSLayoutConstraint?
    lazy var voiceContainerView: FeedVoiceContainerView = {
        let view = FeedVoiceContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)

        view.translatesAutoresizingMaskIntoConstraints = false
        self.socialWorkContainerView.addSubview(view)

        let centerY = NSLayoutConstraint(item: view, attribute: .centerY, relatedBy: .equal, toItem: self.socialWorkContainerView, attribute: .centerY, multiplier: 1.0, constant: 0)

        let leading = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self.socialWorkContainerView, attribute: .leading, multiplier: 1.0, constant: 0)

        let width = NSLayoutConstraint(item: view, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 160)

        self.voiceContainerViewWidthConstraint = width

        NSLayoutConstraint.activate([centerY, leading, width])

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

        let views: [String: Any] = [
            "view": view
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)

        let tapLocation = UITapGestureRecognizer(target: self, action: #selector(FeedView.tapLocation(_:)))
        view.addGestureRecognizer(tapLocation)

        return view
    }()
    
    @IBOutlet weak var socialWorkBorderImageView: UIImageView!

    lazy var feedURLContainerView: FeedURLContainerView = {
        let view = FeedURLContainerView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        view.compressionMode = true

        view.translatesAutoresizingMaskIntoConstraints = false
        self.socialWorkContainerView.addSubview(view)

        let views: [String: Any] = [
            "view": view
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)

        let tapURLInfo = UITapGestureRecognizer(target: self, action: #selector(FeedView.tapURLInfo(_:)))
        view.addGestureRecognizer(tapURLInfo)

        return view
    }()
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!

    lazy var socialWorkHalfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_socialMediaImageMask)
        return imageView
    }()

    lazy var socialWorkFullMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_socialMediaImageMaskFull)
        return imageView
    }()
    
    var attachments = [DiscoveredAttachment]() {
        didSet {
            mediaCollectionView.reloadData()
            mediaView.setImagesWithAttachments(attachments)
        }
    }

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.main.bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        if feed?.hasSocialImage ?? false {
            socialWorkFullMaskImageView.frame = socialWorkImageView.bounds
        }

        if feed?.hasMapImage ?? false {
            socialWorkHalfMaskImageView.frame = locationContainerView.bounds
        }
    }

    fileprivate var disposableTimer: Disposable?

    deinit {
        NotificationCenter.default.removeObserver(self)

        disposableTimer?.dispose()

        println("deinit FeedView")
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        clipsToBounds = true

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageLabel.textColor = UIColor.darkGray
        messageTextView.textColor = UIColor.darkGray
        distanceLabel.textColor = UIColor.gray
        timeLabel.textColor = UIColor.gray
        dotLabel.textColor = UIColor.gray

        usernameLabel.isHidden = true
        usernameLabel.text = nil

        messageLabel.font = UIFont.feedMessageFont()
        messageLabel.alpha = 0

        messageTextView.scrollsToTop = false
        messageTextView.font = UIFont.feedMessageFont()
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        mediaView.alpha = 0

        mediaCollectionView.contentInset = UIEdgeInsets(top: 0, left: 15 + 40 + 10, bottom: 0, right: 15)
        mediaCollectionView.showsHorizontalScrollIndicator = false
        mediaCollectionView.backgroundColor = UIColor.clear

        mediaCollectionView.registerNibOf(FeedMediaCell.self)

        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

        let tapToggleFold = UITapGestureRecognizer(target: self, action: #selector(FeedView.toggleFold(_:)))
        addGestureRecognizer(tapToggleFold)
        tapToggleFold.delegate = self

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(FeedView.tapAvatar(_:)))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapAvatar)

        let tapSocialWork = UITapGestureRecognizer(target: self, action: #selector(FeedView.tapSocialWork(_:)))
        socialWorkContainerView.addGestureRecognizer(tapSocialWork)

        NotificationCenter.default.addObserver(self, selector: #selector(FeedView.feedAudioDidFinishPlaying(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }

    func toggleFold(_ sender: UITapGestureRecognizer) {

        if foldProgress == 1 {
            foldProgress = 0

        } else if foldProgress == 0 {
            foldProgress = 1
        }
    }

    func tapAvatar(_ sender: UITapGestureRecognizer) {

        tapAvatarAction?()
    }
    
    var normalHeight: CGFloat {

        guard let feed = feed else {
            return FeedView.foldHeight
        }

        let rect = feed.body.boundingRect(with: CGSize(width: FeedView.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: YepConfig.FeedView.textAttributes, context: nil)

        var height: CGFloat = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        
        if feed.hasAttachment {
            if feed.kind == .audio {
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

    fileprivate func calHeightOfMessageTextView() {

        let rect = messageTextView.text.boundingRect(with: CGSize(width: FeedView.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: YepConfig.FeedView.textAttributes, context: nil)
        messageTextViewHeightConstraint.constant = ceil(rect.height)
    }

    fileprivate weak var audioPlaybackTimer: Timer?

    fileprivate func configureWithFeed(_ feed: ConversationFeed) {

        let message = feed.body
        messageLabel.text = message
        messageTextView.text = message

        calHeightOfMessageTextView()

        let hasAttachment = feed.hasAttachment
        timeLabelTopConstraint.constant = hasAttachment ? (15 + (feed.kind == .audio ? 44 : 80) + 15) : 15

        attachments = feed.attachments.map({
            //DiscoveredAttachment(kind: AttachmentKind(rawValue: $0.kind)!, metadata: $0.metadata, URLString: $0.URLString)
            DiscoveredAttachment(metadata: $0.metadata, URLString: $0.URLString, image: nil)
        })

        messageLabelTrailingConstraint.constant = attachments.isEmpty ? 15 : 60

        if let creator = feed.creator {
            let userAvatar = UserAvatar(userID: creator.userID, avatarURLString: creator.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

            nicknameLabel.text = creator.nickname
            //usernameLabel.text = creator.mentionedUsername
        }

        if let distance = feed.distance {
            if distance < 1 {
                distanceLabel.text = String.trans_titleNearby
            } else {
                distanceLabel.text = "\(distance.yep_format(".1")) km"
            }
        }

        let configureTimeLabel: () -> Void = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.timeLabel.text = feed.timeString
        }
        configureTimeLabel()
        disposableTimer = Observable<Int>
            .interval(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                configureTimeLabel()
            })

        // social works

        guard let kind = feed.kind else {
            return
        }

        var socialWorkImageURL: URL?

        switch kind {

        case .text:

            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = true

        case .url:

            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = false

            socialWorkBorderImageView.isHidden = true

            socialWorkContainerViewHeightConstraint.constant = 80

            if let openGraphInfo = feed.openGraphInfo {
                feedURLContainerView.configureWithOpenGraphInfoType(openGraphInfo)
            }

        case .image:

            mediaCollectionView.isHidden = false
            socialWorkContainerView.isHidden = true

            socialWorkBorderImageView.isHidden = false

            socialWorkContainerViewHeightConstraint.constant = 80

        case .githubRepo:

            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = false

            socialWorkImageView.isHidden = true

            socialWorkBorderImageView.isHidden = false

            socialWorkContainerViewHeightConstraint.constant = 80

            githubRepoContainerView.nameLabel.text = feed.githubRepoName
            githubRepoContainerView.descriptionLabel.text = feed.githubRepoDescription

            socialWorkBorderImageView.isHidden = false
            socialWorkContainerView.bringSubview(toFront: socialWorkBorderImageView)

        case .dribbbleShot:

            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = false

            socialWorkImageView.isHidden = false

            socialWorkBorderImageView.isHidden = false

            socialWorkContainerViewHeightConstraint.constant = 80

            socialWorkImageView.mask = socialWorkFullMaskImageView
            socialWorkBorderImageView.isHidden = false

            socialWorkImageURL = feed.dribbbleShotImageURL as URL?

        case .audio:

            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = false

            socialWorkImageView.isHidden = true

            socialWorkBorderImageView.isHidden = true

            socialWorkContainerViewHeightConstraint.constant = 44

            if let (audioDuration, audioSampleValues) = feed.audioMetaInfo {
                voiceContainerView.voiceSampleView.sampleColor = UIColor.leftWaveColor()
                let timeLengthString = audioDuration.yep_feedAudioTimeLengthString
                voiceContainerView.timeLengthLabel.text = timeLengthString
                voiceContainerView.voiceSampleView.samples = audioSampleValues

                let width = FeedVoiceContainerView.fullWidthWithSampleValuesCount(audioSampleValues.count, timeLengthString: timeLengthString)
                voiceContainerViewWidthConstraint?.constant = width
            }

            if let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer, onlineAudioPlayer.yep_playing {
                if let feedID = YepAudioService.sharedManager.playingFeedAudio?.feedID, feedID == feed.feedID {
                    audioPlaying = true

                    audioPlaybackTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self, selector: #selector(FeedView.updateOnlineAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)
                }
            }

        case .location:

            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = false

            socialWorkImageView.isHidden = true

            if let locationCoordinate = feed.locationCoordinate {

                locationContainerView.layoutIfNeeded()

                let size = CGSize(width: UIScreen.main.bounds.width - 65 - 60, height: 80 - locationContainerView.nameLabel.bounds.height)

                YepImageCache.sharedInstance.mapImageOfLocationCoordinate(locationCoordinate, withSize: size, completion: { [weak self] image in
                    self?.locationContainerView.mapImageView.image = image
                })
            }

            locationContainerView.nameLabel.text = feed.locationName
            locationContainerView.mapImageView.mask = socialWorkHalfMaskImageView

            socialWorkBorderImageView.isHidden = false
            socialWorkContainerView.bringSubview(toFront: socialWorkBorderImageView)

        default:
            break
        }
        
        if let url = socialWorkImageURL {
            socialWorkImageView.kf.setImage(with: url, placeholder: nil)
        }
    }

    func tapSocialWork(_ sender: UITapGestureRecognizer) {

        guard let kind = feed?.kind else {
            return
        }

        switch kind {

        case .githubRepo:

            if let URL = feed?.githubRepoURL {
                tapGithubRepoAction?(URL as URL)
            }

        case .dribbbleShot:

            if let URL = feed?.dribbbleShotURL {
                tapDribbbleShotAction?(URL as URL)

            }
            
        default:
            break
        }
    }

    func tapLocation(_ sender: UITapGestureRecognizer) {

        guard let locationName = feed?.locationName, let locationCoordinate = feed?.locationCoordinate else {
            return
        }

        tapLocationAction?(locationName, locationCoordinate)
    }

    func tapURLInfo(_ sender: UITapGestureRecognizer) {

        guard let url = feed?.openGraphInfo?.url else {
            return
        }

        tapURLInfoAction?(url)
    }

    var syncPlayAudioAction: (() -> Void)?

    fileprivate func playOrPauseAudio() {

        if AVAudioSession.sharedInstance().category == AVAudioSessionCategoryRecord {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch let error {
                println("playVoice setCategory failed: \(error)")
                return
            }
        }

        guard let realm = try? Realm(), let feedID = feed?.feedID, let feedAudio = FeedAudio.feedAudioWithFeedID(feedID, inRealm: realm) else {
            return
        }

        func play() {

            YepAudioService.sharedManager.playOnlineAudioWithFeedAudio(feedAudio, beginFromTime: audioPlayedDuration, delegate: self, success: { [weak self] in
                println("playOnlineAudioWithFeedAudio success!")

                if let strongSelf = self {

                    strongSelf.audioPlaybackTimer?.invalidate()
                    strongSelf.audioPlaybackTimer = Timer.scheduledTimer(timeInterval: 0.02, target: strongSelf, selector: #selector(FeedView.updateOnlineAudioPlaybackProgress(_:)), userInfo: nil, repeats: true)

                    YepAudioService.sharedManager.playbackTimer = strongSelf.audioPlaybackTimer

                    strongSelf.audioPlaying = true

                    strongSelf.syncPlayAudioAction?()
                }
            })
        }

        // 如果在播放，就暂停
        if let onlineAudioPlayer = YepAudioService.sharedManager.onlineAudioPlayer, onlineAudioPlayer.yep_playing {

            onlineAudioPlayer.pause()

            if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
                playbackTimer.invalidate()
            }

            audioPlaying = false

            if let feedID = feed?.feedID, let playingFeedAudio = YepAudioService.sharedManager.playingFeedAudio, playingFeedAudio.feedID == feedID {
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

    @objc fileprivate func updateOnlineAudioPlaybackProgress(_ timer: Timer) {

        audioPlayedDuration = YepAudioService.sharedManager.aduioOnlinePlayCurrentTime.seconds
    }
}

// MARK: - UIGestureRecognizerDelegate

extension FeedView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        let location = touch.location(in: mediaCollectionView)

        if mediaCollectionView.bounds.contains(location) {
            return false
        }

        return true
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension FeedView: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell: FeedMediaCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

        let attachment = attachments[indexPath.item]

        //println("attachment imageURL: \(imageURL)")
        
        cell.configureWithAttachment(attachment, bigger: (attachments.count == 1))

        return cell
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {

        return CGSize(width: 80, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! FeedMediaCell

//        let transitionView = cell.imageView
//        tapMediaAction?(transitionView: transitionView, image: cell.imageView.image, attachments: attachments, index: indexPath.item)

        let references: [Reference?] = (0..<attachments.count).map({
            let cell = collectionView.cellForItem(at: IndexPath(item: $0, section: indexPath.section)) as? FeedMediaCell
            return cell?.transitionReference
        })
        tapImagesAction?(references, attachments, cell.imageView.image, indexPath.item)
    }
}

// MARK: Audio Finish Playing

extension FeedView {

    fileprivate func feedAudioDidFinishPlaying() {

        if let playbackTimer = YepAudioService.sharedManager.playbackTimer {
            playbackTimer.invalidate()
        }

        audioPlayedDuration = 0
        audioPlaying = false

        YepAudioService.sharedManager.resetToDefault()
    }

    @objc fileprivate func feedAudioDidFinishPlaying(_ notification: Notification) {
        feedAudioDidFinishPlaying()
    }
}

// MARK: AVAudioPlayerDelegate

extension FeedView: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {

        println("audioPlayerDidFinishPlaying \(flag)")

        feedAudioDidFinishPlaying()
    }
}


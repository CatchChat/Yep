//
//  NewFeedViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices.UTType
import Photos
import YepKit
import YepNetworking
import YepPreview
import OpenGraph
import Proposer
import RealmSwift
import Kingfisher
import MapKit

struct FeedVoice {

    let fileURL: URL
    let sampleValuesCount: Int
    let limitedSampleValues: [CGFloat]
}

final class NewFeedViewController: SegueViewController {

    static let generalSkill = Skill(category: nil, id: "", name: "general", localName: String.trans_promptChoose, coverURLString: nil)

    enum Attachment {
        case `default`
        case socialWork(MessageSocialWork)
        case voice(FeedVoice)
        case location(PickLocationViewControllerLocation)

        var needPrepare: Bool {
            switch self {
            case .default:
                return false
            case .socialWork:
                return false
            case .voice:
                return true
            case .location:
                return true
            }
        }
    }

    var attachment: Attachment = .default
    
    var beforeUploadingFeedAction: ((_ feed: DiscoveredFeed, _ newFeedViewController: NewFeedViewController) -> Void)?
    var afterCreatedFeedAction: ((_ feed: DiscoveredFeed) -> Void)?

    var preparedSkill: Skill?

    weak var feedsViewController: FeedsViewController?
    var getFeedsViewController: (() -> FeedsViewController?)?


    @IBOutlet fileprivate weak var feedWhiteBGView: UIView!
    
    @IBOutlet fileprivate weak var messageTextView: UITextView!

    @IBOutlet fileprivate weak var mediaCollectionView: UICollectionView!
    @IBOutlet fileprivate weak var mediaCollectionViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var socialWorkContainerView: UIView!
    @IBOutlet fileprivate weak var socialWorkImageView: UIImageView!
    @IBOutlet fileprivate weak var githubRepoContainerView: UIView!
    @IBOutlet fileprivate weak var githubRepoImageView: UIImageView!
    @IBOutlet fileprivate weak var githubRepoNameLabel: UILabel!
    @IBOutlet fileprivate weak var githubRepoDescriptionLabel: UILabel!

    @IBOutlet fileprivate weak var voiceContainerView: UIView!
    @IBOutlet fileprivate weak var voiceBubbleImageVIew: UIImageView!
    @IBOutlet fileprivate weak var voicePlayButton: UIButton!
    @IBOutlet fileprivate weak var voiceSampleView: SampleView!
    @IBOutlet fileprivate weak var voiceTimeLabel: UILabel!

    @IBOutlet fileprivate weak var voiceSampleViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var locationContainerView: UIView!
    @IBOutlet fileprivate weak var locationMapImageView: UIImageView!
    @IBOutlet fileprivate weak var locationNameLabel: UILabel!

    @IBOutlet fileprivate weak var channelView: UIView!
    @IBOutlet fileprivate weak var channelViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var channelViewTopLineView: HorizontalLineView!
    @IBOutlet fileprivate weak var channelViewBottomLineView: HorizontalLineView!
    
    @IBOutlet fileprivate weak var channelLabel: UILabel!
    @IBOutlet fileprivate weak var choosePromptLabel: UILabel!
    
    @IBOutlet fileprivate weak var pickedSkillBubbleImageView: UIImageView!
    @IBOutlet fileprivate weak var pickedSkillLabel: UILabel!
    
    @IBOutlet fileprivate weak var skillPickerView: UIPickerView!

    fileprivate lazy var socialWorkHalfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_socialMediaImageMask)
        return imageView
    }()

    fileprivate lazy var socialWorkFullMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_socialMediaImageMaskFull)
        return imageView
    }()

    fileprivate let placeholderOfFeed = String.trans_promptNewFeedPlaceholder

    fileprivate var isNeverInputMessage = true
    fileprivate var isDirty = false {
        willSet {
            postButton.isEnabled = newValue

            if !newValue && isNeverInputMessage {
                messageTextView.text = placeholderOfFeed
            }

            messageTextView.textColor = newValue ? UIColor.black : UIColor.lightGray
        }
    }

    fileprivate lazy var postButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: String.trans_buttonPost, style: .plain, target: self, action: #selector(NewFeedViewController.tryPost(_:)))
            button.isEnabled = false
        return button
    }()

    fileprivate lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = false
        return imagePicker
    }()
    
    fileprivate var imageAssets: [PHAsset] = []
    
    fileprivate var mediaImages = [UIImage]()

    enum UploadState {
        case ready
        case uploading
        case failed(message: String)
        case success
    }
    var uploadState: UploadState = .ready {
        willSet {
            switch newValue {

            case .ready:
                break

            case .uploading:
                postButton.isEnabled = false
                messageTextView.resignFirstResponder()
                YepHUD.showActivityIndicator()

            case .failed(let message):
                YepHUD.hideActivityIndicator()
                postButton.isEnabled = true

                if presentingViewController != nil {
                    YepAlert.alertSorry(message: message, inViewController: self)
                } else {
                    feedsViewController?.handleUploadingErrorMessage(message)
                }

            case .success:
                YepHUD.hideActivityIndicator()
                messageTextView.text = nil
            }
        }
    }
    
    fileprivate let skills: [Skill] = {
        guard let me = me() else {
            return []
        }

        var skills = skillsFromUserSkillList(me.masterSkills) + skillsFromUserSkillList(me.learningSkills)
        skills.insert(NewFeedViewController.generalSkill, at: 0)
        return skills
    }()
    
    fileprivate var pickedSkill: Skill? {
        willSet {
            pickedSkillLabel.text = newValue?.localName
            choosePromptLabel.isHidden = (newValue != nil)
        }
    }

    fileprivate var previewReferences: [Reference?]?
    fileprivate var previewNewFeedPhotos: [PreviewNewFeedPhoto] = []

    deinit {
        println("NewFeed deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = NavigationTitleLabel(title: String.trans_titleNewFeed)
        view.backgroundColor = UIColor.yepBackgroundColor()
        
        navigationItem.rightBarButtonItem = postButton

        if !attachment.needPrepare {
            let cancleButton = UIBarButtonItem(title: String.trans_cancel, style: .plain, target: self, action: #selector(NewFeedViewController.cancel(_:)))

            navigationItem.leftBarButtonItem = cancleButton
        }
        
        view.sendSubview(toBack: feedWhiteBGView)

        feedsViewController = getFeedsViewController?()
        println("feedsViewController: \(feedsViewController)")
        
        isDirty = false

        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        messageTextView.delegate = self
        //messageTextView.becomeFirstResponder()
        
        mediaCollectionView.backgroundColor = UIColor.clear

        mediaCollectionView.registerNibOf(FeedMediaAddCell.self)
        mediaCollectionView.registerNibOf(FeedMediaCell.self)

        mediaCollectionView.contentInset.left = 15
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self
        mediaCollectionView.showsHorizontalScrollIndicator = false

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(reorderMediaCollectionViewWithLongPress(_:)))
        mediaCollectionView.addGestureRecognizer(longPress)

        // pick skill
        
        // 只有自己也有，才使用准备的
        if let skill = preparedSkill, let _ = skills.index(of: skill) {
            pickedSkill = preparedSkill
        }
        
        channelLabel.text = String.trans_promptChannel
        choosePromptLabel.text = String.trans_promptChoose
        
        channelViewTopConstraint.constant = 30
        
        skillPickerView.alpha = 0
        
        let hasSkill = (pickedSkill != nil)
        pickedSkillBubbleImageView.alpha = hasSkill ? 1 : 0
        pickedSkillLabel.alpha = hasSkill ? 1 : 0
        
        channelView.backgroundColor = UIColor.white
        channelView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(NewFeedViewController.showSkillPickerView(_:)))
        channelView.addGestureRecognizer(tap)
        
        // try turn on location
        
        proposeToAccess(.location(.whenInUse), agreed: {
            YepLocationService.turnOn()
            
        }, rejected: { [weak self] in
            self?.alertCanNotAccessLocation()
        })

        switch attachment {

        case .default:
            mediaCollectionView.isHidden = false
            socialWorkContainerView.isHidden = true
            voiceContainerView.isHidden = true
            locationContainerView.isHidden = true

            mediaCollectionViewHeightConstraint.constant = 80

        case .socialWork(let socialWork):
            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = false
            voiceContainerView.isHidden = true
            locationContainerView.isHidden = true

            mediaCollectionViewHeightConstraint.constant = 80

            updateUIForSocialWork(socialWork)

        case .voice(let feedVoice):
            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = true
            voiceContainerView.isHidden = false
            locationContainerView.isHidden = true

            mediaCollectionViewHeightConstraint.constant = 40

            voiceBubbleImageVIew.tintColor = UIColor.leftBubbleTintColor()
            voicePlayButton.tintColor = UIColor.lightGray
            voicePlayButton.tintAdjustmentMode = .normal
            voiceTimeLabel.textColor = UIColor.lightGray
            voiceSampleView.sampleColor = UIColor.leftWaveColor()
            voiceSampleView.samples = feedVoice.limitedSampleValues

            let seconds = feedVoice.sampleValuesCount / 10
            let subSeconds = feedVoice.sampleValuesCount - seconds * 10
            voiceTimeLabel.text = String(format: "%d.%d\"", seconds, subSeconds)

            voiceSampleViewWidthConstraint.constant = CGFloat(feedVoice.limitedSampleValues.count) * 3

        case .location(let location):
            mediaCollectionView.isHidden = true
            socialWorkContainerView.isHidden = true
            voiceContainerView.isHidden = true
            locationContainerView.isHidden = false

            let locationCoordinate = location.info.coordinate

            let options = MKMapSnapshotOptions()
            options.scale = UIScreen.main.scale
            options.size = locationMapImageView.bounds.size
            options.region = MKCoordinateRegionMakeWithDistance(locationCoordinate, 500, 500)

            let mapSnapshotter = MKMapSnapshotter(options: options)

            mapSnapshotter.start (completionHandler: { (snapshot, error) -> Void in
                if error == nil {

                    guard let snapshot = snapshot else {
                        return
                    }

                    let image = snapshot.image

                    SafeDispatch.async { [weak self] in
                        self?.locationMapImageView.image = image
                    }
                }
            })

            locationNameLabel.text = location.info.name
        }
    }

    // MARK: UI

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        socialWorkFullMaskImageView.frame = socialWorkImageView.bounds
        socialWorkHalfMaskImageView.frame = locationMapImageView.bounds
    }

    fileprivate func updateUIForSocialWork(_ socialWork: MessageSocialWork) {

        socialWorkImageView.mask = socialWorkFullMaskImageView
        locationMapImageView.mask = socialWorkHalfMaskImageView

        var socialWorkImageURL: URL?

        guard let socialWorkType = MessageSocialWorkType(rawValue: socialWork.type) else {
            return
        }

        switch socialWorkType {

        case .githubRepo:

            socialWorkImageView.isHidden = true
            githubRepoContainerView.isHidden = false

            githubRepoImageView.tintColor = UIColor.yepIconImageViewTintColor()

            if let githubRepo = socialWork.githubRepo {
                githubRepoNameLabel.text = githubRepo.name
                githubRepoDescriptionLabel.text = githubRepo.repoDescription
            }

        case .dribbbleShot:

            socialWorkImageView.isHidden = false
            githubRepoContainerView.isHidden = true

            if let string = socialWork.dribbbleShot?.imageURLString {
                socialWorkImageURL = URL(string: string)
            }

        case .instagramMedia:

            socialWorkImageView.isHidden = false
            githubRepoContainerView.isHidden = true

            if let string = socialWork.instagramMedia?.imageURLString {
                socialWorkImageURL = URL(string: string)
            }
        }
        
        if let url = socialWorkImageURL {
            socialWorkImageView.kf.setImage(with: url, placeholder: nil)
        }
    }
    
    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showPickPhotos" {

            let vc = segue.destination as! PickPhotosViewController
            
            vc.pickedImageSet = Set(imageAssets)
            vc.imageLimit = mediaImages.count
            vc.delegate = self
//            vc.completion = { [weak self] images, imageAssets in
//                
//                for image in images {
//                    self?.mediaImages.append(image)
//                }
//                self?.mediaCollectionView.reloadData()
//            }
        }
    }
    
    // MARK: Actions
    
    @objc fileprivate func showSkillPickerView(_ tap: UITapGestureRecognizer) {
        
        // 初次 show，预先 selectRow

        self.messageTextView.endEditing(true)
        
        if pickedSkill == nil {
            if !skills.isEmpty {
                let selectedRow = 0
                skillPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
                pickedSkill = skills[selectedRow % skills.count]
            }
            
        } else {
            if let skill = preparedSkill, let index = skills.index(of: skill) {
                let selectedRow = index
                skillPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
                pickedSkill = skills[selectedRow % skills.count]
            }
            
            preparedSkill = nil // 再 show 就不需要 selectRow 了
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
            
            self?.channelView.backgroundColor = UIColor.clear
            self?.channelViewTopLineView.alpha = 0
            self?.channelViewBottomLineView.alpha = 0
            self?.choosePromptLabel.alpha = 0
            
            self?.pickedSkillBubbleImageView.alpha = 0
            self?.pickedSkillLabel.alpha = 0
            
            self?.skillPickerView.alpha = 1
            
            self?.channelViewTopConstraint.constant = 108
            self?.view.layoutIfNeeded()
            
        }, completion: { [weak self] _ in
            self?.channelView.isUserInteractionEnabled = false
        })
    }
    
    fileprivate func hideSkillPickerView() {
        
        if pickedSkill == NewFeedViewController.generalSkill {
            pickedSkill = nil
        }
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: UIViewAnimationOptions(), animations: { [weak self] in
            
            self?.channelView.backgroundColor = UIColor.white
            self?.channelViewTopLineView.alpha = 1
            self?.channelViewBottomLineView.alpha = 1
            self?.choosePromptLabel.alpha = 1
            
            if let _ = self?.pickedSkill {
                self?.pickedSkillBubbleImageView.alpha = 1
                self?.pickedSkillLabel.alpha = 1
            }
            
            self?.skillPickerView.alpha = 0
            
            self?.channelViewTopConstraint.constant = 30
            self?.view.layoutIfNeeded()
            
        }, completion: { [weak self] _ in
            self?.channelView.isUserInteractionEnabled = true
        })
    }

    fileprivate func tryDeleteFeedVoice() {
        if case let .voice(feedVoice) = attachment {
            do {
                try FileManager.default.removeItem(at: feedVoice.fileURL)
            } catch let error {
                println("delete voiceFileURL error: \(error)")
            }
        }
    }

    @objc fileprivate func cancel(_ sender: UIBarButtonItem) {
        
        messageTextView.resignFirstResponder()

        tryDeleteFeedVoice()

        self.dismiss(animated: true, completion: nil)
    }
    
    func tryMakeUploadingFeed() -> DiscoveredFeed? {

        guard let me = me() else {
            return nil
        }

        let creator = DiscoveredUser.fromUser(me)

        var kind: FeedKind = .Text

        let createdUnixTime = Date().timeIntervalSince1970
        let updatedUnixTime = createdUnixTime

        let message = messageTextView.text.trimming(.whitespaceAndNewline)

        var feedAttachment: DiscoveredFeed.Attachment?

        switch attachment {

        case .default:

            if !mediaImages.isEmpty {
                kind = .Image

                let imageAttachments: [DiscoveredAttachment] = mediaImages.map({ image in

                    let fixedSize = image.yep_fixedSize

                    // resize to smaller, not need fixRotation

                    if let image = image.resizeToSize(fixedSize, withInterpolationQuality: .high) {
                        return DiscoveredAttachment(metadata: "", URLString: "", image: image)
                    } else {
                        return nil
                    }
                }).flatMap({ $0 })

                feedAttachment = .images(imageAttachments)
            }

        case .voice(let feedVoice):

            kind = .Audio

            let audioAsset = AVURLAsset(url: feedVoice.fileURL, options: nil)
            let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

            let audioMetaDataInfo: [String: Any] = [
                Config.MetaData.audioSamples: feedVoice.limitedSampleValues,
                Config.MetaData.audioDuration: audioDuration
            ]

            let audioMetaData = try! JSONSerialization.data(withJSONObject: audioMetaDataInfo, options: [])

            let audioInfo = DiscoveredFeed.AudioInfo(feedID: "", URLString: "", metaData: audioMetaData, duration: audioDuration, sampleValues: feedVoice.limitedSampleValues)

            feedAttachment = .audio(audioInfo)

        default:
            break
        }

        return DiscoveredFeed(id: "", allowComment: true, kind: kind, createdUnixTime: createdUnixTime, updatedUnixTime: updatedUnixTime, creator: creator, body: message, highlightedKeywordsBody: nil, attachment: feedAttachment, distance: 0, skill: pickedSkill, groupID: "", messagesCount: 0, recommended: false, uploadingErrorMessage: nil)
    }

    @objc fileprivate func tryPost(_ sender: UIBarButtonItem) {

        guard let avatarURLString = YepUserDefaults.avatarURLString.value , !avatarURLString.isEmpty else {

            YepAlert.alertSorry(message: NSLocalizedString("You have no avatar! Please set up one first.", comment: ""), inViewController: self, withDismissAction: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })

            return
        }

        post(again: false)
    }

    func post(again: Bool) {

        let messageLength = (messageTextView.text as NSString).length

        guard messageLength <= YepConfig.maxFeedTextLength else {
            let message = String.trans_promptFeedInfoTooLong(YepConfig.maxFeedTextLength)
            YepAlert.alertSorry(message: message, inViewController: self)
            return
        }

        if !again {
            uploadState = .uploading

            if let feed = tryMakeUploadingFeed() , feed.kind.needBackgroundUpload {
                beforeUploadingFeedAction?(feed, self)

                YepHUD.hideActivityIndicator()
                dismiss(animated: true, completion: nil)
            }
        }

        let message = messageTextView.text.trimming(.whitespaceAndNewline)
        let coordinate = YepLocationService.sharedManager.currentLocation?.coordinate
        var kind: FeedKind = .Text
        var attachments: [JSONDictionary]?

        let tryCreateFeed: () -> Void = { [weak self] in

            var openGraph: OpenGraph?

            let doCreateFeed: () -> Void = { [weak self] in

                if let openGraph = openGraph , openGraph.isValid {

                    kind = .URL

                    let URLInfo = [
                        "url": openGraph.URL.absoluteString,
                        "site_name": (openGraph.siteName ?? "").yep_truncatedForFeed,
                        "title": (openGraph.title ?? "").yep_truncatedForFeed,
                        "description": (openGraph.description ?? "").yep_truncatedForFeed,
                        "image_url": openGraph.previewImageURLString ?? "",
                    ]

                    attachments = [URLInfo]
                }

                createFeedWithKind(kind, message: message, attachments: attachments, coordinate: coordinate, skill: self?.pickedSkill, allowComment: true, failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason, errorMessage)

                    SafeDispatch.async { [weak self] in
                        let message = errorMessage ?? String.trans_promptCreateFeedFailed
                        self?.uploadState = .failed(message: message)
                    }

                }, completion: { data in
                    println("createFeedWithKind: \(data)")

                    SafeDispatch.async { [weak self] in

                        self?.uploadState = .success

                        if let feed = DiscoveredFeed.fromFeedInfo(data, groupInfo: nil) {
                            self?.afterCreatedFeedAction?(feed)

                            NotificationCenter.default.post(name: YepConfig.NotificationName.createdFeed, object: feed)
                        }

                        if !kind.needBackgroundUpload {
                            self?.dismiss(animated: true, completion: nil)
                        }
                    }

                    // Sync to local

                    if let groupInfo = data["circle"] as? JSONDictionary, let groupID = groupInfo["id"] as? String {

                        syncGroupWithGroupID(groupID)
                    }
                })
            }

            guard kind.needParseOpenGraph, let fisrtURL = message.yep_embeddedURLs.first else {
                doCreateFeed()

                return
            }

            let parseOpenGraphGroup = DispatchGroup()


            parseOpenGraphGroup.enter()

            openGraphWithURL(fisrtURL, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason, errorMessage)

                SafeDispatch.async {
                    parseOpenGraphGroup.leave()
                }

            }, completion: { _openGraph in
                println("_openGraph: \(_openGraph)")

                SafeDispatch.async {
                    openGraph = _openGraph

                    parseOpenGraphGroup.leave()
                }
            })

            parseOpenGraphGroup.notify(queue: DispatchQueue.main) {
                doCreateFeed()
            }
        }

        switch attachment {

        case .default:

            let mediaImagesCount = mediaImages.count

            let uploadImagesQueue = OperationQueue()
            var uploadAttachmentOperations = [UploadAttachmentOperation]()
            var uploadedAttachments = [UploadedAttachment]()
            var uploadErrorMessage: String?

            mediaImages.forEach({ image in

                let fixedSize = image.yep_fixedSize

                // resize to smaller, not need fixRotation

                if let image = image.resizeToSize(fixedSize, withInterpolationQuality: .default), let imageData = UIImageJPEGRepresentation(image, 0.95) {

                    let source: UploadAttachment.Source = .data(imageData)
                    let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: false)
                    let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .JPEG, metaDataString: metaDataString)

                    let operation = UploadAttachmentOperation(uploadAttachment: uploadAttachment) { result in
                        switch result {
                        case .failed(let errorMessage):
                            if let errorMessage = errorMessage {
                                uploadErrorMessage = errorMessage
                            }
                        case .success(let uploadedAttachment):
                            uploadedAttachments.append(uploadedAttachment)
                        }
                    }

                    uploadAttachmentOperations.append(operation)
                }
            })

            if uploadAttachmentOperations.count > 1 {
                for i in 1..<uploadAttachmentOperations.count {
                    let previousOperation = uploadAttachmentOperations[i-1]
                    let currentOperation = uploadAttachmentOperations[i]

                    currentOperation.addDependency(previousOperation)
                }
            }

            let uploadFinishOperation = BlockOperation { [weak self] in

                guard uploadedAttachments.count == mediaImagesCount else {
                    let message = uploadErrorMessage ?? NSLocalizedString("Upload failed!", comment: "")

                    println("uploadedAttachments.count == mediaImagesCount: \(uploadedAttachments.count), \(mediaImagesCount)")
                    OperationQueue.main.addOperation {
                        self?.uploadState = .failed(message: message)
                    }

                    return
                }

                if !uploadedAttachments.isEmpty {

                    let imageInfos: [JSONDictionary] = uploadedAttachments.map({
                        ["id": $0.ID]
                    })

                    attachments = imageInfos
                    
                    kind = .Image
                }
                
                tryCreateFeed()

                // pre cache mediaImages

                if let strongSelf = self {

                    let bigger = (strongSelf.mediaImages.count == 1)

                    for i in 0..<strongSelf.mediaImages.count {

                        let image = strongSelf.mediaImages[i]
                        let URLString = uploadedAttachments[i].URLString

                        do {
                            let sideLength: CGFloat
                            if bigger {
                               sideLength = YepConfig.FeedBiggerImageCell.imageSize.width
                            } else {
                               sideLength = YepConfig.FeedNormalImagesCell.imageSize.width
                            }
                            let scaledKey = YepImageCache.attachmentSideLengthKeyWithURLString(URLString, sideLength: sideLength)
                            let scaledImage = image.scaleToMinSideLength(sideLength)
                            let scaledData = UIImageJPEGRepresentation(image, 1.0)
                            ImageCache.default.store(scaledImage, original: scaledData, forKey: scaledKey, toDisk: true, completionHandler: nil)
                        }

                        do {
                            let originalKey = YepImageCache.attachmentOriginKeyWithURLString(URLString)
                            let originalData = UIImageJPEGRepresentation(image, 1.0)
                            ImageCache.default.store(image, original: originalData, forKey: originalKey, toDisk: true, completionHandler: nil)
                        }
                    }
                }
            }

            if let lastUploadAttachmentOperation = uploadAttachmentOperations.last {
                uploadFinishOperation.addDependency(lastUploadAttachmentOperation)
            }

            uploadImagesQueue.addOperations(uploadAttachmentOperations, waitUntilFinished: false)
            uploadImagesQueue.addOperation(uploadFinishOperation)

        case .socialWork(let socialWork):

            guard let type = MessageSocialWorkType(rawValue: socialWork.type) else {
                return
            }

            switch type {

            case .githubRepo:

                guard let githubRepo = socialWork.githubRepo else {
                    break
                }

                let repoInfo: JSONDictionary = [
                    "repo_id": githubRepo.repoID,
                    "name": githubRepo.name,
                    "full_name": githubRepo.fullName,
                    "description": githubRepo.repoDescription,
                    "url": githubRepo.URLString,
                    "created_at": githubRepo.createdUnixTime,
                ]

                attachments = [repoInfo]

                kind = .GithubRepo

            case .dribbbleShot:

                guard let dribbbleShot = socialWork.dribbbleShot else {
                    break
                }

                let shotInfo: JSONDictionary = [
                    "shot_id": dribbbleShot.shotID,
                    "title": dribbbleShot.title,
                    "description": dribbbleShot.shotDescription,
                    "media_url": dribbbleShot.imageURLString,
                    "url": dribbbleShot.htmlURLString,
                    "created_at": dribbbleShot.createdUnixTime,
                ]

                attachments = [shotInfo]

                kind = .DribbbleShot

            default:
                break
            }

            tryCreateFeed()

        case .voice(let feedVoice):

            let audioAsset = AVURLAsset(url: feedVoice.fileURL, options: nil)
            let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

            let audioMetaDataInfo: [String: Any] = [
                Config.MetaData.audioDuration: audioDuration,
                Config.MetaData.audioSamples: feedVoice.limitedSampleValues,
            ]

            var metaDataString = ""
            if let audioMetaData = try? JSONSerialization.data(withJSONObject: audioMetaDataInfo, options: []) {
                if let audioMetaDataString = String(data: audioMetaData, encoding: .utf8) {
                    metaDataString = audioMetaDataString
                }
            }

            let uploadVoiceGroup = DispatchGroup()

            var uploadErrorMessage: String?

            uploadVoiceGroup.enter()

            let source: UploadAttachment.Source = .filePath(feedVoice.fileURL.path)

            let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .M4A, metaDataString: metaDataString)

            tryUploadAttachment(uploadAttachment, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason, errorMessage)

                SafeDispatch.async {
                    uploadErrorMessage = errorMessage
                    uploadVoiceGroup.leave()
                }

            }, completion: { uploadedAttachment in

                let audioInfo: JSONDictionary = [
                    "id": uploadedAttachment.ID
                ]

                attachments = [audioInfo]

                SafeDispatch.async {
                    uploadVoiceGroup.leave()
                }
            })

            uploadVoiceGroup.notify(queue: DispatchQueue.main) { [weak self] in

                guard attachments != nil else {
                    let message = uploadErrorMessage ?? NSLocalizedString("Upload failed!", comment: "")
                    self?.uploadState = .failed(message: message)

                    return
                }

                kind = .Audio

                tryCreateFeed()

                self?.tryDeleteFeedVoice()
            }

        case .location(let location):

            let locationInfo: JSONDictionary = [
                "place": location.info.name ?? "",
                "latitude": location.info.coordinate.latitude,
                "longitude": location.info.coordinate.longitude,
            ]

            attachments = [locationInfo]

            kind = .Location

            tryCreateFeed()
        }
    }

    @IBAction fileprivate func playOrPauseAudio(_ sender: UIButton) {

        YepAlert.alertSorry(message: "你以为可以播放吗？\n哈哈哈，NIX和你开个玩笑。", inViewController: self)
    }

    @objc fileprivate func reorderMediaCollectionViewWithLongPress(_ gesture: UILongPressGestureRecognizer) {

        let collectionView = mediaCollectionView

        switch(gesture.state) {

        case .began:
            guard let selectedIndexPath = collectionView?.indexPathForItem(at: gesture.location(in: self.mediaCollectionView)) else {
                break
            }
            collectionView?.beginInteractiveMovementForItem(at: selectedIndexPath)

        case .changed:
            collectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))

        case .ended:
            collectionView?.endInteractiveMovement()

        default:
            collectionView?.cancelInteractiveMovement()
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension NewFeedViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    enum Section: Int {
        case photos
        case add
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalid section!")
        }

        switch section {
        case .photos:
            return mediaImages.count
        case .add:
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .photos:
            let cell: FeedMediaCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            
            let image = mediaImages[(indexPath as NSIndexPath).item]
            
            cell.configureWithImage(image)
            cell.delete = { [weak self] in
                self?.mediaImages.remove(at: (indexPath as NSIndexPath).item)
            }
            
            return cell

        case .add:
            let cell: FeedMediaAddCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .photos:
            return CGSize(width: 80, height: 80)

        case .add:
            guard mediaImages.count != YepConfig.Feed.maxImagesCount else {
                return CGSize.zero
            }
            return CGSize(width: 80, height: 80)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .photos:
            return true

        case .add:
            return false
        }
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {

        let sourceIndex = (sourceIndexPath as NSIndexPath).item
        let destinationIndex = (destinationIndexPath as NSIndexPath).item

        guard sourceIndex != destinationIndex else {
            return
        }

        let image = mediaImages[sourceIndex]
        mediaImages.remove(at: sourceIndex)
        mediaImages.insert(image, at: destinationIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .photos:

            let index = (indexPath as NSIndexPath).row

            let references: [Reference?] = (0..<mediaImages.count).map({
                let cell = collectionView.cellForItem(at: IndexPath(item: $0, section: (indexPath as NSIndexPath).section)) as? FeedMediaCell
                return cell?.transitionReference
            })

            self.previewReferences = references

            let previewNewFeedPhotos = mediaImages.map({ PreviewNewFeedPhoto(image: $0) })

            self.previewNewFeedPhotos = previewNewFeedPhotos

            let photos: [Photo] = previewNewFeedPhotos.map({ $0 })
            let initialPhoto = photos[index]

            let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
            self.present(photosViewController, animated: true, completion: nil)

        case .add:

            messageTextView.resignFirstResponder()
            
            if mediaImages.count == YepConfig.Feed.maxImagesCount {
                YepAlert.alertSorry(message: String.trans_promptFeedCanOnlyHasXPhotos, inViewController: self)
                return
            }
            
            let pickAlertController = UIAlertController(title: String.trans_titleChooseSource, message: nil, preferredStyle: .actionSheet)
            
            let cameraAction: UIAlertAction = UIAlertAction(title: String.trans_titleCamera, style: .default) { _ in

                proposeToAccess(.camera, agreed: { [weak self] in

                    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                        self?.alertCanNotOpenCamera()
                        return
                    }

                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = .camera
                        strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
                    }
                    
                }, rejected: { [weak self] in
                    self?.alertCanNotOpenCamera()
                })
            }
            
            pickAlertController.addAction(cameraAction)
            
            let albumAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("title.albums", comment: ""), style: .default) { [weak self] _ in

                proposeToAccess(.photos, agreed: { [weak self] in
                    self?.performSegue(withIdentifier: "showPickPhotos", sender: nil)

                }, rejected: { [weak self] in
                    self?.alertCanNotAccessCameraRoll()
                })
            }
        
            pickAlertController.addAction(albumAction)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .cancel) { _ in
            }
        
            pickAlertController.addAction(cancelAction)
        
            self.present(pickAlertController, animated: true, completion: nil)
        }
    }
}

// MARK: - UIScrollViewDelegate

extension NewFeedViewController: UITextViewDelegate {

    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {

        if !isDirty {
            textView.text = ""
        }

        isNeverInputMessage = false

        return true
    }

    func textViewDidChange(_ textView: UITextView) {

        isDirty = NSString(string: textView.text).length > 0
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        hideSkillPickerView()
    }
}

// MARK: - UIScrollViewDelegate

extension NewFeedViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        messageTextView.resignFirstResponder()
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension NewFeedViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return skills.isEmpty ? 0 : 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return skills.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
        let skill = skills[row % skills.count]
        
        if let view = view as? FeedSkillPickerItemView {
            view.configureWithSkill(skill)
            return view
            
        } else {
            let view = FeedSkillPickerItemView()
            view.configureWithSkill(skill)
            return view
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        pickedSkill = skills[row % skills.count]
    }
}

extension NewFeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            
            switch mediaType {
                
            case String(kUTTypeImage):
                
                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    if mediaImages.count <= 3 {
                        mediaImages.append(image)
                        mediaCollectionView.reloadData()
                    }
                }
                
            default:
                break
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
}

// MARK: Fetch images from imagePicker

extension NewFeedViewController: ReturnPickedPhotosDelegate {

    func returnSelectedImages(_ images: [UIImage], imageAssets: [PHAsset]) {
        
        for image in images {
            mediaImages.append(image)
        }
        mediaCollectionView.reloadData()
    }
}

// MARK: - PhotosViewControllerDelegate

extension NewFeedViewController: PhotosViewControllerDelegate {

    func photosViewController(_ vc: PhotosViewController, referenceForPhoto photo: Photo) -> Reference? {

        println("photosViewController:referenceViewForPhoto:\(photo)")

        if let previewNewFeedPhoto = photo as? PreviewNewFeedPhoto {
            if let index = previewNewFeedPhotos.index(of: previewNewFeedPhoto) {
                return previewReferences?[index]
            }
        }

        return nil
    }

    func photosViewController(_ vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int) {

        println("photosViewController:didNavigateToPhoto:\(photo):atIndex:\(index)")
    }

    func photosViewControllerWillDismiss(_ vc: PhotosViewController) {

        println("photosViewControllerWillDismiss")
    }

    func photosViewControllerDidDismiss(_ vc: PhotosViewController) {

        println("photosViewControllerDidDismiss")

        previewReferences = nil
        previewNewFeedPhotos = []
    }
}


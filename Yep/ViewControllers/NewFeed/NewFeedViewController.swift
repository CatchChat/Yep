//
//  NewFeedViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import CoreLocation
import MobileCoreServices
import Photos
import Proposer
import RealmSwift
import Kingfisher
import MapKit

let generalSkill = Skill(category: nil, id: "", name: "general", localName: NSLocalizedString("Choose...", comment: ""), coverURLString: nil)

struct FeedVoice {

    let fileURL: NSURL
    let sampleValuesCount: Int
    let limitedSampleValues: [CGFloat]
}

class NewFeedViewController: SegueViewController {

    enum Attachment {
        case Default
        case SocialWork(MessageSocialWork)
        case Voice(FeedVoice)
        case Location(PickLocationViewController.Location)

        var needPrepare: Bool {
            switch self {
            case .Default:
                return false
            case .SocialWork:
                return false
            case .Voice:
                return true
            case .Location:
                return true
            }
        }
    }

    var attachment: Attachment = .Default

    var beforeUploadingFeedAction: ((feed: DiscoveredFeed, newFeedViewController: NewFeedViewController) -> Void)?
    var afterCreatedFeedAction: ((feed: DiscoveredFeed) -> Void)?

    var preparedSkill: Skill?

    weak var feedsViewController: FeedsViewController?
    var getFeedsViewController: (() -> FeedsViewController?)?


    @IBOutlet private weak var feedWhiteBGView: UIView!
    
    @IBOutlet private weak var messageTextView: UITextView!

    @IBOutlet private weak var mediaCollectionView: UICollectionView!
    @IBOutlet private weak var mediaCollectionViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet private weak var socialWorkContainerView: UIView!
    @IBOutlet private weak var socialWorkImageView: UIImageView!
    @IBOutlet private weak var githubRepoContainerView: UIView!
    @IBOutlet private weak var githubRepoImageView: UIImageView!
    @IBOutlet private weak var githubRepoNameLabel: UILabel!
    @IBOutlet private weak var githubRepoDescriptionLabel: UILabel!

    @IBOutlet private weak var voiceContainerView: UIView!
    @IBOutlet private weak var voiceBubbleImageVIew: UIImageView!
    @IBOutlet private weak var voicePlayButton: UIButton!
    @IBOutlet private weak var voiceSampleView: SampleView!
    @IBOutlet private weak var voiceTimeLabel: UILabel!

    @IBOutlet private weak var voiceSampleViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet private weak var locationContainerView: UIView!
    @IBOutlet private weak var locationMapImageView: UIImageView!
    @IBOutlet private weak var locationNameLabel: UILabel!

    @IBOutlet private weak var channelView: UIView!
    @IBOutlet private weak var channelViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var channelViewTopLineView: HorizontalLineView!
    @IBOutlet private weak var channelViewBottomLineView: HorizontalLineView!
    
    @IBOutlet private weak var channelLabel: UILabel!
    @IBOutlet private weak var choosePromptLabel: UILabel!
    
    @IBOutlet private weak var pickedSkillBubbleImageView: UIImageView!
    @IBOutlet private weak var pickedSkillLabel: UILabel!
    
    @IBOutlet private weak var skillPickerView: UIPickerView!

    private lazy var socialWorkHalfMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask"))
        return imageView
    }()

    private lazy var socialWorkFullMaskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask_full"))
        return imageView
    }()

    private let placeholderOfFeed = NSLocalizedString("Introduce a thing, share an idea, describe a problem ...", comment: "")

    private var isNeverInputMessage = true
    private var isDirty = false {
        willSet {
            postButton.enabled = newValue

            if !newValue && isNeverInputMessage {
                messageTextView.text = placeholderOfFeed
            }

            messageTextView.textColor = newValue ? UIColor.blackColor() : UIColor.lightGrayColor()
        }
    }

    private lazy var postButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Post", comment: ""), style: .Plain, target: self, action: "post:")
            button.enabled = false
        return button
    }()

    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = false
        return imagePicker
    }()
    
    private var imageAssets: [PHAsset] = []
    
    private var mediaImages = [UIImage]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.mediaCollectionView.reloadData()
            }
        }
    }

    enum UploadState {
        case Ready
        case Uploading
        case Failed(message: String)
        case Success
    }
    var uploadState: UploadState = .Ready {
        willSet {
            switch newValue {

            case .Ready:
                break

            case .Uploading:
                postButton.enabled = false
                messageTextView.resignFirstResponder()
                YepHUD.showActivityIndicator()

            case .Failed(let message):
                YepHUD.hideActivityIndicator()
                postButton.enabled = true

                if presentingViewController != nil {
                    YepAlert.alertSorry(message: message, inViewController: self)
                } else {
                    feedsViewController?.handleUploadingErrorMessage(message)
                }

            case .Success:
                YepHUD.hideActivityIndicator()
                messageTextView.text = nil
            }
        }
    }
    
    private let feedMediaAddCellID = "FeedMediaAddCell"
    private let feedMediaCellID = "FeedMediaCell"
    
    //let max = Int(INT16_MAX)
    
    private let skills: [Skill] = {
        if let
            myUserID = YepUserDefaults.userID.value,
            realm = try? Realm(),
            me = userWithUserID(myUserID, inRealm: realm) {
                
                var skills = skillsFromUserSkillList(me.masterSkills) + skillsFromUserSkillList(me.learningSkills)
                
                skills.insert(generalSkill, atIndex: 0)
                
                return skills
        }
        
        return []
    }()
    
    private var pickedSkill: Skill? {
        willSet {
            pickedSkillLabel.text = newValue?.localName
            choosePromptLabel.hidden = (newValue != nil)
        }
    }

    deinit {
        println("NewFeed deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("New Feed", comment: ""))
        view.backgroundColor = UIColor.yepBackgroundColor()
        
        navigationItem.rightBarButtonItem = postButton

        if !attachment.needPrepare {
            let cancleButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .Plain, target: self, action: "cancel:")

            navigationItem.leftBarButtonItem = cancleButton
        }
        
        view.sendSubviewToBack(feedWhiteBGView)

        feedsViewController = getFeedsViewController?()
        println("feedsViewController: \(feedsViewController)")
        
        isDirty = false

        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        messageTextView.delegate = self
        //messageTextView.becomeFirstResponder()
        
        mediaCollectionView.backgroundColor = UIColor.clearColor()
        
        mediaCollectionView.registerNib(UINib(nibName: feedMediaAddCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaAddCellID)
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.contentInset.left = 15
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self
        mediaCollectionView.showsHorizontalScrollIndicator = false
        
        // pick skill
        
        // 只有自己也有，才使用准备的
        if let skill = preparedSkill, _ = skills.indexOf(skill) {
            pickedSkill = preparedSkill
        }
        
        channelLabel.text = NSLocalizedString("Channel:", comment: "")
        choosePromptLabel.text = NSLocalizedString("Choose...", comment: "")
        
        channelViewTopConstraint.constant = 30
        
        skillPickerView.alpha = 0
        
        let hasSkill = (pickedSkill != nil)
        pickedSkillBubbleImageView.alpha = hasSkill ? 1 : 0
        pickedSkillLabel.alpha = hasSkill ? 1 : 0
        
        channelView.backgroundColor = UIColor.whiteColor()
        channelView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "showSkillPickerView:")
        channelView.addGestureRecognizer(tap)
        
        // try turn on location
        
        let locationResource = PrivateResource.Location(.WhenInUse)
        
        if locationResource.isNotDeterminedAuthorization {
            
            proposeToAccess(.Location(.WhenInUse), agreed: {
                
                YepLocationService.turnOn()
                
            }, rejected: {
                self.alertCanNotAccessLocation()
            })
            
        } else {
            proposeToAccess(.Location(.WhenInUse), agreed: {
                
                YepLocationService.turnOn()
                
            }, rejected: {
            })
        }

        switch attachment {

        case .Default:
            mediaCollectionView.hidden = false
            socialWorkContainerView.hidden = true
            voiceContainerView.hidden = true
            locationContainerView.hidden = true

            mediaCollectionViewHeightConstraint.constant = 80

        case .SocialWork(let socialWork):
            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = false
            voiceContainerView.hidden = true
            locationContainerView.hidden = true

            mediaCollectionViewHeightConstraint.constant = 80

            updateUIForSocialWork(socialWork)

        case .Voice(let feedVoice):
            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = true
            voiceContainerView.hidden = false
            locationContainerView.hidden = true

            mediaCollectionViewHeightConstraint.constant = 40

            voiceBubbleImageVIew.tintColor = UIColor.leftBubbleTintColor()
            voicePlayButton.tintColor = UIColor.lightGrayColor()
            voicePlayButton.tintAdjustmentMode = .Normal
            voiceTimeLabel.textColor = UIColor.lightGrayColor()
            voiceSampleView.sampleColor = UIColor.leftWaveColor()
            voiceSampleView.samples = feedVoice.limitedSampleValues

            let seconds = feedVoice.sampleValuesCount / 10
            let subSeconds = feedVoice.sampleValuesCount - seconds * 10
            voiceTimeLabel.text = String(format: "%d.%d\"", seconds, subSeconds)

            voiceSampleViewWidthConstraint.constant = CGFloat(feedVoice.limitedSampleValues.count) * 3

        case .Location(let location):
            mediaCollectionView.hidden = true
            socialWorkContainerView.hidden = true
            voiceContainerView.hidden = true
            locationContainerView.hidden = false

            let locationCoordinate = location.info.coordinate

            let options = MKMapSnapshotOptions()
            options.scale = UIScreen.mainScreen().scale
            options.size = locationMapImageView.bounds.size
            options.region = MKCoordinateRegionMakeWithDistance(locationCoordinate, 500, 500)

            let mapSnapshotter = MKMapSnapshotter(options: options)

            mapSnapshotter.startWithCompletionHandler { (snapshot, error) -> Void in
                if error == nil {

                    guard let snapshot = snapshot else {
                        return
                    }

                    let image = snapshot.image

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.locationMapImageView.image = image
                    }
                }
            }

            locationNameLabel.text = location.info.name
        }
    }

    // MARK: UI

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        socialWorkFullMaskImageView.frame = socialWorkImageView.bounds
        socialWorkHalfMaskImageView.frame = locationMapImageView.bounds
    }

    private func updateUIForSocialWork(socialWork: MessageSocialWork) {

        socialWorkImageView.maskView = socialWorkFullMaskImageView
        locationMapImageView.maskView = socialWorkHalfMaskImageView

        var socialWorkImageURL: NSURL?

        guard let socialWorkType = MessageSocialWorkType(rawValue: socialWork.type) else {
            return
        }

        switch socialWorkType {

        case .GithubRepo:

            socialWorkImageView.hidden = true
            githubRepoContainerView.hidden = false

            githubRepoImageView.tintColor = UIColor.yepIconImageViewTintColor()

            if let githubRepo = socialWork.githubRepo {
                githubRepoNameLabel.text = githubRepo.name
                githubRepoDescriptionLabel.text = githubRepo.repoDescription
            }

        case .DribbbleShot:

            socialWorkImageView.hidden = false
            githubRepoContainerView.hidden = true

            if let string = socialWork.dribbbleShot?.imageURLString {
                socialWorkImageURL = NSURL(string: string)
            }

        case .InstagramMedia:

            socialWorkImageView.hidden = false
            githubRepoContainerView.hidden = true

            if let string = socialWork.instagramMedia?.imageURLString {
                socialWorkImageURL = NSURL(string: string)
            }
        }
        
        if let URL = socialWorkImageURL {
            socialWorkImageView.kf_setImageWithURL(URL, placeholderImage: nil)
        }
    }
    
    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showPickPhotos" {
            
            let vc = segue.destinationViewController as! PickPhotosViewController
            
            vc.pickedImageSet = Set(imageAssets)
            vc.imageLimit = mediaImages.count
            vc.completion = { [weak self] images, imageAssets in
                
                for image in images {
                    self?.mediaImages.append(image)
                }
            }
        }
    }
    
    // MARK: Actions
    
    @objc private func showSkillPickerView(tap: UITapGestureRecognizer) {
        
        // 初次 show，预先 selectRow

        self.messageTextView.endEditing(true)
        
        if pickedSkill == nil {
            if !skills.isEmpty {
                //let centerRow = max / 2
                //let selectedRow = centerRow
                let selectedRow = 0
                skillPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
                pickedSkill = skills[selectedRow % skills.count]
            }
            
        } else {
            if let skill = preparedSkill, let index = skills.indexOf(skill) {
                
                //var selectedRow = max / 2
                //selectedRow = selectedRow - selectedRow % skills.count + index
                let selectedRow = index

                skillPickerView.selectRow(selectedRow, inComponent: 0, animated: false)
                pickedSkill = skills[selectedRow % skills.count]
            }
            
            preparedSkill = nil // 再 show 就不需要 selectRow 了
        }
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            
            self?.channelView.backgroundColor = UIColor.clearColor()
            self?.channelViewTopLineView.alpha = 0
            self?.channelViewBottomLineView.alpha = 0
            self?.choosePromptLabel.alpha = 0
            
            self?.pickedSkillBubbleImageView.alpha = 0
            self?.pickedSkillLabel.alpha = 0
            
            self?.skillPickerView.alpha = 1
            
            self?.channelViewTopConstraint.constant = 108
            self?.view.layoutIfNeeded()
            
        }, completion: { [weak self] _ in
            self?.channelView.userInteractionEnabled = false
        })
    }
    
    private func hideSkillPickerView() {
        
        if pickedSkill == generalSkill {
            pickedSkill = nil
        }
        
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            
            self?.channelView.backgroundColor = UIColor.whiteColor()
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
            self?.channelView.userInteractionEnabled = true
        })
    }

    private func tryDeleteFeedVoice() {
        if case let .Voice(feedVoice) = attachment {
            do {
                try NSFileManager.defaultManager().removeItemAtURL(feedVoice.fileURL)
            } catch let error {
                println("delete voiceFileURL error: \(error)")
            }
        }
    }

    @objc private func cancel(sender: UIBarButtonItem) {
        
        messageTextView.resignFirstResponder()

        tryDeleteFeedVoice()

        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tryMakeUploadingFeed() -> DiscoveredFeed? {

        guard let
            myUserID = YepUserDefaults.userID.value,
            realm = try? Realm(),
            me = userWithUserID(myUserID, inRealm: realm) else {
                return nil
        }

        let creator = DiscoveredUser.fromUser(me)

        var kind: FeedKind = .Text

        let createdUnixTime = NSDate().timeIntervalSince1970
        let updatedUnixTime = createdUnixTime

        let message = messageTextView.text.trimming(.WhitespaceAndNewline)

        var feedAttachment: DiscoveredFeed.Attachment?

        switch attachment {

        case .Default:

            if !mediaImages.isEmpty {
                kind = .Image

                let imageAttachments: [DiscoveredAttachment] = mediaImages.map({ image in

                    let imageWidth = image.size.width
                    let imageHeight = image.size.height

                    let fixedImageWidth: CGFloat
                    let fixedImageHeight: CGFloat

                    if imageWidth > imageHeight {
                        fixedImageWidth = min(imageWidth, YepConfig.Media.miniImageWidth)
                        fixedImageHeight = imageHeight * (fixedImageWidth / imageWidth)
                    } else {
                        fixedImageHeight = min(imageHeight, YepConfig.Media.miniImageHeight)
                        fixedImageWidth = imageWidth * (fixedImageHeight / imageHeight)
                    }

                    let fixedSize = CGSize(width: fixedImageWidth, height: fixedImageHeight)

                    // resize to smaller, not need fixRotation

                    if let image = image.resizeToSize(fixedSize, withInterpolationQuality: .Medium) {
                        return DiscoveredAttachment(metadata: "", URLString: "", image: image)
                    } else {
                        return nil
                    }
                }).flatMap({ $0 })

                feedAttachment = .Images(imageAttachments)
            }

        case .Voice(let feedVoice):

            kind = .Audio

            let audioAsset = AVURLAsset(URL: feedVoice.fileURL, options: nil)
            let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

            let audioMetaDataInfo = [YepConfig.MetaData.audioSamples: feedVoice.limitedSampleValues, YepConfig.MetaData.audioDuration: audioDuration]

            let audioMetaData = try! NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: [])

            let audioInfo = DiscoveredFeed.AudioInfo(feedID: "", URLString: "", metaData: audioMetaData, duration: audioDuration, sampleValues: feedVoice.limitedSampleValues)

            feedAttachment = .Audio(audioInfo)

        default:
            break
        }

        return DiscoveredFeed(id: "", allowComment: true, kind: kind, createdUnixTime: createdUnixTime, updatedUnixTime: updatedUnixTime, creator: creator, body: message, attachment: feedAttachment, distance: 0, skill: pickedSkill, groupID: "", messagesCount: 0, uploadingErrorMessage: nil)
    }

    @objc private func post(sender: UIBarButtonItem) {
        post(again: false)
    }

    func post(again again: Bool) {

        let messageLength = (messageTextView.text as NSString).length

        guard messageLength <= YepConfig.maxFeedTextLength else {
            let message = String(format: NSLocalizedString("Feed info is too long!\nUp to %d letters.", comment: ""), YepConfig.maxFeedTextLength)
            YepAlert.alertSorry(message: message, inViewController: self)

            return
        }

        if !again {
            uploadState = .Uploading

            if let feed = tryMakeUploadingFeed() where feed.kind.needBackgroundUpload {
                beforeUploadingFeedAction?(feed: feed, newFeedViewController: self)

                YepHUD.hideActivityIndicator()
                dismissViewControllerAnimated(true, completion: nil)
            }
        }

        let message = messageTextView.text.trimming(.WhitespaceAndNewline)
        let coordinate = YepLocationService.sharedManager.currentLocation?.coordinate
        var kind: FeedKind = .Text
        var attachments: [JSONDictionary]?

        let tryCreateFeed: () -> Void = { [weak self] in

            var openGraph: OpenGraph?

            let doCreateFeed: () -> Void = { [weak self] in

                if let openGraph = openGraph where openGraph.isValid {

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
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        let message = errorMessage ?? NSLocalizedString("Create feed failed!", comment: "")
                        self?.uploadState = .Failed(message: message)
                    }

                }, completion: { data in
                    println("createFeedWithKind: \(data)")

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in

                        self?.uploadState = .Success

                        if let feed = DiscoveredFeed.fromFeedInfo(data, groupInfo: nil) {
                            self?.afterCreatedFeedAction?(feed: feed)

                            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.createdFeed, object: Box<DiscoveredFeed>(feed))
                        }

                        if !kind.needBackgroundUpload {
                            self?.dismissViewControllerAnimated(true, completion: nil)
                        }
                    }
                    
                    syncGroupsAndDoFurtherAction {}
                })
            }

            guard kind.needParseOpenGraph, let fisrtURL = message.yep_embeddedURLs.first else {
                doCreateFeed()

                return
            }

            let parseOpenGraphGroup = dispatch_group_create()


            dispatch_group_enter(parseOpenGraphGroup)

            openGraphWithURL(fisrtURL, failureHandler: { reason, errorMessage in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {
                    dispatch_group_leave(parseOpenGraphGroup)
                }

            }, completion: { _openGraph in
                println("_openGraph: \(_openGraph)")

                dispatch_async(dispatch_get_main_queue()) {
                    openGraph = _openGraph

                    dispatch_group_leave(parseOpenGraphGroup)
                }
            })

            dispatch_group_notify(parseOpenGraphGroup, dispatch_get_main_queue()) {
                doCreateFeed()
            }
        }

        switch attachment {

        case .Default:

            let mediaImagesCount = mediaImages.count

            let uploadImagesQueue = NSOperationQueue()
            var uploadAttachmentOperations = [UploadAttachmentOperation]()
            var uploadedAttachments = [UploadedAttachment]()
            var uploadErrorMessage: String?

            mediaImages.forEach({ image in

                let imageWidth = image.size.width
                let imageHeight = image.size.height

                let fixedImageWidth: CGFloat
                let fixedImageHeight: CGFloat

                if imageWidth > imageHeight {
                    fixedImageWidth = min(imageWidth, YepConfig.Media.imageWidth)
                    fixedImageHeight = imageHeight * (fixedImageWidth / imageWidth)
                } else {
                    fixedImageHeight = min(imageHeight, YepConfig.Media.imageHeight)
                    fixedImageWidth = imageWidth * (fixedImageHeight / imageHeight)
                }

                let fixedSize = CGSize(width: fixedImageWidth, height: fixedImageHeight)

                // resize to smaller, not need fixRotation

                if let image = image.resizeToSize(fixedSize, withInterpolationQuality: CGInterpolationQuality.High), imageData = UIImageJPEGRepresentation(image, 0.95) {

                    let source: UploadAttachment.Source = .Data(imageData)
                    let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: false)
                    let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .JPEG, metaDataString: metaDataString)

                    let operation = UploadAttachmentOperation(uploadAttachment: uploadAttachment) { result in
                        switch result {
                        case .Failed(let errorMessage):
                            if let errorMessage = errorMessage {
                                uploadErrorMessage = errorMessage
                            }
                        case .Success(let uploadedAttachment):
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

            let uploadFinishOperation = NSBlockOperation { [weak self] in

                guard uploadedAttachments.count == mediaImagesCount else {
                    let message = uploadErrorMessage ?? NSLocalizedString("Upload failed!", comment: "")

                    println("uploadedAttachments.count == mediaImagesCount: \(uploadedAttachments.count), \(mediaImagesCount)")
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self?.uploadState = .Failed(message: message)
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
                            let scaledKey = ImageCache.attachmentSideLengthKeyWithURLString(URLString, sideLength: sideLength)
                            let scaledImage = image.scaleToMinSideLength(sideLength)
                            let scaledData = UIImageJPEGRepresentation(image, 1.0)
                            Kingfisher.ImageCache.defaultCache.storeImage(scaledImage, originalData: scaledData, forKey: scaledKey, toDisk: true, completionHandler: nil)
                        }

                        do {
                            let originalKey = ImageCache.attachmentOriginKeyWithURLString(URLString)
                            let originalData = UIImageJPEGRepresentation(image, 1.0)
                            Kingfisher.ImageCache.defaultCache.storeImage(image, originalData: originalData, forKey: originalKey, toDisk: true, completionHandler: nil)
                        }
                    }
                }
            }

            if let lastUploadAttachmentOperation = uploadAttachmentOperations.last {
                uploadFinishOperation.addDependency(lastUploadAttachmentOperation)
            }

            uploadImagesQueue.addOperations(uploadAttachmentOperations, waitUntilFinished: false)
            uploadImagesQueue.addOperation(uploadFinishOperation)

        case .SocialWork(let socialWork):

            guard let type = MessageSocialWorkType(rawValue: socialWork.type) else {
                return
            }

            switch type {

            case .GithubRepo:

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

            case .DribbbleShot:

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

        case .Voice(let feedVoice):

            let audioAsset = AVURLAsset(URL: feedVoice.fileURL, options: nil)
            let audioDuration = CMTimeGetSeconds(audioAsset.duration) as Double

            let audioMetaDataInfo = [YepConfig.MetaData.audioSamples: feedVoice.limitedSampleValues, YepConfig.MetaData.audioDuration: audioDuration]

            var metaDataString = ""
            if let audioMetaData = try? NSJSONSerialization.dataWithJSONObject(audioMetaDataInfo, options: []) {
                if let audioMetaDataString = NSString(data: audioMetaData, encoding: NSUTF8StringEncoding) as? String {
                    metaDataString = audioMetaDataString
                }
            }

            let uploadVoiceGroup = dispatch_group_create()

            var uploadErrorMessage: String?

            dispatch_group_enter(uploadVoiceGroup)

            let source: UploadAttachment.Source = .FilePath(feedVoice.fileURL.path!)

            let uploadAttachment = UploadAttachment(type: .Feed, source: source, fileExtension: .M4A, metaDataString: metaDataString)

            tryUploadAttachment(uploadAttachment, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {
                    uploadErrorMessage = errorMessage
                    dispatch_group_leave(uploadVoiceGroup)
                }

            }, completion: { uploadedAttachment in

                let audioInfo: JSONDictionary = [
                    "id": uploadedAttachment.ID
                ]

                attachments = [audioInfo]

                dispatch_async(dispatch_get_main_queue()) {
                    dispatch_group_leave(uploadVoiceGroup)
                }
            })

            dispatch_group_notify(uploadVoiceGroup, dispatch_get_main_queue()) { [weak self] in

                guard attachments != nil else {
                    let message = uploadErrorMessage ?? NSLocalizedString("Upload failed!", comment: "")
                    self?.uploadState = .Failed(message: message)

                    return
                }

                kind = .Audio

                tryCreateFeed()

                self?.tryDeleteFeedVoice()
            }

        case .Location(let location):

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

    @IBAction private func playOrPauseAudio(sender: UIButton) {
        YepAlert.alertSorry(message: "你以为可以播放吗？\nNIX已经累死了。", inViewController: self)
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension NewFeedViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return 1
        case 1:
            return mediaImages.count
        default:
            return 0
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        switch indexPath.section {
            
        case 0:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedMediaAddCellID, forIndexPath: indexPath) as! FeedMediaAddCell
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedMediaCellID, forIndexPath: indexPath) as! FeedMediaCell
            
            let image = mediaImages[indexPath.item]
            
            cell.configureWithImage(image)
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
        
        return CGSize(width: 80, height: 80)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        switch indexPath.section {
            
        case 0:

            messageTextView.resignFirstResponder()
            
            if mediaImages.count == 4 {
                YepAlert.alertSorry(message: NSLocalizedString("Feed can only has 4 photos.", comment: ""), inViewController: self)
                return
            }
            
            let pickAlertController = UIAlertController(title: NSLocalizedString("Choose Source", comment: ""), message: nil, preferredStyle: .ActionSheet)
            
            let cameraAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .Default) { action -> Void in

                proposeToAccess(.Camera, agreed: { [weak self] in

                    guard UIImagePickerController.isSourceTypeAvailable(.Camera) else {
                        self?.alertCanNotOpenCamera()
                        return
                    }

                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = .Camera
                        strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                    }
                    
                }, rejected: { [weak self] in
                    self?.alertCanNotOpenCamera()
                })
            }
            
            pickAlertController.addAction(cameraAction)
            
            let albumAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Albums", comment: ""), style: .Default) { [weak self] action -> Void in

                proposeToAccess(.Photos, agreed: { [weak self] in
                    self?.performSegueWithIdentifier("showPickPhotos", sender: nil)
                    
                }, rejected: { [weak self] in
                    self?.alertCanNotAccessCameraRoll()
                })
            }
        
            pickAlertController.addAction(albumAction)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in

            }
        
            pickAlertController.addAction(cancelAction)
        
            self.presentViewController(pickAlertController, animated: true, completion: nil)

        case 1:
            mediaImages.removeAtIndex(indexPath.item)
//            if !imageAssets.isEmpty {
//                imageAssets.removeAtIndex(indexPath.item)
//            }
            collectionView.deleteItemsAtIndexPaths([indexPath])
            
        default:
            break
        }
    }
}

// MARK: - UIScrollViewDelegate

extension NewFeedViewController: UITextViewDelegate {

    func textViewShouldBeginEditing(textView: UITextView) -> Bool {

        if !isDirty {
            textView.text = ""
        }

        isNeverInputMessage = false

        return true
    }

    func textViewDidChange(textView: UITextView) {

        isDirty = NSString(string: textView.text).length > 0
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        
        hideSkillPickerView()
    }
}

// MARK: - UIScrollViewDelegate

extension NewFeedViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        
        messageTextView.resignFirstResponder()
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension NewFeedViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return skills.isEmpty ? 0 : 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return skills.count
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        
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
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        pickedSkill = skills[row % skills.count]
    }
}

extension NewFeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        if let mediaType = info[UIImagePickerControllerMediaType] as? String {
            
            switch mediaType {
                
            case kUTTypeImage as! String:
                
                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                    if mediaImages.count <= 3 {
                        mediaImages.append(image)
                    }
                }
                
            default:
                break
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}

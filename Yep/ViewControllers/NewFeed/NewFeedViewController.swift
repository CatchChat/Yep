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
import Crashlytics
import Kingfisher
import MapKit

let generalSkill = Skill(category: nil, id: "", name: "general", localName: NSLocalizedString("Choose...", comment: ""), coverURLString: nil)

struct FeedVoice {

    let fileURL: NSURL
    let sampleValuesCount: Int
    let limitedSampleValues: [CGFloat]
}

class NewFeedViewController: UIViewController {

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

    var afterCreatedFeedAction: ((feed: DiscoveredFeed) -> Void)?

    var preparedSkill: Skill?


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

    private let infoAboutThisFeed = NSLocalizedString("Info about this Feed...", comment: "")

    private var isNeverInputMessage = true
    private var isDirty = false {
        willSet {
            postButton.enabled = newValue

            if !newValue && isNeverInputMessage {
                messageTextView.text = infoAboutThisFeed
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("New Feed", comment: "")
        view.backgroundColor = UIColor.yepBackgroundColor()
        
        navigationItem.rightBarButtonItem = postButton

        if !attachment.needPrepare {
            let cancleButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .Plain, target: self, action: "cancel:")

            navigationItem.leftBarButtonItem = cancleButton
        }
        
        view.sendSubviewToBack(feedWhiteBGView)
        
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
//                self?.imageAssets = imageAssets
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
    
    private struct UploadImageInfo {
        
        let s3UploadParams: S3UploadParams
        let metaDataString: String?
    }
    
    @objc private func post(sender: UIBarButtonItem) {

        sender.enabled = false

        messageTextView.resignFirstResponder()
        
        let messageLength = (messageTextView.text as NSString).length
        
        if messageLength > YepConfig.maxFeedTextLength {
            return
        }
        
        // Begin Uploading
        YepHUD.showActivityIndicator()
        
        let message = messageTextView.text
        let coordinate = YepLocationService.sharedManager.currentLocation?.coordinate
        var kind: FeedKind = .Text
        var mediaInfo: JSONDictionary?

        let doCreateFeed: () -> Void = { [weak self] in

            if let userID = YepUserDefaults.userID.value, nickname = YepUserDefaults.nickname.value {
                Answers.logCustomEventWithName("New Feed",
                    customAttributes: [
                        "userID": userID,
                        "nickname": nickname,
                        "time": NSDate().description
                    ])
            }

            createFeedWithKind(kind, message: message, attachments: mediaInfo, coordinate: coordinate, skill: self?.pickedSkill, allowComment: true, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage: errorMessage)

                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Create feed failed!", comment: ""), inViewController: self)

                dispatch_async(dispatch_get_main_queue()) {
                    sender.enabled = true
                }

                YepHUD.hideActivityIndicator()

            }, completion: { data in
                println(data)

                YepHUD.hideActivityIndicator()

                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                    if let feed = DiscoveredFeed.fromFeedInfo(data, groupInfo: nil) {
                        self?.afterCreatedFeedAction?(feed: feed)
                    }

                    self?.dismissViewControllerAnimated(true, completion: nil)
                }
                
                syncGroupsAndDoFurtherAction {}
            })
        }

        let uploadMediaImagesGroup = dispatch_group_create()

        switch attachment {

        case .Default:

            var uploadImageInfos = [UploadImageInfo]()

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

                    dispatch_group_enter(uploadMediaImagesGroup)

                    s3UploadFileOfKind(.Feed, inFilePath: nil, orFileData: imageData, mimeType: MessageMediaType.Image.mineType, failureHandler: { (reason, errorMessage) in

                        defaultFailureHandler(reason, errorMessage: errorMessage)

                        dispatch_async(dispatch_get_main_queue()) {
                            dispatch_group_leave(uploadMediaImagesGroup)
                        }

                    }, completion: { s3UploadParams in

                        // Prepare meta data

                        let metaDataString = metaDataStringOfImage(image, needBlurThumbnail: false)

                        let uploadImageInfo = UploadImageInfo(s3UploadParams: s3UploadParams, metaDataString: metaDataString)

                        dispatch_async(dispatch_get_main_queue()) {
                            uploadImageInfos.append(uploadImageInfo)

                            dispatch_group_leave(uploadMediaImagesGroup)
                        }
                    })
                }
            })

            dispatch_group_notify(uploadMediaImagesGroup, dispatch_get_main_queue()) {

                if !uploadImageInfos.isEmpty {

                    let imageInfosData = uploadImageInfos.map({
                        [
                            "file": $0.s3UploadParams.key,
                            "metadata": $0.metaDataString ?? "",
                        ]
                    })

                    mediaInfo = [
                        "image": imageInfosData,
                    ]

                    kind = .Image
                }

                doCreateFeed()
            }

        case .SocialWork(let socialWork):

            guard let type = MessageSocialWorkType(rawValue: socialWork.type) else {
                return
            }

            switch type {

            case .GithubRepo:

                guard let githubRepo = socialWork.githubRepo else {
                    break
                }

                let repoInfo = [
                    "repo_id": githubRepo.repoID,
                    "name": githubRepo.name,
                    "full_name": githubRepo.fullName,
                    "description": githubRepo.repoDescription,
                    "url": githubRepo.URLString,
                    "created_at": githubRepo.createdUnixTime,
                ]

                mediaInfo = [
                    "github": [repoInfo]
                ]

                kind = .GithubRepo

            case .DribbbleShot:

                guard let dribbbleShot = socialWork.dribbbleShot else {
                    break
                }

                let shotInfo = [
                    "shot_id": dribbbleShot.shotID,
                    "title": dribbbleShot.title,
                    "description": dribbbleShot.shotDescription,
                    "media_url": dribbbleShot.imageURLString,
                    "url": dribbbleShot.htmlURLString,
                    "created_at": dribbbleShot.createdUnixTime,
                ]

                mediaInfo = [
                    "dribbble": [shotInfo]
                ]

                kind = .DribbbleShot

            default:
                break
            }

            doCreateFeed()

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

            dispatch_group_enter(uploadMediaImagesGroup)

            s3UploadFileOfKind(.Feed, inFilePath: feedVoice.fileURL.path, orFileData: nil, mimeType: MessageMediaType.Audio.mineType, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {
                    dispatch_group_leave(uploadMediaImagesGroup)
                }

            }, completion: { s3UploadParams in

                let audioInfo = [
                    "file": s3UploadParams.key,
                    "metadata": metaDataString,
                ]

                mediaInfo = [
                    "audio": [audioInfo]
                ]

                dispatch_async(dispatch_get_main_queue()) {
                    dispatch_group_leave(uploadMediaImagesGroup)
                }
            })

            dispatch_group_notify(uploadMediaImagesGroup, dispatch_get_main_queue()) { [weak self] in
                kind = .Audio
                doCreateFeed()

                self?.tryDeleteFeedVoice()
            }

        case .Location(let location):

            let locationInfo = [
                "place": location.info.name ?? "",
                "latitude": location.info.coordinate.latitude,
                "longitude": location.info.coordinate.longitude,
            ]

            mediaInfo = [
                "location": [locationInfo]
            ]

            kind = .Location

            doCreateFeed()
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
                    
                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
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

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        
        let newString = textView.text! + text
        
        if NSString(string: newString).length > YepConfig.maxFeedTextLength {
            return false
        }
        
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        if NSString(string: textView.text).length > YepConfig.maxFeedTextLength {
            textView.text = (textView.text as NSString).substringWithRange(NSMakeRange(0,YepConfig.maxFeedTextLength))
        }

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

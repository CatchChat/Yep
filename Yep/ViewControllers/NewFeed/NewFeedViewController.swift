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
let genrealSkill = Skill(category: nil, id: "", name: "general", localName: NSLocalizedString("Choose...", comment: ""), coverURLString: nil)

class NewFeedViewController: UIViewController {
    
    var afterCreatedFeedAction: ((feed: DiscoveredFeed) -> Void)?
    
    @IBOutlet weak var feedWhiteBGView: UIView!
    
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var mediaCollectionView: UICollectionView!
    
    @IBOutlet weak var channelView: UIView!
    @IBOutlet weak var channelViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var channelViewTopLineView: HorizontalLineView!
    @IBOutlet weak var channelViewBottomLineView: HorizontalLineView!
    
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var choosePromptLabel: UILabel!
    
    @IBOutlet weak var pickedSkillBubbleImageView: UIImageView!
    @IBOutlet weak var pickedSkillLabel: UILabel!
    
    @IBOutlet weak var skillPickerView: UIPickerView!

    var isDirty = false {
        willSet {
            postButton.enabled = newValue
        }
    }

    lazy var postButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Post", comment: ""), style: .Plain, target: self, action: "post:")
            button.enabled = false
        return button
    }()

    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.allowsEditing = false
        return imagePicker
    }()
    
    var imageAssets: [PHAsset] = []
    
    var mediaImages = [UIImage]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.mediaCollectionView.reloadData()
            }
        }
    }
    
    let feedMediaAddCellID = "FeedMediaAddCell"
    let feedMediaCellID = "FeedMediaCell"
    
    //let max = Int(INT16_MAX)
    
    let skills: [Skill] = {
        if let
            myUserID = YepUserDefaults.userID.value,
            realm = try? Realm(),
            me = userWithUserID(myUserID, inRealm: realm) {
                
                var skills = skillsFromUserSkillList(me.masterSkills) + skillsFromUserSkillList(me.learningSkills)
                
                skills.insert(genrealSkill, atIndex: 0)
                
                return skills
        }
        
        return []
    }()
    
    var preparedSkill: Skill?
    var pickedSkill: Skill? {
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
        
        let cancleButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .Plain, target: self, action: "cancel:")
        
        navigationItem.leftBarButtonItem = cancleButton
        
        view.sendSubviewToBack(feedWhiteBGView)
        
        messageTextView.text = ""
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
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        delay(1) { [weak self] in
            self?.messageTextView.becomeFirstResponder()
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
    
    func showSkillPickerView(tap: UITapGestureRecognizer) {
        
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
    
    func hideSkillPickerView() {
        
        if pickedSkill == genrealSkill {
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
    
    func cancel(sender: UIBarButtonItem) {
        
        messageTextView.resignFirstResponder()
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    struct UploadImageInfo {
        
        let s3UploadParams: S3UploadParams
        let metaDataString: String?
    }
    
    func post(sender: UIBarButtonItem) {
        
        messageTextView.resignFirstResponder()
        
        let messageLength = (messageTextView.text as NSString).length
        
        if messageLength > YepConfig.maxFeedTextLength {
            return
        }
        
        // Begin Uploading
        YepHUD.showActivityIndicator()
        
        let message = messageTextView.text
        
        let coordinate = YepLocationService.sharedManager.currentLocation?.coordinate
        
        let uploadMediaImagesGroup = dispatch_group_create()
        
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
            
            
            if let image = image.resizeToSize(fixedSize, withInterpolationQuality: CGInterpolationQuality.High),
                imageData = UIImageJPEGRepresentation(image, 0.95) {
                
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
        
        dispatch_group_notify(uploadMediaImagesGroup, dispatch_get_main_queue()) { [weak self] in
            
            var mediaInfo: JSONDictionary?
            
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
            }
            
            if let userID = YepUserDefaults.userID.value,
                nickname = YepUserDefaults.nickname.value{
                    Answers.logCustomEventWithName("New Feed",
                        customAttributes: [
                            "userID": userID,
                            "nickname": nickname,
                            "time": NSDate().description
                        ])
                    
            }

            createFeedWithKind(.Normal, message: message, attachments: mediaInfo, appleMedia: nil, coordinate: coordinate, skill: self?.pickedSkill, allowComment: true, failureHandler: { [weak self] reason, errorMessage in
                defaultFailureHandler(reason, errorMessage: errorMessage)
                
                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Create feed failed!", comment: ""), inViewController: self)
                
                YepHUD.hideActivityIndicator()
                
            }, completion: { data in
                println(data)
                
                YepHUD.hideActivityIndicator()
                
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    
                    if let feed = DiscoveredFeed.fromJSONDictionary(data) {
                        self?.afterCreatedFeedAction?(feed: feed)
                    }
                    
                    self?.dismissViewControllerAnimated(true, completion: nil)
                }

                syncGroupsAndDoFurtherAction {}
            })
        }
    }
}

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
            
            if mediaImages.count == 4 {
                YepAlert.alertSorry(message: NSLocalizedString("Feed can only has 4 photos.", comment: ""), inViewController: self)
                return
            }
            
            let pickActionController = UIAlertController(title: NSLocalizedString("Choose Source", comment: ""), message: nil, preferredStyle: .ActionSheet)
            
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
            
            pickActionController.addAction(cameraAction)
            
            let albumAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Albums", comment: ""), style: .Default) { [weak self] action -> Void in

                proposeToAccess(.Photos, agreed: { [weak self] in
                    self?.performSegueWithIdentifier("showPickPhotos", sender: nil)
                    
                }, rejected: { [weak self] in
                        self?.alertCanNotAccessCameraRoll()
                })
                
            }
        
            pickActionController.addAction(albumAction)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in

            }
        
            pickActionController.addAction(cancelAction)
        
            self.presentViewController(pickActionController, animated: true, completion: nil)
        
            
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

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

class NewFeedViewController: UIViewController {

    @IBOutlet weak var feedWhiteBGView: UIView!
    
    var afterCreatedFeedAction: ((feed: DiscoveredFeed) -> Void)?

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var mediaCollectionView: UICollectionView!
    //@IBOutlet weak var pickFeedSkillView: PickFeedSkillView!
    //@IBOutlet weak var pickFeedSkillViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var skillPickerView: UIPickerView!

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

    let max = Int(INT16_MAX)

    let skills: [Skill] = {
        if let
            myUserID = YepUserDefaults.userID.value,
            realm = try? Realm(),
            me = userWithUserID(myUserID, inRealm: realm) {
                return skillsFromUserSkillList(me.masterSkills) + skillsFromUserSkillList(me.learningSkills)
        }

        return []
        }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("New Feed", comment: "")
        view.backgroundColor = UIColor.yepBackgroundColor()

        let postButton = UIBarButtonItem(title: NSLocalizedString("Post", comment: ""), style: .Plain, target: self, action: "post:")

        navigationItem.rightBarButtonItem = postButton
        
        let cancleButton = UIBarButtonItem(title: NSLocalizedString("Cancel", comment: ""), style: .Plain, target: self, action: "cancel:")
        
        navigationItem.leftBarButtonItem = cancleButton
        
        view.sendSubviewToBack(feedWhiteBGView)

        messageTextView.text = ""
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        //messageTextView.becomeFirstResponder()

        mediaCollectionView.backgroundColor = UIColor.clearColor()

        mediaCollectionView.registerNib(UINib(nibName: feedMediaAddCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaAddCellID)
        mediaCollectionView.registerNib(UINib(nibName: feedMediaCellID, bundle: nil), forCellWithReuseIdentifier: feedMediaCellID)
        mediaCollectionView.contentInset.left = 15
        mediaCollectionView.dataSource = self
        mediaCollectionView.delegate = self

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

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showPickPhotos" {

            let vc = segue.destinationViewController as! PickPhotosViewController

            vc.pickedImageSet = Set(imageAssets)

            vc.completion = { [weak self] images, imageAssets in
                self?.mediaImages = images
                self?.imageAssets = imageAssets
            }
        }
    }

    // MARK: Actions

    func cancel(sender: UIBarButtonItem) {
        messageTextView.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func post(sender: UIBarButtonItem) {

        YepHUD.showActivityIndicator()

        let message = messageTextView.text

        let coordinate = YepLocationService.sharedManager.currentLocation?.coordinate

        let uploadMediaImagesGroup = dispatch_group_create()

        var allS3UploadParams = [S3UploadParams]()

        mediaImages.forEach({ image in

            if let imageData = UIImageJPEGRepresentation(image, 0.7) {

                dispatch_group_enter(uploadMediaImagesGroup)

                s3UploadFileOfKind(.Feed, inFilePath: nil, orFileData: imageData, mimeType: MessageMediaType.Image.mineType, failureHandler: { (reason, errorMessage) in

                    defaultFailureHandler(reason, errorMessage: errorMessage)

                    dispatch_async(dispatch_get_main_queue()) {
                        dispatch_group_leave(uploadMediaImagesGroup)
                    }

                }, completion: { s3UploadParams in

                    dispatch_async(dispatch_get_main_queue()) {
                        allS3UploadParams.append(s3UploadParams)

                        dispatch_group_leave(uploadMediaImagesGroup)
                    }
                })
            }
        })

        dispatch_group_notify(uploadMediaImagesGroup, dispatch_get_main_queue()) {

            var mediaInfo: JSONDictionary?

            if !allS3UploadParams.isEmpty {

                let imageInfosData = allS3UploadParams.map({
                    [
                        "file": $0.key,
                        "metadata": "", // TODO: metadata, maybe not need
                    ]
                })

                mediaInfo = [
                    "image": imageInfosData,
                ]
            }

            createFeedWithMessage(message, attachments: mediaInfo, coordinate: coordinate, skill: nil, allowComment: true, failureHandler: { [weak self] reason, errorMessage in
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
            proposeToAccess(.Photos, agreed: { [weak self] in
                self?.performSegueWithIdentifier("showPickPhotos", sender: nil)

            }, rejected: { [weak self] in
                self?.alertCanNotAccessCameraRoll()
            })

        case 1:
            mediaImages.removeAtIndex(indexPath.item)
            imageAssets.removeAtIndex(indexPath.item)
            collectionView.deleteItemsAtIndexPaths([indexPath])

        default:
            break
        }
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension NewFeedViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return max
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
}



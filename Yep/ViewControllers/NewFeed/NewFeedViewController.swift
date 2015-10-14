//
//  NewFeedViewController.swift
//  Yep
//
//  Created by nixzhu on 15/9/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Proposer
import CoreLocation
import MobileCoreServices

class NewFeedViewController: UIViewController {

    @IBOutlet weak var feedWhiteBGView: UIView!
    
    var afterCreatedFeedAction: ((feed: DiscoveredFeed) -> Void)?

    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var mediaCollectionView: UICollectionView!

    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String]
        imagePicker.videoQuality = .TypeMedium
        imagePicker.allowsEditing = false
        return imagePicker
        }()

    var mediaImages = [UIImage]() {
        didSet {
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.mediaCollectionView.reloadData()
            }
        }
    }

    let feedMediaAddCellID = "FeedMediaAddCell"
    let feedMediaCellID = "FeedMediaCell"

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
        messageTextView.becomeFirstResponder()

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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        // touch to create (if need) for faster appear
        delay(0.2) { [weak self] in
            self?.imagePicker.hidesBarsOnTap = false
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showPickPhotos" {

            let vc = segue.destinationViewController as! PickPhotosViewController

            vc.completion = { [weak self] images in
                self?.mediaImages.appendContentsOf(images)
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
            /*
            let openCameraRoll: ProposerAction = { [weak self] in
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary) {
                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = .SavedPhotosAlbum
                        strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                    }
                }
            }

            proposeToAccess(.Photos, agreed: openCameraRoll, rejected: { [weak self] in
                self?.alertCanNotAccessCameraRoll()
            })
            */

            proposeToAccess(.Photos, agreed: { [weak self] in
                self?.performSegueWithIdentifier("showPickPhotos", sender: nil)

            }, rejected: { [weak self] in
                self?.alertCanNotAccessCameraRoll()
            })

        case 1:
            mediaImages.removeAtIndex(indexPath.item)
            collectionView.deleteItemsAtIndexPaths([indexPath])

        default:
            break
        }
    }
}

extension NewFeedViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {

        if let mediaType = info[UIImagePickerControllerMediaType] as? String {

            if mediaType == (kUTTypeImage as String) {

                if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {

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

                    if let fixedImage = image.resizeToSize(fixedSize, withInterpolationQuality: CGInterpolationQuality.Medium) {
                        mediaImages.append(fixedImage)
                    }
                }
            }
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}


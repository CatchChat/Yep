//
//  EditProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

class EditProfileViewController: UIViewController {

    struct Notification {
        static let Logout = "LogoutNotification"
    }

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var mobileLabel: UILabel!

    @IBOutlet weak var editProfileTableView: UITableView!


    let editProfileLessInfoCellIdentifier = "EditProfileLessInfoCell"
    let editProfileMoreInfoCellIdentifier = "EditProfileMoreInfoCell"
    let editProfileColoredTitleCellIdentifier = "EditProfileColoredTitleCell"

    var introduction: String {
        get {
            return YepUserDefaults.introduction.value ?? NSLocalizedString("No Introduction yet.", comment: "")
        }
    }

    let introAttributes = [NSFontAttributeName: YepConfig.EditProfile.introFont]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Edit Profile", comment: "")

        let avatarSize = YepConfig.editProfileAvatarSize()
        avatarImageViewWidthConstraint.constant = avatarSize

        updateAvatar() {
        }

        mobileLabel.text = YepUserDefaults.mobile.value

        editProfileTableView.registerNib(UINib(nibName: editProfileLessInfoCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileLessInfoCellIdentifier)
        editProfileTableView.registerNib(UINib(nibName: editProfileMoreInfoCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileMoreInfoCellIdentifier)
        editProfileTableView.registerNib(UINib(nibName: editProfileColoredTitleCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileColoredTitleCellIdentifier)
    }

    func updateAvatar(completion:() -> Void) {
        if let avatarURLString = YepUserDefaults.avatarURLString.value {

            let avatarSize = YepConfig.editProfileAvatarSize()

            self.avatarImageView.alpha = 0
            AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: avatarSize * 0.5) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = image

                    completion()

                    UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                        self.avatarImageView.alpha = 1
                    }, completion: { (finished) -> Void in
                    })
                }
            }
        }
    }

    @IBAction func changeAvatar(sender: UITapGestureRecognizer) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let choosePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Choose Photo", comment: ""), style: .Default) { action -> Void in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
                imagePicker.allowsEditing = false

                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }
        alertController.addAction(choosePhotoAction)

        let takePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .Default) { action -> Void in
            if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
                imagePicker.allowsEditing = false

                self.presentViewController(imagePicker, animated: true, completion: nil)
            }
        }
        alertController.addAction(takePhotoAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)

        self.presentViewController(alertController, animated: true, completion: nil)
    }

}

extension EditProfileViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case Info
        case LogOut
    }

    enum InfoRow: Int {
        case Name = 0
        case Intro
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {

        case Section.Info.rawValue:
            return 2

        case Section.LogOut.rawValue:
            return 1

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {

        case Section.Info.rawValue:

            switch indexPath.row {
            case InfoRow.Name.rawValue:
                let cell = tableView.dequeueReusableCellWithIdentifier(editProfileLessInfoCellIdentifier) as! EditProfileLessInfoCell

                cell.annotationLabel.text = NSLocalizedString("Nickname", comment: "")

                YepUserDefaults.nickname.bindAndFireListener("EditProfileLessInfoCell.Nickname") { nickname in
                    cell.infoLabel.text = nickname
                }

                return cell

            case InfoRow.Intro.rawValue:
                let cell = tableView.dequeueReusableCellWithIdentifier(editProfileMoreInfoCellIdentifier) as! EditProfileMoreInfoCell

                cell.annotationLabel.text = NSLocalizedString("Introduction", comment: "")

                YepUserDefaults.introduction.bindAndFireListener("EditProfileLessInfoCell.Introduction") { introduction in
                    cell.infoLabel.text = introduction
                }

                return cell

            default:
                return UITableViewCell()
            }

        case Section.LogOut.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(editProfileColoredTitleCellIdentifier) as! EditProfileColoredTitleCell
            cell.coloredTitleLabel.text = NSLocalizedString("Log out", comment: "")
            cell.coloredTitleColor = UIColor.redColor()
            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.section {
        case Section.Info.rawValue:

            switch indexPath.row {
            case InfoRow.Name.rawValue:
                return 60

            case InfoRow.Intro.rawValue:
                let tableViewWidth = CGRectGetWidth(editProfileTableView.bounds)
                let introLabelMaxWidth = tableViewWidth - YepConfig.EditProfile.introInset

                let rect = introduction.boundingRectWithSize(CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: introAttributes, context: nil)

                let height = 20 + 22 + 20 + ceil(rect.height) + 20
                
                return height

            default:
                return 0
            }

        case Section.LogOut.rawValue:
            return 80

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.section {

        case Section.Info.rawValue:

            switch indexPath.row {

            case InfoRow.Name.rawValue:
                YepAlert.textInput(title: NSLocalizedString("Change nickname", comment: ""), placeholder: YepUserDefaults.nickname.value, oldText: nil, dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withFinishedAction: { (newNickname) -> Void in

                    if let oldNickname = YepUserDefaults.nickname.value {
                        if oldNickname == newNickname {
                            return
                        }
                    }

                    YepHUD.showActivityIndicator()

                    updateMyselfWithInfo(["nickname": newNickname], failureHandler: { (reason, errorMessage) in
                        defaultFailureHandler(reason, errorMessage)

                        YepHUD.hideActivityIndicator()

                    }, completion: { success in
                        dispatch_async(dispatch_get_main_queue()) {
                            YepUserDefaults.nickname.value = newNickname
                        }

                        YepHUD.hideActivityIndicator()
                    })
                })

            case InfoRow.Intro.rawValue:
                YepAlert.textInput(title: NSLocalizedString("New introduction", comment: ""), placeholder: nil, oldText: YepUserDefaults.introduction.value, dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withFinishedAction: { (newIntroduction) -> Void in

                    if let oldIntroduction = YepUserDefaults.introduction.value {
                        if oldIntroduction == newIntroduction {
                            return
                        }
                    }

                    YepHUD.showActivityIndicator()

                    updateMyselfWithInfo(["introduction": newIntroduction], failureHandler: { (reason, errorMessage) in
                        defaultFailureHandler(reason, errorMessage)

                        YepHUD.hideActivityIndicator()

                    }, completion: { success in
                        dispatch_async(dispatch_get_main_queue()) {
                            YepUserDefaults.introduction.value = newIntroduction
                        }

                        YepHUD.hideActivityIndicator()
                    })
                })

            default:
                break
            }

        case Section.LogOut.rawValue:
            YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("Do you want to logout?", comment: ""), confirmTitle: NSLocalizedString("Yes", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { () -> Void in

                YepUserDefaults.cleanAllUserDefaults()

                if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    appDelegate.startIntroStory()
                }

                cleanRealmAndCaches()

            }, cancelAction: { () -> Void in
            })

        default:
            break
        }
    }
}

// MARK: UIImagePicker

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {

        YepHUD.showActivityIndicator()

        s3PublicUploadParams(failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

            YepHUD.hideActivityIndicator()

        }, completion: { s3UploadParams in

            let image = image.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())

            var imageData = UIImageJPEGRepresentation(image, YepConfig.avatarCompressionQuality())

            uploadFileToS3(inFilePath: nil, orFileData: imageData, mimeType: "image/jpeg", s3UploadParams: s3UploadParams, completion: { (success, error) in
                println("upload avatar to s3 result: \(success), error: \(error)")

                if (success) {
                    let newAvatarURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"

                    updateMyselfWithInfo(["avatar_url": newAvatarURLString], failureHandler: { (reason, errorMessage) in
                        defaultFailureHandler(reason, errorMessage)
                        
                        YepHUD.hideActivityIndicator()

                    }, completion: { success in
                        dispatch_async(dispatch_get_main_queue()) {
                            YepUserDefaults.avatarURLString.value = newAvatarURLString

                            self.updateAvatar() {
                                YepHUD.hideActivityIndicator()
                            }
                        }
                    })

                } else {
                    YepHUD.hideActivityIndicator()
                }
            })
        })
        
        dismissViewControllerAnimated(true, completion: nil)
    }
}

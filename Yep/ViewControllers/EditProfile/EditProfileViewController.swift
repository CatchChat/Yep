//
//  EditProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import TPKeyboardAvoiding
import Proposer
import Navi

class EditProfileViewController: UIViewController {

    struct Notification {
        static let Logout = "LogoutNotification"
    }

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var mobileLabel: UILabel!

    @IBOutlet weak var editProfileTableView: TPKeyboardAvoidingTableView!

    lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        return imagePicker
        }()

    lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "saveIntroduction:")
        return button
        }()

    let editProfileLessInfoCellIdentifier = "EditProfileLessInfoCell"
    let editProfileMoreInfoCellIdentifier = "EditProfileMoreInfoCell"
    let editProfileColoredTitleCellIdentifier = "EditProfileColoredTitleCell"

    var introduction: String {
        get {
            return YepUserDefaults.introduction.value ?? NSLocalizedString("No Introduction yet.", comment: "")
        }
    }

    let introAttributes = [NSFontAttributeName: YepConfig.EditProfile.introFont]

    struct Listener {
        static let Nickname = "EditProfileLessInfoCell.Nickname"
        static let Introduction = "EditProfileLessInfoCell.Introduction"
        static let Badge = "EditProfileLessInfoCell.Badge"
    }

    deinit {
        YepUserDefaults.nickname.removeListenerWithName(Listener.Nickname)
        YepUserDefaults.introduction.removeListenerWithName(Listener.Introduction)
        YepUserDefaults.badge.removeListenerWithName(Listener.Badge)

        println("deinit EditProfileViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Edit Profile", comment: "")

        let avatarSize = YepConfig.editProfileAvatarSize()
        avatarImageViewWidthConstraint.constant = avatarSize

        updateAvatar() {
        }

        mobileLabel.text = YepUserDefaults.fullPhoneNumber

        editProfileTableView.registerNib(UINib(nibName: editProfileLessInfoCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileLessInfoCellIdentifier)
        editProfileTableView.registerNib(UINib(nibName: editProfileMoreInfoCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileMoreInfoCellIdentifier)
        editProfileTableView.registerNib(UINib(nibName: editProfileColoredTitleCellIdentifier, bundle: nil), forCellReuseIdentifier: editProfileColoredTitleCellIdentifier)
    }

    // MARK: Actions

    func updateAvatar(completion:() -> Void) {
        if let avatarURLString = YepUserDefaults.avatarURLString.value {

            let avatarSize = YepConfig.editProfileAvatarSize()
            let avatarStyle: AvatarStyle = .RoundedRectangle(size: CGSize(width: avatarSize, height: avatarSize), cornerRadius: avatarSize * 0.5, borderWidth: 0)
            let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: avatarStyle)
            avatarImageView.navi_setAvatar(plainAvatar)
            
            completion()
        }
    }

    @IBAction func changeAvatar(sender: UITapGestureRecognizer) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let choosePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Choose Photo", comment: ""), style: .Default) { action -> Void in

            let openCameraRoll: ProposerAction = { [weak self] in
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum) {
                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = .PhotoLibrary
                        strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                    }
                }
            }

            proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
                self.alertCanNotAccessCameraRoll()
            })
        }
        alertController.addAction(choosePhotoAction)

        let takePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .Default) { action -> Void in

            let openCamera: ProposerAction = { [weak self] in
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
                    if let strongSelf = self {
                        strongSelf.imagePicker.sourceType = .Camera
                        strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                    }
                }
            }

            proposeToAccess(.Camera, agreed: openCamera, rejected: {
                self.alertCanNotOpenCamera()
            })
        }
        alertController.addAction(takePhotoAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)

        self.presentViewController(alertController, animated: true, completion: nil)

        // touch to create (if need) for faster appear
        delay(0.2) { [weak self] in
            self?.imagePicker.hidesBarsOnTap = false
        }
    }

    func saveIntroduction(sender: UIBarButtonItem) {

        let introductionCellIndexPath = NSIndexPath(forRow: InfoRow.Intro.rawValue, inSection: Section.Info.rawValue)
        if let introductionCell = editProfileTableView.cellForRowAtIndexPath(introductionCellIndexPath) as? EditProfileMoreInfoCell {
            introductionCell.infoTextView.resignFirstResponder()
        }
    }
}

extension EditProfileViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case Info
        case LogOut
    }

    enum InfoRow: Int {
        case Username = 0
        case Nickname
        case Intro
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        switch section {

        case Section.Info.rawValue:
            return 3

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

            case InfoRow.Username.rawValue:

                let cell = tableView.dequeueReusableCellWithIdentifier(editProfileLessInfoCellIdentifier) as! EditProfileLessInfoCell

                cell.annotationLabel.text = NSLocalizedString("Username", comment: "")

                var username = ""
                if let
                    myUserID = YepUserDefaults.userID.value,
                    realm = try? Realm(),
                    me = userWithUserID(myUserID, inRealm: realm) {
                        username = me.username
                }

                if username.isEmpty {
                    cell.infoLabel.text = NSLocalizedString("None", comment: "")
                    cell.accessoryImageView.hidden = false
                    cell.selectionStyle = .Default
                } else {
                    cell.infoLabel.text = username
                    cell.accessoryImageView.hidden = true
                    cell.selectionStyle = .None
                }

                cell.badgeImageView.image = nil
                cell.infoLabelTrailingConstraint.constant = EditProfileLessInfoCell.ConstraintConstant.minInfoLabelTrailing

                return cell

            case InfoRow.Nickname.rawValue:

                let cell = tableView.dequeueReusableCellWithIdentifier(editProfileLessInfoCellIdentifier) as! EditProfileLessInfoCell

                cell.annotationLabel.text = NSLocalizedString("Nickname", comment: "")
                cell.accessoryImageView.hidden = false
                cell.selectionStyle = .Default

                YepUserDefaults.nickname.bindAndFireListener(Listener.Nickname) { [weak cell] nickname in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell?.infoLabel.text = nickname
                    }
                }

                YepUserDefaults.badge.bindAndFireListener(Listener.Badge) { [weak cell] badgeName in
                    dispatch_async(dispatch_get_main_queue()) {
                        if let badgeName = badgeName, badge = BadgeView.Badge(rawValue: badgeName) {
                            cell?.badgeImageView.image = badge.image
                            cell?.badgeImageView.tintColor = badge.color
                            cell?.infoLabelTrailingConstraint.constant = EditProfileLessInfoCell.ConstraintConstant.normalInfoLabelTrailing

                        } else {
                            cell?.badgeImageView.image = nil
                            cell?.infoLabelTrailingConstraint.constant = EditProfileLessInfoCell.ConstraintConstant.minInfoLabelTrailing
                        }
                    }
                }

                return cell

            case InfoRow.Intro.rawValue:

                let cell = tableView.dequeueReusableCellWithIdentifier(editProfileMoreInfoCellIdentifier) as! EditProfileMoreInfoCell

                cell.annotationLabel.text = NSLocalizedString("Introduction", comment: "")

                YepUserDefaults.introduction.bindAndFireListener(Listener.Introduction) { [weak cell] introduction in
                    dispatch_async(dispatch_get_main_queue()) {
                        cell?.infoTextView.text = introduction ?? NSLocalizedString("Introduce yourself here.", comment: "")
                    }
                }

                cell.infoTextViewIsDirtyAction = { [weak self] in
                    self?.navigationItem.rightBarButtonItem = self?.doneButton
                    self?.doneButton.enabled = true
                }

                cell.infoTextViewDidEndEditingAction = { [weak self] newIntroduction in
                    self?.doneButton.enabled = false

                    if let oldIntroduction = YepUserDefaults.introduction.value {
                        if oldIntroduction == newIntroduction {
                            return
                        }
                    }

                    YepHUD.showActivityIndicator()

                    updateMyselfWithInfo(["introduction": newIntroduction], failureHandler: { (reason, errorMessage) in
                        defaultFailureHandler(reason, errorMessage: errorMessage)

                        YepHUD.hideActivityIndicator()

                    }, completion: { success in
                        dispatch_async(dispatch_get_main_queue()) {
                            YepUserDefaults.introduction.value = newIntroduction

                            self?.editProfileTableView.reloadData()
                        }

                        YepHUD.hideActivityIndicator()
                    })
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

            case InfoRow.Username.rawValue:
                return 60

            case InfoRow.Nickname.rawValue:
                return 60

            case InfoRow.Intro.rawValue:

                let tableViewWidth = CGRectGetWidth(editProfileTableView.bounds)
                let introLabelMaxWidth = tableViewWidth - YepConfig.EditProfile.introInset

                let rect = introduction.boundingRectWithSize(CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: introAttributes, context: nil)

                let height = 20 + 22 + 10 + ceil(rect.height) + 20
                
                return max(height, 120)

            default:
                return 0
            }

        case Section.LogOut.rawValue:
            return 60

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        switch indexPath.section {

        case Section.Info.rawValue:

            switch indexPath.row {

            case InfoRow.Username.rawValue:

                if let
                    myUserID = YepUserDefaults.userID.value,
                    me = userWithUserID(myUserID, inRealm: try! Realm()) {

                        let username = me.username

                        if username.isEmpty {

                            YepAlert.textInput(title: NSLocalizedString("Set Username", comment: ""), message: NSLocalizedString("Please note that you can only set username once.", comment: ""), placeholder: NSLocalizedString("use letters, numbers, and underscore", comment: ""), oldText: nil, confirmTitle: NSLocalizedString("Set", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { text in

                                let newUsername = text

                                updateMyselfWithInfo(["username": newUsername], failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason, errorMessage: errorMessage)

                                    YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set username failed!", comment: ""), inViewController: self)

                                }, completion: { success in
                                    dispatch_async(dispatch_get_main_queue()) { [weak tableView] in
                                        guard let realm = try? Realm() else {
                                            return
                                        }
                                        
                                        if let
                                            myUserID = YepUserDefaults.userID.value,
                                            me = userWithUserID(myUserID, inRealm: realm) {
                                                let _ = try? realm.write {
                                                    me.username = newUsername
                                                }
                                        }

                                        // update UI

                                        if let usernameCell = tableView?.cellForRowAtIndexPath(indexPath) as? EditProfileLessInfoCell {
                                            usernameCell.infoLabel.text = newUsername
                                        }
                                    }
                                })
                                
                            }, cancelAction: {
                            })
                        }
                }

            case InfoRow.Nickname.rawValue:
                performSegueWithIdentifier("showEditNicknameAndBadge", sender: nil)

            default:
                break
            }

        case Section.LogOut.rawValue:

            YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("Do you want to logout?", comment: ""), confirmTitle: NSLocalizedString("Yes", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { () -> Void in

                unregisterThirdPartyPush()

                cleanRealmAndCaches()

                YepUserDefaults.cleanAllUserDefaults()

                if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    appDelegate.startShowStory()
                }

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

        let image = image.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())
        let imageData = UIImageJPEGRepresentation(image, YepConfig.avatarCompressionQuality())

        s3UploadFileOfKind(.Avatar, inFilePath: nil, orFileData: imageData, mimeType: MessageMediaType.Image.mineType, failureHandler: { (reason, errorMessage) in
            
            defaultFailureHandler(reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

        }, completion: { s3UploadParams in

            let newAvatarURLString = "\(s3UploadParams.url)\(s3UploadParams.key)"

            updateMyselfWithInfo(["avatar_url": newAvatarURLString], failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage: errorMessage)

                YepHUD.hideActivityIndicator()

            }, completion: { success in

                dispatch_async(dispatch_get_main_queue()) {
                    
                    YepUserDefaults.avatarURLString.value = newAvatarURLString

                    self.updateAvatar() {
                        YepHUD.hideActivityIndicator()
                    }
                }
            })
        })

        dismissViewControllerAnimated(true, completion: nil)
    }
}

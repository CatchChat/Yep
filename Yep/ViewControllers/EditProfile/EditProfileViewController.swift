//
//  EditProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import YepKit
import YepNetworking
import OpenGraph
import TPKeyboardAvoiding
import Proposer
import Navi

final class EditProfileViewController: SegueViewController {

    struct Notification {
        static let Logout = "LogoutNotification"
        static let NewUsername = "NewUsername"
    }

    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet private weak var mobileContainerView: UIStackView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(EditProfileViewController.tapMobileContainer(_:)))
            mobileContainerView.addGestureRecognizer(tap)
        }
    }
    @IBOutlet private weak var mobileLabel: UILabel! {
        didSet {
            mobileLabel.textColor = UIColor.yepTintColor()
        }
    }

    @IBOutlet private weak var editProfileTableView: TPKeyboardAvoidingTableView! {
        didSet {
            editProfileTableView.registerNibOf(EditProfileLessInfoCell)
            editProfileTableView.registerNibOf(EditProfileMoreInfoCell)
            editProfileTableView.registerNibOf(EditProfileColoredTitleCell)
        }
    }

    private lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        return imagePicker
    }()

    private lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(EditProfileViewController.save(_:)))
        return button
    }()
    private var giveUpEditing: Bool = false
    private var isDirty: Bool = false {
        didSet {
            navigationItem.rightBarButtonItem = doneButton
            doneButton.enabled = isDirty
        }
    }

    private var introduction: String {
        return YepUserDefaults.introduction.value ?? NSLocalizedString("No Introduction yet.", comment: "")
    }

    private var blogURLString: String {
        return YepUserDefaults.blogURLString.value ?? NSLocalizedString("Set blog URL here.", comment: "")
    }

    private let infoAttributes = [NSFontAttributeName: YepConfig.EditProfile.infoFont]

    private func heightOfCellForMoreInfo(info: String) -> CGFloat {

        let tableViewWidth: CGFloat = CGRectGetWidth(editProfileTableView.bounds)
        let introLabelMaxWidth: CGFloat = tableViewWidth - YepConfig.EditProfile.infoInset

        let rect: CGRect = info.boundingRectWithSize(CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: infoAttributes, context: nil)

        let height: CGFloat = 20 + 22 + 10 + ceil(rect.height) + 20

        return max(height, 120)
    }

    private struct Listener {
        static let Nickname = "EditProfileLessInfoCell.Nickname"
        static let Introduction = "EditProfileLessInfoCell.Introduction"
        static let Badge = "EditProfileLessInfoCell.Badge"
        static let Mobile = "EditProfileLessInfoCell.Mobile"
        static let Blog = "EditProfileLessInfoCell.Blog"
    }

    deinit {
        YepUserDefaults.nickname.removeListenerWithName(Listener.Nickname)
        YepUserDefaults.introduction.removeListenerWithName(Listener.Introduction)
        YepUserDefaults.mobile.removeListenerWithName(Listener.Mobile)
        YepUserDefaults.badge.removeListenerWithName(Listener.Badge)

        editProfileTableView?.delegate = nil

        println("deinit EditProfile")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Edit Profile", comment: "")

        let avatarSize = YepConfig.editProfileAvatarSize()
        avatarImageViewWidthConstraint.constant = avatarSize

        updateAvatar() {}

        YepUserDefaults.mobile.bindAndFireListener(Listener.Mobile) { [weak self] _ in
            self?.mobileLabel.text = YepUserDefaults.fullPhoneNumber
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        giveUpEditing = false
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        giveUpEditing = true

        view.endEditing(true)
    }

    // MARK: Unwind

    @IBAction func unwindToEditProfile(segue: UIStoryboardSegue) {
    }

    // MARK: Actions

    private func uploadContacts() {

        let uploadContacts = UploadContactsMaker.make()

        YepHUD.showActivityIndicator()

        println("uploadContacts.count: \(uploadContacts.count)")

        friendsInContacts(uploadContacts, failureHandler: { (reason, errorMessage) in
            YepHUD.hideActivityIndicator()

            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

        }, completion: { [weak self] discoveredUsers in
            YepHUD.hideActivityIndicator()
            println("friendsInContacts discoveredUsers.count: \(discoveredUsers.count)")

            YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("Yep will match friends from your contacts for you.", comment: ""), dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withDismissAction: nil)
        })
    }

    private func updateAvatar(completion:() -> Void) {
        if let avatarURLString = YepUserDefaults.avatarURLString.value {

            println("avatarURLString: \(avatarURLString)")

            let avatarSize = YepConfig.editProfileAvatarSize()
            let avatarStyle: AvatarStyle = .RoundedRectangle(size: CGSize(width: avatarSize, height: avatarSize), cornerRadius: avatarSize * 0.5, borderWidth: 0)
            let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: avatarStyle)
            avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
            
            completion()
        }
    }

    @IBAction private func changeAvatar(sender: UITapGestureRecognizer) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let choosePhotoAction: UIAlertAction = UIAlertAction(title: String.trans_titleChoosePhoto, style: .Default) { _ in

            let openCameraRoll: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else {
                    self?.alertCanNotAccessCameraRoll()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .PhotoLibrary
                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Photos, agreed: openCameraRoll, rejected: { [weak self] in
                self?.alertCanNotAccessCameraRoll()
            })
        }
        alertController.addAction(choosePhotoAction)

        let takePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .Default) { _ in

            let openCamera: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.Camera) else {
                    self?.alertCanNotOpenCamera()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .Camera
                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Camera, agreed: openCamera, rejected: { [weak self] in
                self?.alertCanNotOpenCamera()
            })
        }
        alertController.addAction(takePhotoAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .Cancel) { [weak self] _ in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)

        self.presentViewController(alertController, animated: true, completion: nil)

        // touch to create (if need) for faster appear
        delay(0.2) { [weak self] in
            self?.imagePicker.hidesBarsOnTap = false
        }
    }

    @objc private func tapMobileContainer(sender: UITapGestureRecognizer) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let changeMobileAction: UIAlertAction = UIAlertAction(title: String.trans_titleChangeMobile, style: .Default) { [weak self] action in

            self?.performSegueWithIdentifier("showChangeMobile", sender: nil)
        }
        alertController.addAction(changeMobileAction)

//        let uploadContactsAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Upload Contacts", comment: ""), style: .Default) { [weak self] action in
//
//            let propose: Propose = {
//                proposeToAccess(.Contacts, agreed: { [weak self] in
//                    self?.uploadContacts()
//
//                }, rejected: { [weak self] in
//                    self?.alertCanNotAccessContacts()
//                })
//            }
//
//            self?.showProposeMessageIfNeedForContactsAndTryPropose(propose)
//        }
//        alertController.addAction(uploadContactsAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .Cancel) { [weak self] _ in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)

        self.presentViewController(alertController, animated: true, completion: nil)
    }

    @objc private func save(sender: UIBarButtonItem) {

        view.endEditing(true)

        doInNextRunLoop { [weak self] in
            self?.isDirty = false
        }
    }
}

extension EditProfileViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int {
        case Info
        case LogOut
    }

    private enum InfoRow: Int {
        case Username
        case Nickname
        case Intro
        case Blog
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .Info:
            return 4

        case .LogOut:
            return 1
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Info:

            guard let infoRow = InfoRow(rawValue: indexPath.row) else {
                fatalError()
            }

            switch infoRow {

            case .Username:

                let cell: EditProfileLessInfoCell = tableView.dequeueReusableCell()

                cell.annotationLabel.text = NSLocalizedString("Username", comment: "")

                let username = me()?.username ?? ""

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

            case .Nickname:

                let cell: EditProfileLessInfoCell = tableView.dequeueReusableCell()

                cell.annotationLabel.text = NSLocalizedString("Nickname", comment: "")
                cell.accessoryImageView.hidden = false
                cell.selectionStyle = .Default

                YepUserDefaults.nickname.bindAndFireListener(Listener.Nickname) { [weak cell] nickname in
                    SafeDispatch.async {
                        cell?.infoLabel.text = nickname
                    }
                }

                YepUserDefaults.badge.bindAndFireListener(Listener.Badge) { [weak cell] badgeName in
                    SafeDispatch.async {
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

            case .Intro:
                let cell: EditProfileMoreInfoCell = tableView.dequeueReusableCell()

                cell.annotationLabel.text = NSLocalizedString("Introduction", comment: "")

                YepUserDefaults.introduction.bindAndFireListener(Listener.Introduction) { [weak cell] introduction in
                    SafeDispatch.async {
                        cell?.infoTextView.text = introduction ?? NSLocalizedString("Introduce yourself here.", comment: "")
                    }
                }

                cell.infoTextViewBeginEditingAction = { infoTextView in
                    // 初次设置前，清空 placeholder
                    if YepUserDefaults.introduction.value == nil {
                        infoTextView.text = ""
                    }
                }

                cell.infoTextViewIsDirtyAction = { [weak self] in
                    self?.isDirty = true
                }

                cell.infoTextViewDidEndEditingAction = { [weak self] newIntroduction in

                    guard !(self?.giveUpEditing ?? true) else {
                        return
                    }

                    self?.doneButton.enabled = false

                    if let oldIntroduction = YepUserDefaults.introduction.value {
                        if oldIntroduction == newIntroduction {
                            return
                        }
                    }

                    guard self?.isDirty ?? false else {
                        return
                    }

                    if newIntroduction.isEmpty {

                        YepHUD.showActivityIndicator()

                        updateMyselfWithInfo(["introduction": ""], failureHandler: { (reason, errorMessage) in
                            YepHUD.hideActivityIndicator()

                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        }, completion: { success in
                            YepHUD.hideActivityIndicator()

                            SafeDispatch.async {
                                YepUserDefaults.introduction.value = nil
                            }
                        })

                        return
                    }

                    YepHUD.showActivityIndicator()

                    updateMyselfWithInfo(["introduction": newIntroduction], failureHandler: { (reason, errorMessage) in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        YepHUD.hideActivityIndicator()

                    }, completion: { success in
                        SafeDispatch.async {
                            YepUserDefaults.introduction.value = newIntroduction
                        }

                        YepHUD.hideActivityIndicator()
                    })
                }

                return cell

            case .Blog:
                let cell: EditProfileMoreInfoCell = tableView.dequeueReusableCell()

                cell.annotationLabel.text = "Blog"

                YepUserDefaults.blogURLString.bindAndFireListener(Listener.Blog) { [weak cell] blogURLString in
                    SafeDispatch.async {
                        cell?.infoTextView.text = blogURLString ?? NSLocalizedString("Set blog URL here.", comment: "")
                    }
                }

                cell.infoTextViewBeginEditingAction = { infoTextView in
                    // 初次设置前，清空 placeholder
                    if YepUserDefaults.blogURLString.value == nil {
                        infoTextView.text = ""
                    }
                }

                cell.infoTextViewIsDirtyAction = { [weak self] in
                    self?.isDirty = true
                }

                cell.infoTextViewDidEndEditingAction = { [weak self] newBlogURLString in

                    guard !(self?.giveUpEditing ?? true) else {
                        return
                    }

                    self?.doneButton.enabled = false

                    if let oldBlogURLString = YepUserDefaults.blogURLString.value {
                        if oldBlogURLString == newBlogURLString {
                            return
                        }
                    }

                    guard self?.isDirty ?? false else {
                        return
                    }

                    if newBlogURLString.isEmpty {

                        YepHUD.showActivityIndicator()

                        let info: JSONDictionary = [
                            "website_url": "",
                            "website_title": "",
                        ]

                        updateMyselfWithInfo(info, failureHandler: { (reason, errorMessage) in
                            YepHUD.hideActivityIndicator()

                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        }, completion: { success in
                            YepHUD.hideActivityIndicator()

                            SafeDispatch.async {
                                YepUserDefaults.blogTitle.value = nil
                                YepUserDefaults.blogURLString.value = nil
                            }
                        })

                        return
                    }

                    guard let blogURL = NSURL(string: newBlogURLString)?.yep_validSchemeNetworkURL else {
                        YepUserDefaults.blogTitle.value = nil
                        YepUserDefaults.blogURLString.value = nil

                        YepAlert.alertSorry(message: NSLocalizedString("You have entered an invalid URL!", comment: ""), inViewController: self)

                        return
                    }

                    YepHUD.showActivityIndicator()

                    titleOfURL(blogURL, failureHandler: { [weak self] reason, errorMessage in

                        YepHUD.hideActivityIndicator()

                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        YepAlert.alert(title: NSLocalizedString("Ooops!", comment: ""), message: NSLocalizedString("You have entered an invalid URL!", comment: ""), dismissTitle: NSLocalizedString("Modify", comment: ""), inViewController: self, withDismissAction: { [weak cell] in

                            cell?.infoTextView.becomeFirstResponder()
                        })

                    }, completion: { blogTitle in

                        println("blogTitle: \(blogTitle)")

                        let info: JSONDictionary = [
                            "website_url": newBlogURLString,
                            "website_title": blogTitle,
                        ]

                        updateMyselfWithInfo(info, failureHandler: { (reason, errorMessage) in
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                            YepHUD.hideActivityIndicator()

                        }, completion: { success in
                            SafeDispatch.async {
                                YepUserDefaults.blogTitle.value = blogTitle
                                YepUserDefaults.blogURLString.value = newBlogURLString
                            }
                            
                            YepHUD.hideActivityIndicator()
                        })
                    })
                }

                return cell
            }

        case .LogOut:
            let cell: EditProfileColoredTitleCell = tableView.dequeueReusableCell()
            cell.coloredTitleLabel.text = NSLocalizedString("Log out", comment: "")
            cell.coloredTitleColor = UIColor.redColor()
            return cell
        }
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Info:

            guard let infoRow = InfoRow(rawValue: indexPath.row) else {
                fatalError()
            }

            switch infoRow {

            case .Username:
                return 60

            case .Nickname:
                return 60

            case .Intro:
                return heightOfCellForMoreInfo(introduction)

            case .Blog:
                return heightOfCellForMoreInfo(blogURLString)
            }

        case .LogOut:
            return 60
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Info:

            guard let infoRow = InfoRow(rawValue: indexPath.row) else {
                fatalError()
            }

            switch infoRow {

            case .Username:

                let username = me()?.username ?? ""

                guard username.isEmpty else {
                    break
                }
                
                YepAlert.textInput(title: NSLocalizedString("Set Username", comment: ""), message: NSLocalizedString("Please note that you can only set username once.", comment: ""), placeholder: NSLocalizedString("use letters, numbers, and underscore", comment: ""), oldText: nil, confirmTitle: NSLocalizedString("Set", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { text in

                    let newUsername = text

                    updateMyselfWithInfo(["username": newUsername], failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set username failed!", comment: ""), inViewController: self)

                    }, completion: { success in
                        SafeDispatch.async { [weak tableView] in
                            guard let realm = try? Realm() else {
                                return
                            }

                            if let me = meInRealm(realm) {
                                let _ = try? realm.write {
                                    me.username = newUsername
                                }
                            }

                            // update UI

                            if let usernameCell = tableView?.cellForRowAtIndexPath(indexPath) as? EditProfileLessInfoCell {
                                usernameCell.infoLabel.text = newUsername
                            }

                            NSNotificationCenter.defaultCenter().postNotificationName(Notification.NewUsername, object: nil)
                        }
                    })
                    
                }, cancelAction: {
                })

            case .Nickname:
                performSegueWithIdentifier("showEditNicknameAndBadge", sender: nil)

            default:
                break
            }

        case .LogOut:

            YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("Do you want to logout?", comment: ""), confirmTitle: NSLocalizedString("Yes", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { () -> Void in

                logout(failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)
                    YepAlert.alertSorry(message: "Logout failed!", inViewController: self)

                }, completion: {
                    SafeDispatch.async {

                        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
                            return
                        }

                        appDelegate.unregisterThirdPartyPush()

                        YepUserDefaults.cleanAllUserDefaults()

                        cleanRealmAndCaches()

                        appDelegate.startShowStory()
                    }
                })

            }, cancelAction: { () -> Void in
            })
        }
    }
}

// MARK: UIImagePicker

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {

        defer {
            dismissViewControllerAnimated(true, completion: nil)
        }

        activityIndicator.startAnimating()

        let image = image.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())
        let imageData = UIImageJPEGRepresentation(image, Config.avatarCompressionQuality())

        if let imageData = imageData {

            updateAvatarWithImageData(imageData, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                SafeDispatch.async { [weak self] in
                    self?.activityIndicator.stopAnimating()
                }
                
            }, completion: { newAvatarURLString in
                SafeDispatch.async {

                    YepUserDefaults.avatarURLString.value = newAvatarURLString

                    println("newAvatarURLString: \(newAvatarURLString)")

                    self.updateAvatar() {
                        SafeDispatch.async { [weak self] in
                            self?.activityIndicator.stopAnimating()
                        }
                    }
                }
            })
        }
    }
}

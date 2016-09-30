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

    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet fileprivate weak var mobileContainerView: UIStackView! {
        didSet {
            let tap = UITapGestureRecognizer(target: self, action: #selector(EditProfileViewController.tapMobileContainer(_:)))
            mobileContainerView.addGestureRecognizer(tap)
        }
    }
    @IBOutlet fileprivate weak var mobileLabel: UILabel! {
        didSet {
            mobileLabel.textColor = UIColor.yepTintColor()
        }
    }

    @IBOutlet fileprivate weak var editProfileTableView: TPKeyboardAvoidingTableView! {
        didSet {
            editProfileTableView.registerNibOf(EditProfileLessInfoCell.self)
            editProfileTableView.registerNibOf(EditProfileMoreInfoCell.self)
            editProfileTableView.registerNibOf(EditProfileColoredTitleCell.self)
        }
    }

    fileprivate lazy var imagePicker: UIImagePickerController = {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        return imagePicker
    }()

    fileprivate lazy var doneButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(EditProfileViewController.save(_:)))
        return button
    }()
    fileprivate var giveUpEditing: Bool = false
    fileprivate var isDirty: Bool = false {
        didSet {
            navigationItem.rightBarButtonItem = doneButton
            doneButton.isEnabled = isDirty
        }
    }

    fileprivate var introduction: String {
        return YepUserDefaults.introduction.value ?? String.trans_promptNoSelfIntroduction
    }

    fileprivate var blogURLString: String {
        return YepUserDefaults.blogURLString.value ?? NSLocalizedString("Set blog URL here.", comment: "")
    }

    fileprivate let infoAttributes = [NSFontAttributeName: YepConfig.EditProfile.infoFont]

    fileprivate func heightOfCellForMoreInfo(_ info: String) -> CGFloat {

        let tableViewWidth: CGFloat = editProfileTableView.bounds.width
        let introLabelMaxWidth: CGFloat = tableViewWidth - YepConfig.EditProfile.infoInset

        let rect: CGRect = info.boundingRect(with: CGSize(width: introLabelMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: infoAttributes, context: nil)

        let height: CGFloat = 20 + 22 + 10 + ceil(rect.height) + 20

        return max(height, 120)
    }

    fileprivate struct Listener {
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

        title = String.trans_titleEditProfile

        let avatarSize = YepConfig.editProfileAvatarSize()
        avatarImageViewWidthConstraint.constant = avatarSize

        updateAvatar() {}

        YepUserDefaults.mobile.bindAndFireListener(Listener.Mobile) { [weak self] _ in
            self?.mobileLabel.text = YepUserDefaults.fullPhoneNumber
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        giveUpEditing = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        giveUpEditing = true

        view.endEditing(true)
    }

    // MARK: Unwind

    @IBAction func unwindToEditProfile(_ segue: UIStoryboardSegue) {
    }

    // MARK: Actions

    fileprivate func uploadContacts() {

        let uploadContacts = UploadContactsMaker.make()

        YepHUD.showActivityIndicator()

        println("uploadContacts.count: \(uploadContacts.count)")

        friendsInContacts(uploadContacts, failureHandler: { (reason, errorMessage) in
            YepHUD.hideActivityIndicator()

            defaultFailureHandler(reason, errorMessage)

        }, completion: { [weak self] discoveredUsers in
            YepHUD.hideActivityIndicator()
            println("friendsInContacts discoveredUsers.count: \(discoveredUsers.count)")

            YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("Yep will match friends from your contacts for you.", comment: ""), dismissTitle: String.trans_titleOK, inViewController: self, withDismissAction: nil)
        })
    }

    fileprivate func updateAvatar(_ completion:() -> Void) {
        if let avatarURLString = YepUserDefaults.avatarURLString.value {

            println("avatarURLString: \(avatarURLString)")

            let avatarSize = YepConfig.editProfileAvatarSize()
            let avatarStyle: AvatarStyle = .roundedRectangle(size: CGSize(width: avatarSize, height: avatarSize), cornerRadius: avatarSize * 0.5, borderWidth: 0)
            let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: avatarStyle)
            avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
            
            completion()
        }
    }

    @IBAction fileprivate func changeAvatar(_ sender: UITapGestureRecognizer) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let choosePhotoAction: UIAlertAction = UIAlertAction(title: String.trans_titleChoosePhoto, style: .default) { _ in

            let openCameraRoll: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                    self?.alertCanNotAccessCameraRoll()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .photoLibrary
                    strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.photos, agreed: openCameraRoll, rejected: { [weak self] in
                self?.alertCanNotAccessCameraRoll()
            })
        }
        alertController.addAction(choosePhotoAction)

        let takePhotoAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Take Photo", comment: ""), style: .default) { _ in

            let openCamera: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    self?.alertCanNotOpenCamera()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .camera
                    strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.camera, agreed: openCamera, rejected: { [weak self] in
                self?.alertCanNotOpenCamera()
            })
        }
        alertController.addAction(takePhotoAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)

        // touch to create (if need) for faster appear
        _ = delay(0.2) { [weak self] in
            self?.imagePicker.hidesBarsOnTap = false
        }
    }

    @objc fileprivate func tapMobileContainer(_ sender: UITapGestureRecognizer) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let changeMobileAction: UIAlertAction = UIAlertAction(title: String.trans_titleChangeMobile, style: .default) { [weak self] action in

            self?.performSegue(withIdentifier: "showChangeMobile", sender: nil)
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

        let cancelAction: UIAlertAction = UIAlertAction(title: String.trans_cancel, style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }

    @objc fileprivate func save(_ sender: UIBarButtonItem) {

        view.endEditing(true)

        doInNextRunLoop { [weak self] in
            self?.isDirty = false
        }
    }
}

extension EditProfileViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {
        case info
        case logOut
    }

    fileprivate enum InfoRow: Int {
        case username
        case nickname
        case intro
        case blog
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .info:
            return 4

        case .logOut:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .info:

            guard let infoRow = InfoRow(rawValue: indexPath.row) else {
                fatalError()
            }

            switch infoRow {

            case .username:

                let cell: EditProfileLessInfoCell = tableView.dequeueReusableCell()

                cell.annotationLabel.text = NSLocalizedString("Username", comment: "")

                let username = me()?.username ?? ""

                if username.isEmpty {
                    cell.infoLabel.text = String.trans_promptNone
                    cell.accessoryImageView.isHidden = false
                    cell.selectionStyle = .default
                } else {
                    cell.infoLabel.text = username
                    cell.accessoryImageView.isHidden = true
                    cell.selectionStyle = .none
                }

                cell.badgeImageView.image = nil
                cell.infoLabelTrailingConstraint.constant = EditProfileLessInfoCell.ConstraintConstant.minInfoLabelTrailing

                return cell

            case .nickname:

                let cell: EditProfileLessInfoCell = tableView.dequeueReusableCell()

                cell.annotationLabel.text = String.trans_titleNickname
                cell.accessoryImageView.isHidden = false
                cell.selectionStyle = .default

                YepUserDefaults.nickname.bindAndFireListener(Listener.Nickname) { [weak cell] nickname in
                    SafeDispatch.async {
                        cell?.infoLabel.text = nickname
                    }
                }

                YepUserDefaults.badge.bindAndFireListener(Listener.Badge) { [weak cell] badgeName in
                    SafeDispatch.async {
                        if let badgeName = badgeName, let badge = BadgeView.Badge(rawValue: badgeName) {
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

            case .intro:
                let cell: EditProfileMoreInfoCell = tableView.dequeueReusableCell()

                cell.annotationLabel.text = String.trans_titleSelfIntroduction

                YepUserDefaults.introduction.bindAndFireListener(Listener.Introduction) { [weak cell] introduction in
                    SafeDispatch.async {
                        cell?.infoTextView.text = introduction ?? String.trans_promptUserIntroPlaceholder
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

                    self?.doneButton.isEnabled = false

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

                            defaultFailureHandler(reason, errorMessage)

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
                        defaultFailureHandler(reason, errorMessage)

                        YepHUD.hideActivityIndicator()

                    }, completion: { success in
                        SafeDispatch.async {
                            YepUserDefaults.introduction.value = newIntroduction
                        }

                        YepHUD.hideActivityIndicator()
                    })
                }

                return cell

            case .blog:
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

                    self?.doneButton.isEnabled = false

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

                            defaultFailureHandler(reason, errorMessage)

                        }, completion: { success in
                            YepHUD.hideActivityIndicator()

                            SafeDispatch.async {
                                YepUserDefaults.blogTitle.value = nil
                                YepUserDefaults.blogURLString.value = nil
                            }
                        })

                        return
                    }

                    guard let blogURL = URL(string: newBlogURLString)?.yep_validSchemeNetworkURL else {
                        YepUserDefaults.blogTitle.value = nil
                        YepUserDefaults.blogURLString.value = nil

                        YepAlert.alertSorry(message: NSLocalizedString("You have entered an invalid URL!", comment: ""), inViewController: self)

                        return
                    }

                    YepHUD.showActivityIndicator()

                    titleOfURL(blogURL, failureHandler: { [weak self] reason, errorMessage in

                        YepHUD.hideActivityIndicator()

                        defaultFailureHandler(reason, errorMessage)

                        YepAlert.alert(title: NSLocalizedString("Ooops!", comment: ""), message: NSLocalizedString("You have entered an invalid URL!", comment: ""), dismissTitle: String.trans_titleModify, inViewController: self, withDismissAction: { [weak cell] in

                            cell?.infoTextView.becomeFirstResponder()
                        })

                    }, completion: { blogTitle in

                        println("blogTitle: \(blogTitle)")

                        let info: JSONDictionary = [
                            "website_url": newBlogURLString,
                            "website_title": blogTitle,
                        ]

                        updateMyselfWithInfo(info, failureHandler: { (reason, errorMessage) in
                            defaultFailureHandler(reason, errorMessage)

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

        case .logOut:
            let cell: EditProfileColoredTitleCell = tableView.dequeueReusableCell()
            cell.coloredTitleLabel.text = String.trans_titleLogOut
            cell.coloredTitleColor = UIColor.red
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .info:

            guard let infoRow = InfoRow(rawValue: indexPath.row) else {
                fatalError()
            }

            switch infoRow {

            case .username:
                return 60

            case .nickname:
                return 60

            case .intro:
                return heightOfCellForMoreInfo(introduction)

            case .blog:
                return heightOfCellForMoreInfo(blogURLString)
            }

        case .logOut:
            return 60
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .info:

            guard let infoRow = InfoRow(rawValue: indexPath.row) else {
                fatalError()
            }

            switch infoRow {

            case .username:

                let username = me()?.username ?? ""

                guard username.isEmpty else {
                    break
                }
                
                YepAlert.textInput(title: NSLocalizedString("Set Username", comment: ""), message: NSLocalizedString("Please note that you can only set username once.", comment: ""), placeholder: NSLocalizedString("use letters, numbers, and underscore", comment: ""), oldText: nil, confirmTitle: NSLocalizedString("Set", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { text in

                    let newUsername = text

                    updateMyselfWithInfo(["username": newUsername], failureHandler: { [weak self] reason, errorMessage in
                        defaultFailureHandler(reason, errorMessage)

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

                            if let usernameCell = tableView?.cellForRow(at: indexPath) as? EditProfileLessInfoCell {
                                usernameCell.infoLabel.text = newUsername
                            }

                            NotificationCenter.default.post(name: YepConfig.NotificationName.newUsername, object: nil)
                        }
                    })
                    
                }, cancelAction: {
                })

            case .nickname:
                performSegue(withIdentifier: "showEditNicknameAndBadge", sender: nil)

            default:
                break
            }

        case .logOut:

            YepAlert.confirmOrCancel(title: String.trans_titleNotice, message: String.trans_promptTryLogout, confirmTitle: NSLocalizedString("Yes", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { () -> Void in

                logout(failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason, errorMessage)
                    YepAlert.alertSorry(message: "Logout failed!", inViewController: self)

                }, completion: {
                    SafeDispatch.async {

                        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage!, editingInfo: [AnyHashable: Any]!) {

        defer {
            dismiss(animated: true, completion: nil)
        }

        activityIndicator.startAnimating()

        let image = image.largestCenteredSquareImage().resizeToTargetSize(YepConfig.avatarMaxSize())
        let imageData = UIImageJPEGRepresentation(image, Config.avatarCompressionQuality)

        if let imageData = imageData {

            updateAvatarWithImageData(imageData, failureHandler: { (reason, errorMessage) in

                defaultFailureHandler(reason, errorMessage)

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

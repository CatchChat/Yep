//
//  ProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import SafariServices
import CoreLocation
import RealmSwift
import YepNetworking
import YepKit
import OpenGraph
import MonkeyKing
import Navi
import Kingfisher
import Proposer

let profileAvatarAspectRatio: CGFloat = 12.0 / 16.0

final class ProfileViewController: SegueViewController, CanScrollsToTop {

    var oAuthCompleteAction: (() -> Void)?
    var afterOAuthAction: ((_ socialAccount: SocialAccount) -> Void)?

    var profileUser: ProfileUser?

    enum FromType {
        case none
        case oneToOneConversation
        case groupConversation
    }
    var fromType: FromType = .none

    fileprivate var profileUserIsMe = true {
        didSet {
            if !profileUserIsMe {

                if fromType == .oneToOneConversation {
                    sayHiView.isHidden = true

                } else {
                    sayHiView.tapAction = { [weak self] in
                        self?.sayHi()
                    }

                    profileCollectionView.contentInset.bottom = sayHiView.bounds.height
                }

            } else {
                sayHiView.isHidden = true

                let settingsBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconSettings, style: .plain, target: self, action: #selector(ProfileViewController.showSettings(_:)))

                customNavigationItem.rightBarButtonItem = settingsBarButtonItem

                NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.createdFeed(_:)), name: Config.NotificationName.createdFeed, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.deletedFeed(_:)), name: YepConfig.NotificationName.deletedFeed, object: nil)
            }
        }
    }

    fileprivate var socialAccount: SocialAccount?

    fileprivate var numberOfItemsInSectionBlog: Int {

        if profileUserIsMe {
            return 1
        } else {
            if let _ = profileUser?.blogURL {
                return 1
            } else {
                return 0
            }
        }
    }

    fileprivate var numberOfItemsInSectionSocialAccount: Int {

        return (profileUser?.providersCount ?? 0)
    }

    fileprivate var needSeparationLine: Bool {

        return (numberOfItemsInSectionBlog > 0) || (numberOfItemsInSectionSocialAccount > 0)
    }

    fileprivate var insetForSectionBlog: UIEdgeInsets {

        if numberOfItemsInSectionBlog > 0 {
            if numberOfItemsInSectionSocialAccount > 0 {
                return UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
            } else {
                return UIEdgeInsets(top: 30, left: 0, bottom: 40, right: 0)
            }
        } else {
            return UIEdgeInsets.zero
        }
    }

    fileprivate var insetForSectionSocialAccount: UIEdgeInsets {

        if numberOfItemsInSectionBlog > 0 {
            if numberOfItemsInSectionSocialAccount > 0 {
                return UIEdgeInsets(top: 10, left: 0, bottom: 30, right: 0)
            } else {
                return UIEdgeInsets.zero
            }
        } else {
            if numberOfItemsInSectionSocialAccount > 0 {
                return UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
            } else {
                return UIEdgeInsets.zero
            }
        }
    }

    fileprivate lazy var shareView: ShareProfileView = {
        let share = ShareProfileView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        share.alpha = 0
        self.view.addSubview(share)
        return share
    }()

    #if DEBUG
    private lazy var profileFPSLabel: FPSLabel = {
        let label = FPSLabel()
        return label
    }()
    #endif

    fileprivate var statusBarShouldLight = false

    fileprivate var noNeedToChangeStatusBar = false

    @IBOutlet fileprivate weak var topShadowImageView: UIImageView!

    @IBOutlet fileprivate weak var profileCollectionView: UICollectionView! {
        didSet {
            profileCollectionView.registerNibOf(SkillCell.self)
            profileCollectionView.registerNibOf(ProfileHeaderCell.self)
            profileCollectionView.registerNibOf(ProfileFooterCell.self)
            profileCollectionView.registerNibOf(ProfileSeparationLineCell.self)
            profileCollectionView.registerNibOf(ProfileSocialAccountCell.self)
            profileCollectionView.registerNibOf(ProfileSocialAccountBlogCell.self)
            profileCollectionView.registerNibOf(ProfileSocialAccountImagesCell.self)
            profileCollectionView.registerNibOf(ProfileSocialAccountGithubCell.self)
            profileCollectionView.registerNibOf(ProfileFeedsCell.self)

            profileCollectionView.registerHeaderNibOf(ProfileSectionHeaderReusableView.self)
            profileCollectionView.registerFooterClassOf(UICollectionReusableView.self)

            profileCollectionView.alwaysBounceVertical = true
        }
    }

    // CanScrollsToTop
    var scrollView: UIScrollView? {
        return profileCollectionView
    }

    @IBOutlet fileprivate weak var sayHiView: BottomButtonView!

    fileprivate lazy var customNavigationItem: UINavigationItem = UINavigationItem(title: "Details")
    fileprivate lazy var customNavigationBar: UINavigationBar = {

        let bar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 64))

        bar.tintColor = UIColor.white
        bar.tintAdjustmentMode = .normal
        bar.alpha = 0
        bar.setItems([self.customNavigationItem], animated: false)

        bar.backgroundColor = UIColor.clear
        bar.isTranslucent = true
        bar.shadowImage = UIImage()
        bar.barStyle = UIBarStyle.blackTranslucent
        bar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]

        bar.titleTextAttributes = textAttributes
        
        return bar
    }()

    fileprivate lazy var collectionViewWidth: CGFloat = {
        return self.profileCollectionView.bounds.width
    }()
    fileprivate lazy var sectionLeftEdgeInset: CGFloat = {
        return YepConfig.Profile.leftEdgeInset
    }()
    fileprivate lazy var sectionRightEdgeInset: CGFloat = {
        return YepConfig.Profile.rightEdgeInset
    }()
    fileprivate lazy var sectionBottomEdgeInset: CGFloat = {
        return 0
    }()

    fileprivate lazy var introductionText: String = {

        let introduction: String? = self.profileUser.flatMap({ profileUser in

            switch profileUser {
                
            case .discoveredUserType(let discoveredUser):
                if let introduction = discoveredUser.introduction , !introduction.isEmpty {
                    return introduction
                }

            case .userType(let user):
                if user.isMe {
                    YepUserDefaults.introduction.bindListener(self.listener.introduction) { introduction in
                        SafeDispatch.async { [weak self] in
                            self?.introductionText = introduction ?? String.trans_promptNoSelfIntroduction
                            self?.updateProfileCollectionView()
                        }
                    }
                }

                if !user.introduction.isEmpty {
                    return user.introduction
                }
            }

            return nil
        })

        return introduction ?? String.trans_promptNoSelfIntroduction
    }()

    fileprivate var masterSkills = [Skill]()

    fileprivate var learningSkills = [Skill]()

    fileprivate func updateMyMasterSkills() {

        guard let profileUser = profileUser , profileUser.isMe else {
            return
        }

        guard let realm = try? Realm() else {
            return
        }

        if let me = meInRealm(realm) {
            realm.beginWrite()
            me.masterSkills.removeAll()
            let userSkills = userSkillsFromSkills(masterSkills, inRealm: realm)
            me.masterSkills.append(objectsIn: userSkills)
            _ = try? realm.commitWrite()
        }
    }

    fileprivate func updateMyLearningSkills() {

        guard let profileUser = profileUser , profileUser.isMe else {
            return
        }

        guard let realm = try? Realm() else {
            return
        }

        if let me = meInRealm(realm) {
            realm.beginWrite()
            me.learningSkills.removeAll()
            let userSkills = userSkillsFromSkills(learningSkills, inRealm: realm)
            me.learningSkills.append(objectsIn: userSkills)
            _ = try? realm.commitWrite()
        }
    }

    fileprivate var dribbbleWork: DribbbleWork?
    fileprivate var instagramWork: InstagramWork?
    fileprivate var githubWork: GithubWork?
    fileprivate var feeds: [DiscoveredFeed]?
    fileprivate var feedAttachments: [DiscoveredAttachment?]?

    fileprivate let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextFont()]

    fileprivate var footerCellHeight: CGFloat {
        let attributes = [
            NSFontAttributeName: YepConfig.Profile.introductionFont
        ]
        let labelWidth = self.collectionViewWidth - (YepConfig.Profile.leftEdgeInset + YepConfig.Profile.rightEdgeInset)
        let rect = self.introductionText.boundingRect(with: CGSize(width: labelWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes:attributes, context:nil)
        return 10 + 24 + 4 + 18 + 10 + ceil(rect.height) + 6
    }

    fileprivate struct Listener {
        let nickname: String
        let introduction: String
        let avatar: String
        let blog: String
    }

    fileprivate lazy var listener: Listener = {

        let suffix = UUID().uuidString

        return Listener(
            nickname: "Profile.Title" + suffix,
            introduction: "Profile.introductionText" + suffix,
            avatar: "Profile.Avatar" + suffix,
            blog: "Profile.Blog" + suffix
        )
    }()

    // MARK: Life cycle

    deinit {
        NotificationCenter.default.removeObserver(self)

        YepUserDefaults.nickname.removeListenerWithName(listener.nickname)
        YepUserDefaults.introduction.removeListenerWithName(listener.introduction)
        YepUserDefaults.avatarURLString.removeListenerWithName(listener.avatar)
        YepUserDefaults.blogURLString.removeListenerWithName(listener.blog)

        profileCollectionView?.delegate = nil

        println("deinit Profile")
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        if statusBarShouldLight {
            return UIStatusBarStyle.lightContent
        } else {
            return UIStatusBarStyle.default
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString("Profile", comment: "")

        view.addSubview(customNavigationBar)

        automaticallyAdjustsScrollViewInsets = false

        Kingfisher.ImageCache.default.calculateDiskCacheSize { (size) in
            let cacheSize = Double(size)/1000000
            println(String(format: "Kingfisher.ImageCache cacheSize: %.2f MB", cacheSize))
            
            if cacheSize > 300 {
                 Kingfisher.ImageCache.default.cleanExpiredDiskCache()
            }
        }

        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.cleanForLogout(_:)), name: YepConfig.NotificationName.logout, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.handleOAuthResult(_:)), name: YepConfig.NotificationName.oauthResult, object: nil)

        if let profileUser = profileUser {

            // 如果是 DiscoveredUser，也可能是好友或已存储的陌生人，查询本地 User 替换

            switch profileUser {

            case .discoveredUserType(let discoveredUser):

                guard let realm = try? Realm() else {
                    break
                }

                if let user = userWithUserID(discoveredUser.id, inRealm: realm) {
                    
                    self.profileUser = ProfileUser.userType(user)

                    masterSkills = skillsFromUserSkillList(user.masterSkills)
                    learningSkills = skillsFromUserSkillList(user.learningSkills)

                    updateProfileCollectionView()
                }

            default:
                break
            }
            
            if let realm = try? Realm() {
                
                if let user = userWithUserID(profileUser.userID, inRealm: realm) {
                    
                    if user.friendState == UserFriendState.normal.rawValue {
                        sayHiView.title = String.trans_titleChat
                    }
                }
                
            }

        } else {

            // 为空的话就要显示自己
            syncMyInfoAndDoFurtherAction {

                // 提示没有 Skills
                guard let me = me() else {
                    return
                }

                if me.masterSkills.count == 0 && me.learningSkills.count == 0 {

                    YepAlert.confirmOrCancel(title: String.trans_titleNotice, message: NSLocalizedString("You don't have any skills!\nWould you like to pick some?", comment: ""), confirmTitle: String.trans_titleOK, cancelTitle: String.trans_titleNotNow, inViewController: self, withConfirmAction: { [weak self] in
                        self?.pickSkills()
                    }, cancelAction: {})
                }
            }

            if let me = me() {
                profileUser = ProfileUser.userType(me)

                masterSkills = skillsFromUserSkillList(me.masterSkills)
                learningSkills = skillsFromUserSkillList(me.learningSkills)

                updateProfileCollectionView()
            }
        }

        profileUserIsMe = profileUser?.isMe ?? false

        if let profileLayout = profileCollectionView.collectionViewLayout as? ProfileLayout {

            profileLayout.scrollUpAction = { [weak self] progress in

                if let strongSelf = self {
                    let indexPath = IndexPath(item: 0, section: Section.header.rawValue)
                    
                    if let coverCell = strongSelf.profileCollectionView.cellForItem(at: indexPath) as? ProfileHeaderCell {
                        
                        let beginChangePercentage: CGFloat = 1 - 64 / strongSelf.collectionViewWidth * profileAvatarAspectRatio
                        let normalizedProgressForChange: CGFloat = (progress - beginChangePercentage) / (1 - beginChangePercentage)
                        
                        coverCell.avatarBlurImageView.alpha = progress < beginChangePercentage ? 0 : normalizedProgressForChange

                        let shadowAlpha = 1 - normalizedProgressForChange
                        
                        if shadowAlpha < 0.2 {
                            strongSelf.topShadowImageView.alpha = progress < beginChangePercentage ? 1 : 0.2
                        } else {
                            strongSelf.topShadowImageView.alpha = progress < beginChangePercentage ? 1 : shadowAlpha
                        }
                        
                        coverCell.locationLabel.alpha = progress < 0.5 ? 1 : 1 - min(1, (progress - 0.5) * 2 * 2) // 特别对待，在后半程的前半段即完成 alpha -> 0
                    }
                }
            }
        }

        //Make sure when pan edge screen collectionview not scroll
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    profileCollectionView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        if let tabBarController = tabBarController {
            profileCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: tabBarController.tabBar.bounds.height, right: 0)
        }

        if let profileUser = profileUser {

            switch profileUser {

            case .discoveredUserType(let discoveredUser):
                customNavigationItem.title = discoveredUser.nickname

            case .userType(let user):
                customNavigationItem.title = user.nickname

                if user.friendState == UserFriendState.me.rawValue {
                    YepUserDefaults.nickname.bindListener(listener.nickname) { [weak self] nickname in
                        SafeDispatch.async {
                            self?.customNavigationItem.title = nickname
                            self?.updateProfileCollectionView()
                        }
                    }

                    YepUserDefaults.avatarURLString.bindListener(listener.avatar) { [weak self] avatarURLString in
                        SafeDispatch.async {
                            let indexPath = IndexPath(item: 0, section: Section.header.rawValue)
                            if let cell = self?.profileCollectionView.cellForItem(at: indexPath) as? ProfileHeaderCell {
                                if let avatarURLString = avatarURLString {
                                    cell.blurredAvatarImage = nil // need reblur
                                    cell.updateAvatarWithAvatarURLString(avatarURLString)
                                }
                            }
                        }
                    }

                    YepUserDefaults.blogURLString.bindListener(listener.blog, action: { [weak self] _ in
                        self?.updateProfileCollectionView()
                    })

                    NotificationCenter.default.addObserver(self, selector: #selector(ProfileViewController.updateUIForUsername(_:)), name: YepConfig.NotificationName.newUsername, object: nil)
                }
            }

            if !profileUserIsMe {

                let userID = profileUser.userID

                userInfoOfUserWithUserID(userID, failureHandler: nil, completion: { userInfo in
                    //println("userInfoOfUserWithUserID \(userInfo)")

                    // 对非好友来说，必要

                    SafeDispatch.async { [weak self] in

                        if let realm = try? Realm() {
                            let _ = try? realm.write {
                                updateUserWithUserID(userID, useUserInfo: userInfo, inRealm: realm)
                            }
                        }

                        if let discoveredUser = parseDiscoveredUser(userInfo) {
                            switch profileUser {
                            case .discoveredUserType:
                                self?.profileUser = ProfileUser.discoveredUserType(discoveredUser)
                            default:
                                break
                            }
                        }
                        
                        self?.updateProfileCollectionView()
                    }
                })
            }

            if profileUserIsMe {

                // share my profile button

                if customNavigationItem.leftBarButtonItem == nil {
                    let shareMyProfileButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(ProfileViewController.tryShareMyProfile(_:)))
                    customNavigationItem.leftBarButtonItem = shareMyProfileButton
                }

            } else {
                // share others' profile button

                if let _ = profileUser.username {
                    let shareOthersProfileButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(ProfileViewController.shareOthersProfile(_:)))
                    customNavigationItem.rightBarButtonItem = shareOthersProfileButton
                }
            }
        }

        if profileUserIsMe {

            proposeToAccess(.location(.whenInUse), agreed: {
                YepLocationService.turnOn()

                YepLocationService.sharedManager.afterUpdatedLocationAction = { [weak self] newLocation in

                    let indexPath = IndexPath(item: 0, section: Section.footer.rawValue)
                    if let cell = self?.profileCollectionView.cellForItem(at: indexPath) as? ProfileFooterCell {
                        cell.location = newLocation
                    }
                }

            }, rejected: {
                println("Yep can NOT get Location. :[\n")
            })
        }

        if profileUserIsMe {

            tryUpdateBlogTitle()

            remindUserToReview()
        }

        #if DEBUG
            //view.addSubview(profileFPSLabel)
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: true)
        customNavigationBar.alpha = 1.0

        statusBarShouldLight = false

        if noNeedToChangeStatusBar {
            statusBarShouldLight = true
        }

        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        statusBarShouldLight = true

        self.setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: Actions

    fileprivate func tryUpdateBlogTitle() {

        guard let blogURLString = YepUserDefaults.blogURLString.value , !blogURLString.isEmpty, let blogURL = URL(string: blogURLString)?.yep_validSchemeNetworkURL else {
            return
        }

        titleOfURL(blogURL, failureHandler: nil, completion: { blogTitle in

            println("blogTitle: \(blogTitle)")

            if YepUserDefaults.blogTitle.value != blogTitle {

                let info: JSONDictionary = [
                    "website_url": blogURLString,
                    "website_title": blogTitle,
                ]

                updateMyselfWithInfo(info, failureHandler: nil, completion: { success in

                    SafeDispatch.async {
                        YepUserDefaults.blogTitle.value = blogTitle
                        YepUserDefaults.blogURLString.value = blogURLString
                    }
                })

            } else {
                println("not need update blogTitle")
            }
        })
    }

    fileprivate func tryShareProfile() {

        guard let username = profileUser?.username, let profileURL = URL(string: "https://\(yepHost)/\(username)"), let nickname = profileUser?.nickname else {
            return
        }

        var thumbnail: UIImage?
        if let
            avatarURLString = profileUser?.avatarURLString,
            let realm = try? Realm(),
            let avatar = avatarWithAvatarURLString(avatarURLString, inRealm: realm) {
                if
                    let avatarFileURL = FileManager.yepAvatarURLWithName(avatar.avatarFileName),
                    let image = UIImage(contentsOfFile: avatarFileURL.path) {
                        thumbnail = image.navi_centerCropWithSize(CGSize(width: 100, height: 100))
                }
        }

        let info = MonkeyKing.Info(
            title: nickname,
            description: String.trans_shareFromYepWithSkills,
            thumbnail: thumbnail,
            media: .url(profileURL)
        )
        let description = String.trans_shareUserFromYepWithSkills(nickname)
        self.yep_share(info: info, defaultActivityItem: profileURL, description: description)
    }

    @objc fileprivate func tryShareMyProfile(_ sender: AnyObject?) {

        if let _ = profileUser?.username {
            tryShareProfile()

        } else {
            YepAlert.textInput(title: String.trans_titleCreateUsername, message: String.trans_promptCreateUsername, placeholder: NSLocalizedString("use letters, numbers, and underscore", comment: ""), oldText: nil, confirmTitle: String.trans_titleCreate, cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { text in

                let newUsername = text

                updateMyselfWithInfo(["username": newUsername], failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason, errorMessage)

                    let message = errorMessage ?? String.trans_promptCreateUsernameFailed
                    YepAlert.alertSorry(message: message, inViewController: self)

                }, completion: { success in
                    SafeDispatch.async { [weak self] in
                        guard let realm = try? Realm() else {
                            return
                        }
                        if let me = meInRealm(realm) {
                            let _ = try? realm.write {
                                me.username = newUsername
                            }
                        }

                        self?.tryShareProfile()
                    }
                })

            }, cancelAction: {
            })
        }
    }

    @objc fileprivate func shareOthersProfile(_ sender: AnyObject) {

        tryShareProfile()
    }

    fileprivate func pickSkills() {

        let vc = UIStoryboard.Scene.registerPickSkills

        vc.isRegister = false
        vc.masterSkills = self.masterSkills
        vc.learningSkills = self.learningSkills

        vc.afterChangeSkillsAction = { [weak self] masterSkills, learningSkills in
            self?.masterSkills = masterSkills
            self?.learningSkills = learningSkills

            SafeDispatch.async {
                self?.updateMyMasterSkills()
                self?.updateMyLearningSkills()

                self?.updateProfileCollectionView()
            }
        }

        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc fileprivate func showSettings(_ sender: AnyObject) {
        self.performSegue(withIdentifier: "showSettings", sender: self)
    }

    func setBackButtonWithTitle() {
        let backBarButtonItem = UIBarButtonItem(image: UIImage.yep_iconBack, style: .plain, target: self, action: #selector(ProfileViewController.back(_:)))

        customNavigationItem.leftBarButtonItem = backBarButtonItem
    }

    @objc fileprivate func back(_ sender: AnyObject) {
        if let presentingViewController = presentingViewController {
            presentingViewController.dismiss(animated: true, completion: nil)
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }

    @objc fileprivate func cleanForLogout(_ sender: Notification) {
        profileUser = nil
    }

    @objc fileprivate func updateUIForUsername(_ sender: Notification) {
        updateProfileCollectionView()
    }

    fileprivate func updateFeedAttachmentsAfterUpdateFeeds() {

        feedAttachments = feeds!.map({ feed -> DiscoveredAttachment? in
            if let attachment = feed.attachment {
                if case let .images(attachments) = attachment {
                    return attachments.first
                }
            }

            return nil
        })

        updateProfileCollectionView()
    }
    @objc fileprivate func createdFeed(_ sender: Notification) {

        guard feeds != nil else {
            return
        }

        let feed = (sender.object as! Box<DiscoveredFeed>).value
        feeds!.insert(feed, at: 0)

        updateFeedAttachmentsAfterUpdateFeeds()
    }

    @objc fileprivate func deletedFeed(_ sender: Notification) {

        guard feeds != nil else {
            return
        }

        let feedID = sender.object as! String
        var indexOfDeletedFeed: Int?
        for (index, feed) in feeds!.enumerated() {
            if feed.id == feedID {
                indexOfDeletedFeed = index
                break
            }
        }
        guard let index = indexOfDeletedFeed else {
            return
        }
        feeds!.remove(at: index)

        updateFeedAttachmentsAfterUpdateFeeds()
    }

    fileprivate func updateProfileCollectionView() {
        SafeDispatch.async { [weak self] in
            self?.profileCollectionView.collectionViewLayout.invalidateLayout()
            self?.profileCollectionView.reloadData()
            self?.profileCollectionView.layoutIfNeeded()
        }
    }

    fileprivate func sayHi() {

        if let profileUser = profileUser {
                    
            guard let realm = try? Realm() else {
                return
            }

            switch profileUser {

            case .discoveredUserType(let discoveredUser):

                realm.beginWrite()
                let conversation = conversationWithDiscoveredUser(discoveredUser, inRealm: realm)
                _ = try? realm.commitWrite()

                if let conversation = conversation {
                    performSegue(withIdentifier: "showConversation", sender: conversation)

                    NotificationCenter.default.post(name: Config.NotificationName.changedConversation, object: nil)
                }

            case .userType(let user):

                if user.friendState != UserFriendState.me.rawValue {

                    if user.conversation == nil {
                        let newConversation = Conversation()

                        newConversation.type = ConversationType.oneToOne.rawValue
                        newConversation.withFriend = user

                        let _ = try? realm.write {
                            realm.add(newConversation)
                        }
                    }

                    if let conversation = user.conversation {
                        performSegue(withIdentifier: "showConversation", sender: conversation)

                        NotificationCenter.default.post(name: Config.NotificationName.changedConversation, object: nil)
                    }
                }
            }
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfileWithUsername":

            let vc = segue.destination as! ProfileViewController

            let profileUser = (sender as! Box<ProfileUser>).value
            vc.prepare(withProfileUser: profileUser)

        case "showConversation":

            let vc = segue.destination as! ConversationViewController
            vc.conversation = sender as! Conversation
            
        case "showFeedsWithSkill":

            let vc = segue.destination as! FeedsViewController

            if let
                skillInfo = sender as? [String: AnyObject],
                let skill = skillInfo["skill"] as? SkillCellSkill {
                    vc.skill = Skill(category: nil, id: skill.ID, name: skill.localName, localName: skill.localName, coverURLString: skill.coverURLString)
            }

            vc.hidesBottomBarWhenPushed = true

        case "showFeedsOfProfileUser":

            let vc = segue.destination as! FeedsViewController

            if let
                info = (sender as? Box<[String: AnyObject]>)?.value,
                let profileUser = (info["profileUser"] as? Box<ProfileUser>)?.value,
                let feeds = (info["feeds"] as? Box<[DiscoveredFeed]>)?.value {
                    vc.profileUser = profileUser
                    vc.feeds = feeds
                    vc.preparedFeedsCount = feeds.count
            }
            
            vc.hideRightBarItem = true

            vc.hidesBottomBarWhenPushed = true

        case "showEditSkills":

            if let skillInfo = sender as? [String: AnyObject] {

                let vc = segue.destination as! EditSkillsViewController

                if let skillSet = skillInfo["skillSet"] as? Int {
                    vc.skillSet = SkillSet(rawValue: skillSet)
                }

                vc.afterChangedSkillsAction = { [weak self] in
                    self?.updateProfileCollectionView()
                }
            }

        case "showSocialWorkGithub":

            if let providerName = sender as? String {

                let vc = segue.destination as! SocialWorkGithubViewController
                vc.socialAccount = SocialAccount(rawValue: providerName)
                vc.profileUser = profileUser
                vc.githubWork = githubWork

                vc.afterGetGithubWork = {[weak self] githubWork in
                    self?.githubWork = githubWork
                }
            }

        case "showSocialWorkDribbble":

            if let providerName = sender as? String {

                let vc = segue.destination as! SocialWorkDribbbleViewController
                vc.socialAccount = SocialAccount(rawValue: providerName)
                vc.profileUser = profileUser
                vc.dribbbleWork = dribbbleWork

                vc.afterGetDribbbleWork = { [weak self] dribbbleWork in
                    self?.dribbbleWork = dribbbleWork
                }
            }

        case "showSocialWorkInstagram":

            if let providerName = sender as? String {

                let vc = segue.destination as! SocialWorkInstagramViewController
                vc.socialAccount = SocialAccount(rawValue: providerName)
                vc.profileUser = profileUser
                vc.instagramWork = instagramWork

                vc.afterGetInstagramWork = { [weak self] instagramWork in
                    self?.instagramWork = instagramWork
                }
            }

        default:
            break
        }
    }
}

// MARK: UICollectionView

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate {
    
    enum Section: Int {
        case header
        case footer
        case master
        case learning
        case separationLine
        case blog
        case socialAccount
        case separationLine2
        case feeds
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 9
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .header:
            return 1

        case .master:
            return profileUser?.masterSkillsCount ?? 0

        case .learning:
            return profileUser?.learningSkillsCount ?? 0

        case .footer:
            return 1

        case .separationLine:
            return needSeparationLine ? 1 : 0

        case .blog:
            return numberOfItemsInSectionBlog

        case .socialAccount:
            return numberOfItemsInSectionSocialAccount

        case .separationLine2:
            return 1

        case .feeds:
            return 1
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError()
        }

        switch section {

        case .header:
            let cell: ProfileHeaderCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            if let profileUser = profileUser {
                switch profileUser {
                case .discoveredUserType(let discoveredUser):
                    cell.configureWithDiscoveredUser(discoveredUser)
                case .userType(let user):
                    cell.configureWithUser(user)
                }
            }

            cell.updatePrettyColorAction = { [weak self] prettyColor in
                self?.customNavigationBar.tintColor = prettyColor

                let textAttributes = [
                    NSForegroundColorAttributeName: prettyColor,
                    NSFontAttributeName: UIFont.navigationBarTitleFont()
                ]
                self?.customNavigationBar.titleTextAttributes = textAttributes
            }

            return cell

        case .master:
            let cell: SkillCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            cell.skill = profileUser?.cellSkillInSkillSet(.master, atIndexPath: indexPath)

            if cell.skill == nil {
                if let profileUser = profileUser {
                    println("Master profileUser: \(profileUser)")
                } else {
                    println("Master profileUser is nil")
                }
            }

            cell.tapAction = { [weak self] skill in
                self?.performSegue(withIdentifier: "showFeedsWithSkill", sender: ["skill": skill, "preferedSkillSet": SkillSet.master.rawValue])
            }

            return cell

        case .learning:
            let cell: SkillCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            cell.skill = profileUser?.cellSkillInSkillSet(.learning, atIndexPath: indexPath)

            if cell.skill == nil {
                if let profileUser = profileUser {
                    println("Learning profileUser: \(profileUser)")
                } else {
                    println("Learning profileUser is nil")
                }
            }

            cell.tapAction = { [weak self] skill in
                self?.performSegue(withIdentifier: "showFeedsWithSkill", sender: ["skill": skill, "preferedSkillSet": SkillSet.learning.rawValue])
            }

            return cell

        case .footer:
            let cell: ProfileFooterCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            if let profileUser = profileUser {
                cell.configureWithProfileUser(profileUser, introduction: introductionText)

                cell.tapUsernameAction = { [weak self] username in
                    self?.tryShowProfileWithUsername(username)
                }
            }

            return cell

        case .separationLine:
            let cell: ProfileSeparationLineCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        case .blog:
            let cell: ProfileSocialAccountBlogCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            cell.configureWithProfileUser(profileUser)

            return cell

        case .socialAccount:

            let index = (indexPath as NSIndexPath).item

            if let providerName = profileUser?.providerNameWithIndex(index), let socialAccount = SocialAccount(rawValue: providerName) {

                if socialAccount == .Github {
                    let cell: ProfileSocialAccountGithubCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    cell.configureWithProfileUser(profileUser, socialAccount: socialAccount, githubWork: githubWork, completion: { githubWork in
                        self.githubWork = githubWork
                    })

                    return cell

                } else {
                    let cell: ProfileSocialAccountImagesCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    
                    cell.socialAccount = socialAccount
                    
                    var socialWork: SocialWork?

                    switch socialAccount {

                    case .Dribbble:
                        if let dribbbleWork = dribbbleWork {
                            socialWork = SocialWork.dribbble(dribbbleWork)
                        }

                    case .Instagram:
                        if let instagramWork = instagramWork {
                            socialWork = SocialWork.instagram(instagramWork)
                        }

                    default:
                        break
                    }

                    cell.configureWithProfileUser(profileUser, socialAccount: socialAccount, socialWork: socialWork, completion: { socialWork in
                        switch socialWork {

                        case .dribbble(let dribbbleWork):
                            self.dribbbleWork = dribbbleWork

                        case .instagram(let instagramWork):
                            self.instagramWork = instagramWork
                        }
                    })
                    
                    return cell
                }
            }

            let cell: ProfileSocialAccountCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            return cell

        case .separationLine2:
            let cell: ProfileSeparationLineCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        case .feeds:
            let cell: ProfileFeedsCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

            cell.configureWithProfileUser(profileUser, feedAttachments: feedAttachments, completion: { [weak self] feeds, feedAttachments in
                self?.feeds = feeds
                self?.feedAttachments = feedAttachments
            })

            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {

            let header: ProfileSectionHeaderReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, forIndexPath: indexPath)

            guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
                fatalError()
            }

            switch section {

            case .master:
                header.titleLabel.text = SkillSet.master.name

            case .learning:
                header.titleLabel.text = SkillSet.learning.name

            default:
                header.titleLabel.text = ""
            }

            if profileUserIsMe {

                header.tapAction = { [weak self] in

                    let skillSet: SkillSet

                    switch section {

                    case .master:
                        skillSet = .master

                    case .learning:
                        skillSet = .learning

                    default:
                        skillSet = .master
                    }

                    self?.performSegue(withIdentifier: "showEditSkills", sender: ["skillSet": skillSet.rawValue])
                }

            } else {
                header.accessoryImageView.isHidden = true
            }

            return header

        } else {
            let footer: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, forIndexPath: indexPath)
            return footer
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .header:
            return UIEdgeInsets(top: 0, left: 0, bottom: sectionBottomEdgeInset, right: 0)

        case .master:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: 15, right: sectionRightEdgeInset)

        case .learning:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case .footer:
            return UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
            
        case .separationLine:
            return UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)

        case .blog:
            return insetForSectionBlog

        case .socialAccount:
            return insetForSectionSocialAccount

        case .separationLine2:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        case .feeds:
            return UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
        }
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .header:

            return CGSize(width: collectionViewWidth, height: collectionViewWidth * profileAvatarAspectRatio)

        case .master:

            let skillLocalName = profileUser?.cellSkillInSkillSet(.master, atIndexPath: indexPath)?.localName ?? ""

            let rect = skillLocalName.boundingRect(with: CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: skillTextAttributes, context: nil)

            return CGSize(width: rect.width + 24, height: SkillCell.height)

        case .learning:

            let skillLocalName = profileUser?.cellSkillInSkillSet(.learning, atIndexPath: indexPath)?.localName ?? ""

            let rect = skillLocalName.boundingRect(with: CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: skillTextAttributes, context: nil)

            return CGSize(width: rect.width + 24, height: SkillCell.height)

        case .footer:
            return CGSize(width: collectionViewWidth, height: footerCellHeight)

        case .separationLine:
            return CGSize(width: collectionViewWidth, height: 1)

        case .blog:
            return CGSize(width: collectionViewWidth, height: numberOfItemsInSectionBlog > 0 ? 40 : 0)

        case .socialAccount:
            return CGSize(width: collectionViewWidth, height: numberOfItemsInSectionSocialAccount > 0 ? 40 : 0)

        case .separationLine2:
            return CGSize(width: collectionViewWidth, height: 1)

        case .feeds:
            return CGSize(width: collectionViewWidth, height: 40)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let profileUser = profileUser else {
            return CGSize.zero
        }

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        let normalHeight: CGFloat = 40

        if profileUser.isMe {

            switch section {

            case .master:
                return CGSize(width: collectionViewWidth, height: normalHeight)

            case .learning:
                return CGSize(width: collectionViewWidth, height: normalHeight)

            default:
                return CGSize.zero
            }

        } else {
            switch section {

            case .master:
                let height: CGFloat = (profileUser.masterSkillsCount > 0 && profileUser.userID != YepUserDefaults.userID.value) ? normalHeight : 0
                return CGSize(width: collectionViewWidth, height: height)

            case .learning:
                let height: CGFloat = (profileUser.learningSkillsCount > 0 && profileUser.userID != YepUserDefaults.userID.value) ? normalHeight : 0
                return CGSize(width: collectionViewWidth, height: height)
                
            default:
                return CGSize.zero
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize.zero
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError()
        }

        switch section {

        case .learning, .master:
            // do in SkillCell's tapAction
            break

        case .blog:

            guard let profileUser = profileUser else {
                break
            }

            if profileUser.isMe {

                if let blogURLString = YepUserDefaults.blogURLString.value , !blogURLString.isEmpty, let blogURL = URL(string: blogURLString) {
                    yep_openURL(blogURL)

                } else {
                    YepAlert.textInput(title: NSLocalizedString("Set Blog", comment: ""), message: String.trans_promptInputBlogURL, placeholder: "example.com", oldText: nil, confirmTitle: NSLocalizedString("Set", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: { text in

                        let blogURLString = text

                        if blogURLString.isEmpty {
                            YepUserDefaults.blogTitle.value = nil
                            YepUserDefaults.blogURLString.value = nil

                            return
                        }

                        guard let blogURL = URL(string: blogURLString)?.yep_validSchemeNetworkURL else {
                            YepUserDefaults.blogTitle.value = nil
                            YepUserDefaults.blogURLString.value = nil

                            YepAlert.alertSorry(message: NSLocalizedString("You have entered an invalid URL!", comment: ""), inViewController: self)
                            
                            return
                        }

                        YepHUD.showActivityIndicator()

                        titleOfURL(blogURL, failureHandler: { [weak self] reason, errorMessage in

                            YepHUD.hideActivityIndicator()

                            defaultFailureHandler(reason, errorMessage)

                            YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set blog failed!", comment: ""), inViewController: self)
                            
                        }, completion: { blogTitle in

                            println("blogTitle: \(blogTitle)")

                            let info: JSONDictionary = [
                                "website_url": blogURLString,
                                "website_title": blogTitle,
                            ]

                            updateMyselfWithInfo(info, failureHandler: { [weak self] reason, errorMessage in

                                YepHUD.hideActivityIndicator()

                                defaultFailureHandler(reason, errorMessage)

                                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set blog failed!", comment: ""), inViewController: self)

                            }, completion: { success in

                                YepHUD.hideActivityIndicator()

                                SafeDispatch.async {
                                    YepUserDefaults.blogTitle.value = blogTitle
                                    YepUserDefaults.blogURLString.value = blogURLString
                                }
                            })
                        })

                    }, cancelAction: {
                    })
                }
                
            } else {
                if let blogURL = profileUser.blogURL {
                    yep_openURL(blogURL)
                }
            }
                
        case .socialAccount:

            let index = (indexPath as NSIndexPath).item

            guard let
                profileUser = profileUser,
                let providerName = profileUser.providerNameWithIndex(index),
                let socialAccount = SocialAccount(rawValue: providerName) else {
                    break
            }

            if profileUser.enabledSocialAccount(socialAccount) {
                performSegue(withIdentifier: "showSocialWork\(socialAccount.segue)", sender: providerName)

            } else {
                guard profileUserIsMe else {
                    break
                }

                afterOAuthAction = { [weak self] socialAccount in

                    // 更新自己的 provider enabled 状态
                    let providerName = socialAccount.rawValue
                    
                    SafeDispatch.async {

                        guard let realm = try? Realm() else {
                            return
                        }

                        guard let me = meInRealm(realm) else {
                            return
                        }

                        var haveSocialAccountProvider = false
                        for socialAccountProvider in me.socialAccountProviders {
                            if socialAccountProvider.name == providerName {
                                let _ = try? realm.write {
                                    socialAccountProvider.enabled = true
                                }
                                haveSocialAccountProvider = true
                                break
                            }
                        }
                        
                        // 如果之前没有，这就新建一个
                        if !haveSocialAccountProvider {
                            let provider = UserSocialAccountProvider()
                            provider.name = providerName
                            provider.enabled = true
                            
                            let _ = try? realm.write {
                                me.socialAccountProviders.append(provider)
                            }
                        }
                        
                        self?.updateProfileCollectionView()
                        
                        // OAuth 成功后，自动跳转去显示对应的 social work
                        _ = delay(1) {
                            self?.performSegue(withIdentifier: "showSocialWork\(socialAccount.segue)", sender: providerName)
                        }
                    }
                }

                do {
                    self.socialAccount = SocialAccount(rawValue: providerName)

                    guard let accessToken = YepUserDefaults.v1AccessToken.value else {
                        return
                    }

                    let safariViewController = SFSafariViewController(url: URL(string: "\(socialAccount.authURL)?_tkn=\(accessToken)")!)
                    present(safariViewController, animated: true, completion: nil)

                    oAuthCompleteAction = {
                        safariViewController.dismiss(animated: true, completion: {
                            // OAuth 成功后，自动跳转去显示对应的 social work
                            _ = delay(1) { [weak self] in
                                self?.performSegue(withIdentifier: "showSocialWork\(socialAccount.segue)", sender: providerName)
                            }
                        })
                    }
                }
            }

        case .feeds:

            guard let profileUser = profileUser else {
                break
            }

            let info: [String: AnyObject] = [
                "profileUser": Box(profileUser),
                "feeds": Box(feeds ?? []),
            ]

            performSegue(withIdentifier: "showFeedsOfProfileUser", sender: Box(info))

        default:
            break
        }
    }
}

extension ProfileViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if shareView.progress >= 1.0 {
            shareView.shareActionAnimationAndDoFurther({
                SafeDispatch.async { [weak self] in
                    self?.tryShareMyProfile(nil)
                }
            })
        }
    }
}

// MARK: - OAuthResult

extension ProfileViewController {
    
    func handleOAuthResult(_ notification: Notification) {
        
        oAuthCompleteAction?()

        if let result = notification.object as? NSNumber , result == 1, let socialAccount = self.socialAccount {

            socialAccountWithProvider(socialAccount.rawValue, failureHandler: { reason, errorMessage in

                defaultFailureHandler(reason, errorMessage)

            }, completion: { provider in

                println("provider: \(provider)")

                SafeDispatch.async { [weak self] in
                    self?.afterOAuthAction?(socialAccount)
                }
            })
            
        } else {
            YepAlert.alertSorry(message: String.trans_promptOAuthError, inViewController: self, withDismissAction: {})
        }
    }
}


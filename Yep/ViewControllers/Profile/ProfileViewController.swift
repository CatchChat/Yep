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
import YepConfig
import YepNetworking
import YepKit
import OpenGraph
import MonkeyKing
import Navi
import Kingfisher
import Proposer

let profileAvatarAspectRatio: CGFloat = 12.0 / 16.0

final class ProfileViewController: SegueViewController {
    
    private var socialAccount: SocialAccount?

    enum FromType {
        case None
        case OneToOneConversation
        case GroupConversation
    }
    var fromType: FromType = .None

    var oAuthCompleteAction: (() -> Void)?
    
    var afterOAuthAction: ((socialAccount: SocialAccount) -> Void)?

    var profileUser: ProfileUser?
    var profileUserIsMe = true {
        didSet {
            if !profileUserIsMe {

                //let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreAction")

                //customNavigationItem.rightBarButtonItem = moreBarButtonItem


                if fromType == .OneToOneConversation {
                    sayHiView.hidden = true

                } else {
                    sayHiView.tapAction = { [weak self] in
                        self?.sayHi()
                    }

                    profileCollectionView.contentInset.bottom = sayHiView.bounds.height
                }

            } else {
                sayHiView.hidden = true

                let settingsBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_settings"), style: .Plain, target: self, action: #selector(ProfileViewController.showSettings(_:)))

                customNavigationItem.rightBarButtonItem = settingsBarButtonItem

                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewController.createdFeed(_:)), name: YepConfig.Notification.createdFeed, object: nil)
                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewController.deletedFeed(_:)), name: YepConfig.Notification.deletedFeed, object: nil)
            }
        }
    }

    private var numberOfItemsInSectionBlog: Int {

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

    private var numberOfItemsInSectionSocialAccount: Int {

        return (profileUser?.providersCount ?? 0)
    }

    private var needSeparationLine: Bool {

        return (numberOfItemsInSectionBlog > 0) || (numberOfItemsInSectionSocialAccount > 0)
    }

    private var insetForSectionBlog: UIEdgeInsets {

        if numberOfItemsInSectionBlog > 0 {
            if numberOfItemsInSectionSocialAccount > 0 {
                return UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
            } else {
                return UIEdgeInsets(top: 30, left: 0, bottom: 40, right: 0)
            }
        } else {
            return UIEdgeInsetsZero
        }
    }

    private var insetForSectionSocialAccount: UIEdgeInsets {

        if numberOfItemsInSectionBlog > 0 {
            if numberOfItemsInSectionSocialAccount > 0 {
                return UIEdgeInsets(top: 10, left: 0, bottom: 30, right: 0)
            } else {
                return UIEdgeInsetsZero
            }
        } else {
            if numberOfItemsInSectionSocialAccount > 0 {
                return UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
            } else {
                return UIEdgeInsetsZero
            }
        }
    }

    private lazy var shareView: ShareProfileView = {
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

    private var statusBarShouldLight = false

    private var noNeedToChangeStatusBar = false

    @IBOutlet private weak var topShadowImageView: UIImageView!
    @IBOutlet weak var profileCollectionView: UICollectionView!

    @IBOutlet private weak var sayHiView: BottomButtonView!

    private lazy var customNavigationItem: UINavigationItem = UINavigationItem(title: "Details")
    private lazy var customNavigationBar: UINavigationBar = {

        let bar = UINavigationBar(frame: CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 64))

        bar.tintColor = UIColor.whiteColor()
        bar.tintAdjustmentMode = .Normal
        bar.alpha = 0
        bar.setItems([self.customNavigationItem], animated: false)

        bar.backgroundColor = UIColor.clearColor()
        bar.translucent = true
        bar.shadowImage = UIImage()
        bar.barStyle = UIBarStyle.BlackTranslucent
        bar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)

        let textAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: UIFont.navigationBarTitleFont()
        ]

        bar.titleTextAttributes = textAttributes
        
        return bar
    }()

    private let skillCellIdentifier = "SkillCell"
    private let headerCellIdentifier = "ProfileHeaderCell"
    private let footerCellIdentifier = "ProfileFooterCell"
    private let sectionHeaderIdentifier = "ProfileSectionHeaderReusableView"
    private let sectionFooterIdentifier = "ProfileSectionFooterReusableView"
    private let separationLineCellIdentifier = "ProfileSeparationLineCell"
    private let socialAccountCellIdentifier = "ProfileSocialAccountCell"
    private let socialAccountBlogCellIdentifier = "ProfileSocialAccountBlogCell"
    private let socialAccountImagesCellIdentifier = "ProfileSocialAccountImagesCell"
    private let socialAccountGithubCellIdentifier = "ProfileSocialAccountGithubCell"
    private let feedsCellIdentifier = "ProfileFeedsCell"

    private lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.profileCollectionView.bounds)
    }()
    private lazy var sectionLeftEdgeInset: CGFloat = { return YepConfig.Profile.leftEdgeInset }()
    private lazy var sectionRightEdgeInset: CGFloat = { return YepConfig.Profile.rightEdgeInset }()
    private lazy var sectionBottomEdgeInset: CGFloat = { return 0 }()

    private lazy var introductionText: String = {

        var introduction: String?

        if let profileUser = self.profileUser {
            switch profileUser {
                
            case .DiscoveredUserType(let discoveredUser):
                if let _introduction = discoveredUser.introduction {
                    if !_introduction.isEmpty {
                        introduction = _introduction
                    }
                }

            case .UserType(let user):

                if !user.introduction.isEmpty {
                    introduction = user.introduction
                }

                if user.friendState == UserFriendState.Me.rawValue {
                    YepUserDefaults.introduction.bindListener(self.listener.introduction) { [weak self] introduction in
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.introductionText = introduction ?? NSLocalizedString("No Introduction yet.", comment: "")
                            self?.updateProfileCollectionView()
                        }
                    }
                }
            }
        }

        return introduction ?? NSLocalizedString("No Introduction yet.", comment: "")
    }()

    private var masterSkills = [Skill]()

    private var learningSkills = [Skill]()

    private func updateMyMasterSkills() {

        guard let profileUser = profileUser where profileUser.isMe else {
            return
        }

        guard let realm = try? Realm() else {
            return
        }

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {
                let _ = try? realm.write {
                    me.masterSkills.removeAll()
                    let userSkills = userSkillsFromSkills(self.masterSkills, inRealm: realm)
                    me.masterSkills.appendContentsOf(userSkills)
                }
        }
    }

    private func updateMyLearningSkills() {

        guard let profileUser = profileUser where profileUser.isMe else {
            return
        }

        guard let realm = try? Realm() else {
            return
        }

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {
                let _ = try? realm.write {
                    me.learningSkills.removeAll()
                    let userSkills = userSkillsFromSkills(self.learningSkills, inRealm: realm)
                    me.learningSkills.appendContentsOf(userSkills)
                }
        }
    }

    private var dribbbleWork: DribbbleWork?
    private var instagramWork: InstagramWork?
    private var githubWork: GithubWork?
    private var feeds: [DiscoveredFeed]?
    private var feedAttachments: [DiscoveredAttachment?]?

    private let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextFont()]

    private var footerCellHeight: CGFloat {
        let attributes = [NSFontAttributeName: YepConfig.Profile.introductionLabelFont]
        let labelWidth = self.collectionViewWidth - (YepConfig.Profile.leftEdgeInset + YepConfig.Profile.rightEdgeInset)
        let rect = self.introductionText.boundingRectWithSize(CGSize(width: labelWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes:attributes, context:nil)
        return 10 + 24 + 4 + 18 + 10 + ceil(rect.height) + 4
    }

    private struct Listener {
        let nickname: String
        let introduction: String
        let avatar: String
        let blog: String
    }

    private lazy var listener: Listener = {

        let suffix = NSUUID().UUIDString

        return Listener(
            nickname: "Profile.Title" + suffix,
            introduction: "Profile.introductionText" + suffix,
            avatar: "Profile.Avatar" + suffix,
            blog: "Profile.Blog" + suffix
        )
    }()

    // MARK: Life cycle

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.nickname.removeListenerWithName(listener.nickname)
        YepUserDefaults.introduction.removeListenerWithName(listener.introduction)
        YepUserDefaults.avatarURLString.removeListenerWithName(listener.avatar)
        YepUserDefaults.blogURLString.removeListenerWithName(listener.blog)

        profileCollectionView?.delegate = nil

        println("deinit Profile")
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if statusBarShouldLight {
            return UIStatusBarStyle.LightContent
        } else {
            return UIStatusBarStyle.Default
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Kingfisher.ImageCache(name: "default").calculateDiskCacheSizeWithCompletionHandler({ (size) -> () in
            let cacheSize = Double(size)/1000000
            
            println(String(format: "%.2f MB", cacheSize))
            
            if cacheSize > 300 {
                 Kingfisher.ImageCache.defaultCache.clearDiskCache()
            }
        })

        title = NSLocalizedString("Profile", comment: "")

        view.addSubview(customNavigationBar)

        println("init ProfileViewController \(self)")

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewController.cleanForLogout(_:)), name: EditProfileViewController.Notification.Logout, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewController.prepareForOAuthResult(_:)), name: YepConfig.Notification.OAuthResult, object: nil)

        if let profileUser = profileUser {

            // 如果是 DiscoveredUser，也可能是好友或已存储的陌生人，查询本地 User 替换

            switch profileUser {

            case .DiscoveredUserType(let discoveredUser):

                guard let realm = try? Realm() else {
                    break
                }

                if let user = userWithUserID(discoveredUser.id, inRealm: realm) {
                    
                    self.profileUser = ProfileUser.UserType(user)

                    masterSkills = skillsFromUserSkillList(user.masterSkills)
                    learningSkills = skillsFromUserSkillList(user.learningSkills)

                    updateProfileCollectionView()
                }

            default:
                break
            }
            
            if let realm = try? Realm() {
                
                if let user = userWithUserID(profileUser.userID, inRealm: realm) {
                    
                    if user.friendState == UserFriendState.Normal.rawValue {
                        sayHiView.title = NSLocalizedString("Chat", comment: "")
                    }
                }
                
            }

        } else {

            // 为空的话就要显示自己
            syncMyInfoAndDoFurtherAction {

                // 提示没有 Skills
                guard let
                    myUserID = YepUserDefaults.userID.value,
                    realm = try? Realm(),
                    me = userWithUserID(myUserID, inRealm: realm) else {
                        return
                }

                if me.masterSkills.count == 0 && me.learningSkills.count == 0 {

                    YepAlert.confirmOrCancel(title: NSLocalizedString("Notice", comment: ""), message: NSLocalizedString("You don't have any skills!\nWould you like to pick some?", comment: ""), confirmTitle: NSLocalizedString("OK", comment: ""), cancelTitle: NSLocalizedString("Not now", comment: ""), inViewController: self, withConfirmAction: { [weak self] in
                        self?.pickSkills()
                    }, cancelAction: {})
                }
            }

            if let
                myUserID = YepUserDefaults.userID.value,
                realm = try? Realm(),
                me = userWithUserID(myUserID, inRealm: realm) {
                    profileUser = ProfileUser.UserType(me)

                    masterSkills = skillsFromUserSkillList(me.masterSkills)
                    learningSkills = skillsFromUserSkillList(me.learningSkills)

                    updateProfileCollectionView()
            }
        }

        profileUserIsMe = profileUser?.isMe ?? false

        if let profileLayout = profileCollectionView.collectionViewLayout as? ProfileLayout {

            profileLayout.scrollUpAction = { [weak self] progress in

                if let strongSelf = self {
                    let indexPath = NSIndexPath(forItem: 0, inSection: Section.Header.rawValue)
                    
                    if let coverCell = strongSelf.profileCollectionView.cellForItemAtIndexPath(indexPath) as? ProfileHeaderCell {
                        
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

        profileCollectionView.registerNib(UINib(nibName: skillCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: headerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: headerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: footerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: footerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: separationLineCellIdentifier, bundle: nil), forCellWithReuseIdentifier: separationLineCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: socialAccountCellIdentifier, bundle: nil), forCellWithReuseIdentifier: socialAccountCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: socialAccountBlogCellIdentifier, bundle: nil), forCellWithReuseIdentifier: socialAccountBlogCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: socialAccountImagesCellIdentifier, bundle: nil), forCellWithReuseIdentifier: socialAccountImagesCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: socialAccountGithubCellIdentifier, bundle: nil), forCellWithReuseIdentifier: socialAccountGithubCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: feedsCellIdentifier, bundle: nil), forCellWithReuseIdentifier: feedsCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: sectionHeaderIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: sectionHeaderIdentifier)
        profileCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: sectionFooterIdentifier)

        profileCollectionView.alwaysBounceVertical = true
        
        automaticallyAdjustsScrollViewInsets = false
        
        //Make sure when pan edge screen collectionview not scroll
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    profileCollectionView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        if let tabBarController = tabBarController {
            profileCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGRectGetHeight(tabBarController.tabBar.bounds), right: 0)
        }

        if let profileUser = profileUser {

            switch profileUser {

            case .DiscoveredUserType(let discoveredUser):
                customNavigationItem.title = discoveredUser.nickname

            case .UserType(let user):
                customNavigationItem.title = user.nickname

                if user.friendState == UserFriendState.Me.rawValue {
                    YepUserDefaults.nickname.bindListener(listener.nickname) { [weak self] nickname in
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.customNavigationItem.title = nickname
                            self?.updateProfileCollectionView()
                        }
                    }

                    YepUserDefaults.avatarURLString.bindListener(listener.avatar) { [weak self] avatarURLString in
                        dispatch_async(dispatch_get_main_queue()) {
                            let indexPath = NSIndexPath(forItem: 0, inSection: Section.Header.rawValue)
                            if let cell = self?.profileCollectionView.cellForItemAtIndexPath(indexPath) as? ProfileHeaderCell {
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

                    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ProfileViewController.updateUIForUsername(_:)), name: EditProfileViewController.Notification.NewUsername, object: nil)
                }
            }

            if !profileUserIsMe {

                let userID = profileUser.userID

                userInfoOfUserWithUserID(userID, failureHandler: nil, completion: { userInfo in
                    //println("userInfoOfUserWithUserID \(userInfo)")

                    // 对非好友来说，必要

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in

                        if let realm = try? Realm() {
                            let _ = try? realm.write {
                                updateUserWithUserID(userID, useUserInfo: userInfo, inRealm: realm)
                            }
                        }

                        if let discoveredUser = parseDiscoveredUser(userInfo) {
                            switch profileUser {
                            case .DiscoveredUserType:
                                self?.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
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
                    let shareMyProfileButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(ProfileViewController.tryShareMyProfile(_:)))
                    customNavigationItem.leftBarButtonItem = shareMyProfileButton
                }

                // try update blog title

                if let blogURLString = YepUserDefaults.blogURLString.value where !blogURLString.isEmpty, let blogURL = NSURL(string: blogURLString)?.yep_validSchemeNetworkURL {

                    titleOfURL(blogURL, failureHandler: nil, completion: { blogTitle in

                        println("blogTitle: \(blogTitle)")

                        if YepUserDefaults.blogTitle.value != blogTitle {

                            let info: JSONDictionary = [
                                "website_url": blogURLString,
                                "website_title": blogTitle,
                            ]

                            updateMyselfWithInfo(info, failureHandler: nil, completion: { success in

                                dispatch_async(dispatch_get_main_queue()) {
                                    YepUserDefaults.blogTitle.value = blogTitle
                                    YepUserDefaults.blogURLString.value = blogURLString
                                }
                            })

                        } else {
                            println("not need update blogTitle")
                        }
                    })
                }

            } else {
                // share others' profile button

                if let _ = profileUser.username {
                    let shareOthersProfileButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(ProfileViewController.shareOthersProfile(_:)))
                    customNavigationItem.rightBarButtonItem = shareOthersProfileButton
                }
            }
        }

        if profileUserIsMe {
            proposeToAccess(.Location(.WhenInUse), agreed: {
                YepLocationService.turnOn()

                YepLocationService.sharedManager.afterUpdatedLocationAction = { [weak self] newLocation in

                    let indexPath = NSIndexPath(forItem: 0, inSection: Section.Footer.rawValue)
                    if let cell = self?.profileCollectionView.cellForItemAtIndexPath(indexPath) as? ProfileFooterCell {
                        cell.location = newLocation
                    }
                }

            }, rejected: {
                println("Yep can NOT get Location. :[\n")
            })
        }

        #if DEBUG
            //view.addSubview(profileFPSLabel)
        #endif
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.setNavigationBarHidden(true, animated: true)
        customNavigationBar.alpha = 1.0

        statusBarShouldLight = false

        if noNeedToChangeStatusBar {
            statusBarShouldLight = true
        }

        self.setNeedsStatusBarAppearanceUpdate()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        statusBarShouldLight = true

        self.setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: Actions

    private func shareProfile() {

         if let username = profileUser?.username, profileURL = NSURL(string: "http://soyep.com/\(username)"), nickname = profileUser?.nickname {

            var thumbnail: UIImage?

            if let
                avatarURLString = profileUser?.avatarURLString,
                realm = try? Realm(),
                avatar = avatarWithAvatarURLString(avatarURLString, inRealm: realm) {
                    if let
                        avatarFileURL = NSFileManager.yepAvatarURLWithName(avatar.avatarFileName),
                        avatarFilePath = avatarFileURL.path,
                        image = UIImage(contentsOfFile: avatarFilePath) {
                            thumbnail = image.navi_centerCropWithSize(CGSize(width: 100, height: 100))
                    }
            }

            let info = MonkeyKing.Info(
                title: nickname,
                description: NSLocalizedString("From Yep, with Skills.", comment: ""),
                thumbnail: thumbnail,
                media: .URL(profileURL)
            )

            let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

            let weChatSessionActivity = WeChatActivity(
                type: .Session,
                message: sessionMessage,
                finish: { success in
                    println("share Profile to WeChat Session success: \(success)")
                }
            )

            let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: info))

            let weChatTimelineActivity = WeChatActivity(
                type: .Timeline,
                message: timelineMessage,
                finish: { success in
                    println("share Profile to WeChat Timeline success: \(success)")
                }
            )
            
            let activityViewController = UIActivityViewController(activityItems: ["\(nickname), \(NSLocalizedString("From Yep, with Skills.", comment: "")) \(profileURL)"], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])
            activityViewController.excludedActivityTypes = [UIActivityTypeMessage, UIActivityTypeMail]
            self.presentViewController(activityViewController, animated: true, completion: nil)
        }
    }

    @objc private func tryShareMyProfile(sender: AnyObject?) {

        if let _ = profileUser?.username {
            shareProfile()

        } else {
            YepAlert.textInput(title: NSLocalizedString("Create a username", comment: ""), message: NSLocalizedString("In order to share your profile, create a unique username first.", comment: ""), placeholder: NSLocalizedString("use letters, numbers, and underscore", comment: ""), oldText: nil, confirmTitle: NSLocalizedString("Create", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { text in

                let newUsername = text

                updateMyselfWithInfo(["username": newUsername], failureHandler: { [weak self] reason, errorMessage in
                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                    YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Create username failed!", comment: ""), inViewController: self)

                }, completion: { success in
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
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

                        self?.shareProfile()
                    }
                })

            }, cancelAction: {
            })
        }
    }

    @objc private func shareOthersProfile(sender: AnyObject) {
        shareProfile()
    }

    private func pickSkills() {

        let storyboard = UIStoryboard(name: "Intro", bundle: nil)
        let pickSkillsController = storyboard.instantiateViewControllerWithIdentifier("RegisterPickSkillsViewController") as! RegisterPickSkillsViewController

        pickSkillsController.isRegister = false
        pickSkillsController.masterSkills = self.masterSkills
        pickSkillsController.learningSkills = self.learningSkills

        pickSkillsController.afterChangeSkillsAction = { [weak self] masterSkills, learningSkills in
            self?.masterSkills = masterSkills
            self?.learningSkills = learningSkills

            dispatch_async(dispatch_get_main_queue()) {
                self?.updateMyMasterSkills()
                self?.updateMyLearningSkills()

                self?.updateProfileCollectionView()
            }
        }

        self.navigationController?.pushViewController(pickSkillsController, animated: true)
    }

    @objc private func showSettings(sender: AnyObject) {
        self.performSegueWithIdentifier("showSettings", sender: self)
    }

    func setBackButtonWithTitle() {
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_back"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(ProfileViewController.back(_:)))

        customNavigationItem.leftBarButtonItem = backBarButtonItem
    }

    @objc private func back(sender: AnyObject) {
        if let presentingViewController = presentingViewController {
            presentingViewController.dismissViewControllerAnimated(true, completion: nil)
        } else {
            navigationController?.popViewControllerAnimated(true)
        }
    }

    @objc private func cleanForLogout(sender: NSNotification) {
        profileUser = nil
    }

    @objc private func updateUIForUsername(sender: NSNotification) {
        updateProfileCollectionView()
    }

    private func updateFeedAttachmentsAfterUpdateFeeds() {

        feedAttachments = feeds!.map({ feed -> DiscoveredAttachment? in
            if let attachment = feed.attachment {
                if case let .Images(attachments) = attachment {
                    return attachments.first
                }
            }

            return nil
        })

        updateProfileCollectionView()
    }
    @objc private func createdFeed(sender: NSNotification) {

        guard feeds != nil else {
            return
        }

        let feed = (sender.object as! Box<DiscoveredFeed>).value
        feeds!.insert(feed, atIndex: 0)

        updateFeedAttachmentsAfterUpdateFeeds()
    }

    @objc private func deletedFeed(sender: NSNotification) {

        guard feeds != nil else {
            return
        }

        let feedID = sender.object as! String
        var indexOfDeletedFeed: Int?
        for (index, feed) in feeds!.enumerate() {
            if feed.id == feedID {
                indexOfDeletedFeed = index
                break
            }
        }
        guard let index = indexOfDeletedFeed else {
            return
        }
        feeds!.removeAtIndex(index)

        updateFeedAttachmentsAfterUpdateFeeds()
    }

    private func updateProfileCollectionView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.profileCollectionView.collectionViewLayout.invalidateLayout()
            self.profileCollectionView.reloadData()
            self.profileCollectionView.layoutIfNeeded()
        }
    }

    private func sayHi() {

        if let profileUser = profileUser {
                    
            guard let realm = try? Realm() else {
                return
            }

            switch profileUser {

            case .DiscoveredUserType(let discoveredUser):

                realm.beginWrite()
                let conversation = conversationWithDiscoveredUser(discoveredUser, inRealm: realm)
                _ = try? realm.commitWrite()

                if let conversation = conversation {
                    performSegueWithIdentifier("showConversation", sender: conversation)

                    NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
                }

            case .UserType(let user):

                if user.friendState != UserFriendState.Me.rawValue {

                    if user.conversation == nil {
                        let newConversation = Conversation()

                        newConversation.type = ConversationType.OneToOne.rawValue
                        newConversation.withFriend = user

                        let _ = try? realm.write {
                            realm.add(newConversation)
                        }
                    }

                    if let conversation = user.conversation {
                        performSegueWithIdentifier("showConversation", sender: conversation)

                        NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.changedConversation, object: nil)
                    }
                }
            }
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showConversation":
            let vc = segue.destinationViewController as! ConversationViewController
            vc.conversation = sender as! Conversation
            
        case "showFeedsWithSkill":

            let vc = segue.destinationViewController as! FeedsViewController

            if let
                skillInfo = sender as? [String: AnyObject],
                skill = skillInfo["skill"] as? SkillCellSkill {
                    vc.skill = Skill(category: nil, id: skill.ID, name: skill.localName, localName: skill.localName, coverURLString: skill.coverURLString)
            }

            vc.hidesBottomBarWhenPushed = true

        case "showFeedsOfProfileUser":

            let vc = segue.destinationViewController as! FeedsViewController

            if let
                info = (sender as? Box<[String: AnyObject]>)?.value,
                profileUser = (info["profileUser"] as? Box<ProfileUser>)?.value,
                feeds = (info["feeds"] as? Box<[DiscoveredFeed]>)?.value {
                    vc.profileUser = profileUser
                    vc.feeds = feeds
                    vc.preparedFeedsCount = feeds.count
            }
            
            vc.hideRightBarItem = true

            vc.hidesBottomBarWhenPushed = true

        case "showEditSkills":

            if let skillInfo = sender as? [String: AnyObject] {

                let vc = segue.destinationViewController as! EditSkillsViewController

                if let skillSet = skillInfo["skillSet"] as? Int {
                    vc.skillSet = SkillSet(rawValue: skillSet)
                }

                vc.afterChangedSkillsAction = { [weak self] in
                    self?.updateProfileCollectionView()
                }
            }

        case "presentOAuth":

            if let providerName = sender as? String {

                let nvc = segue.destinationViewController as! UINavigationController
                let vc = nvc.topViewController as! OAuthViewController
                vc.socialAccount = SocialAccount(rawValue: providerName)
                vc.afterOAuthAction = afterOAuthAction
            }

        case "showSocialWorkGithub":

            if let providerName = sender as? String {

                let vc = segue.destinationViewController as! SocialWorkGithubViewController
                vc.socialAccount = SocialAccount(rawValue: providerName)
                vc.profileUser = profileUser
                vc.githubWork = githubWork

                vc.afterGetGithubWork = {[weak self] githubWork in
                    self?.githubWork = githubWork
                }
            }

        case "showSocialWorkDribbble":

            if let providerName = sender as? String {

                let vc = segue.destinationViewController as! SocialWorkDribbbleViewController
                vc.socialAccount = SocialAccount(rawValue: providerName)
                vc.profileUser = profileUser
                vc.dribbbleWork = dribbbleWork

                vc.afterGetDribbbleWork = { [weak self] dribbbleWork in
                    self?.dribbbleWork = dribbbleWork
                }
            }

        case "showSocialWorkInstagram":

            if let providerName = sender as? String {

                let vc = segue.destinationViewController as! SocialWorkInstagramViewController
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
        case Header
        case Footer
        case Master
        case Learning
        case SeparationLine
        case Blog
        case SocialAccount
        case SeparationLine2
        case Feeds
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 9
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .Header:
            return 1

        case .Master:
            return profileUser?.masterSkillsCount ?? 0

        case .Learning:
            return profileUser?.learningSkillsCount ?? 0

        case .Footer:
            return 1

        case .SeparationLine:
            return needSeparationLine ? 1 : 0

        case .Blog:
            return numberOfItemsInSectionBlog

        case .SocialAccount:
            return numberOfItemsInSectionSocialAccount

        case .SeparationLine2:
            return 1

        case .Feeds:
            return 1
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Header:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(headerCellIdentifier, forIndexPath: indexPath) as! ProfileHeaderCell

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    cell.configureWithDiscoveredUser(discoveredUser)
                case .UserType(let user):
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

        case .Master:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell

            cell.skill = profileUser?.cellSkillInSkillSet(.Master, atIndexPath: indexPath)

            if cell.skill == nil {
                if let profileUser = profileUser {
                    println("Master profileUser: \(profileUser)")
                } else {
                    println("Master profileUser is nil")
                }
            }

            cell.tapAction = { [weak self] skill in
                self?.performSegueWithIdentifier("showFeedsWithSkill", sender: ["skill": skill, "preferedSkillSet": SkillSet.Master.rawValue])
            }

            return cell

        case .Learning:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell

            cell.skill = profileUser?.cellSkillInSkillSet(.Learning, atIndexPath: indexPath)

            if cell.skill == nil {
                if let profileUser = profileUser {
                    println("Learning profileUser: \(profileUser)")
                } else {
                    println("Learning profileUser is nil")
                }
            }

            cell.tapAction = { [weak self] skill in
                self?.performSegueWithIdentifier("showFeedsWithSkill", sender: ["skill": skill, "preferedSkillSet": SkillSet.Learning.rawValue])
            }

            return cell

        case .Footer:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(footerCellIdentifier, forIndexPath: indexPath) as! ProfileFooterCell

            if let profileUser = profileUser {
                cell.configureWithProfileUser(profileUser, introduction: introductionText)
            }

            return cell

        case .SeparationLine:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(separationLineCellIdentifier, forIndexPath: indexPath) as! ProfileSeparationLineCell
            return cell

        case .Blog:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(socialAccountBlogCellIdentifier, forIndexPath: indexPath) as! ProfileSocialAccountBlogCell

            cell.configureWithProfileUser(profileUser)

            return cell

        case .SocialAccount:

            let index = indexPath.item

            if let providerName = profileUser?.providerNameWithIndex(index), socialAccount = SocialAccount(rawValue: providerName) {

                if socialAccount == .Github {
                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(socialAccountGithubCellIdentifier, forIndexPath: indexPath) as! ProfileSocialAccountGithubCell

                    cell.configureWithProfileUser(profileUser, socialAccount: socialAccount, githubWork: githubWork, completion: { githubWork in
                        self.githubWork = githubWork
                    })

                    return cell

                } else {

                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(socialAccountImagesCellIdentifier, forIndexPath: indexPath) as! ProfileSocialAccountImagesCell
                    
                    cell.socialAccount = socialAccount
                    
                    var socialWork: SocialWork?

                    switch socialAccount {

                    case .Dribbble:
                        if let dribbbleWork = dribbbleWork {
                            socialWork = SocialWork.Dribbble(dribbbleWork)
                        }

                    case .Instagram:
                        if let instagramWork = instagramWork {
                            socialWork = SocialWork.Instagram(instagramWork)
                        }

                    default:
                        break
                    }

                    cell.configureWithProfileUser(profileUser, socialAccount: socialAccount, socialWork: socialWork, completion: { socialWork in
                        switch socialWork {

                        case .Dribbble(let dribbbleWork):
                            self.dribbbleWork = dribbbleWork

                        case .Instagram(let instagramWork):
                            self.instagramWork = instagramWork
                        }
                    })
                    
                    return cell
                }
            }

            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(socialAccountCellIdentifier, forIndexPath: indexPath) as! ProfileSocialAccountCell
            return cell

        case .SeparationLine2:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(separationLineCellIdentifier, forIndexPath: indexPath) as! ProfileSeparationLineCell
            return cell

        case .Feeds:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedsCellIdentifier, forIndexPath: indexPath) as! ProfileFeedsCell

            cell.configureWithProfileUser(profileUser, feedAttachments: feedAttachments, completion: { [weak self] feeds, feedAttachments in
                self?.feeds = feeds
                self?.feedAttachments = feedAttachments
            })

            return cell
        }
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {

            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionHeaderIdentifier, forIndexPath: indexPath) as! ProfileSectionHeaderReusableView

            guard let section = Section(rawValue: indexPath.section) else {
                fatalError()
            }

            switch section {

            case .Master:
                header.titleLabel.text = SkillSet.Master.name

            case .Learning:
                header.titleLabel.text = SkillSet.Learning.name

            default:
                header.titleLabel.text = ""
            }

            if profileUserIsMe {

                header.tapAction = { [weak self] in

                    let skillSet: SkillSet

                    switch section {

                    case .Master:
                        skillSet = .Master

                    case .Learning:
                        skillSet = .Learning

                    default:
                        skillSet = .Master
                    }

                    self?.performSegueWithIdentifier("showEditSkills", sender: ["skillSet": skillSet.rawValue])
                }

            } else {
                header.accessoryImageView.hidden = true
            }

            return header

        } else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionFooterIdentifier, forIndexPath: indexPath) 
            return footer
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {

        case .Header:
            return UIEdgeInsets(top: 0, left: 0, bottom: sectionBottomEdgeInset, right: 0)

        case .Master:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: 15, right: sectionRightEdgeInset)

        case .Learning:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case .Footer:
            return UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
            
        case .SeparationLine:
            return UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)

        case .Blog:
            return insetForSectionBlog

        case .SocialAccount:
            return insetForSectionSocialAccount

        case .SeparationLine2:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        case .Feeds:
            return UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Header:

            return CGSize(width: collectionViewWidth, height: collectionViewWidth * profileAvatarAspectRatio)

        case .Master:

            let skillLocalName = profileUser?.cellSkillInSkillSet(.Master, atIndexPath: indexPath)?.localName ?? ""

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)

            return CGSize(width: rect.width + 24, height: SkillCell.height)

        case .Learning:

            let skillLocalName = profileUser?.cellSkillInSkillSet(.Learning, atIndexPath: indexPath)?.localName ?? ""

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)

            return CGSize(width: rect.width + 24, height: SkillCell.height)

        case .Footer:
            return CGSize(width: collectionViewWidth, height: footerCellHeight)

        case .SeparationLine:
            return CGSize(width: collectionViewWidth, height: 1)

        case .Blog:
            return CGSize(width: collectionViewWidth, height: numberOfItemsInSectionBlog > 0 ? 40 : 0)

        case .SocialAccount:
            return CGSize(width: collectionViewWidth, height: numberOfItemsInSectionSocialAccount > 0 ? 40 : 0)

        case .SeparationLine2:
            return CGSize(width: collectionViewWidth, height: 1)

        case .Feeds:
            return CGSize(width: collectionViewWidth, height: 40)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let profileUser = profileUser else {
            return CGSizeZero
        }

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        let normalHeight: CGFloat = 40

        if profileUser.isMe {

            switch section {

            case .Master:
                return CGSizeMake(collectionViewWidth, normalHeight)

            case .Learning:
                return CGSizeMake(collectionViewWidth, normalHeight)

            default:
                return CGSizeZero
            }

        } else {
            switch section {

            case .Master:
                let height: CGFloat = (profileUser.masterSkillsCount > 0 && profileUser.userID != YepUserDefaults.userID.value) ? normalHeight : 0
                return CGSizeMake(collectionViewWidth, height)

            case .Learning:
                let height: CGFloat = (profileUser.learningSkillsCount > 0 && profileUser.userID != YepUserDefaults.userID.value) ? normalHeight : 0
                return CGSizeMake(collectionViewWidth, height)
                
            default:
                return CGSizeZero
            }
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSizeZero
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {

        case .Learning, .Master:
            // do in SkillCell's tapAction
            break

        case .Blog:

            guard let profileUser = profileUser else {
                break
            }

            if profileUser.isMe {

                if let blogURLString = YepUserDefaults.blogURLString.value where !blogURLString.isEmpty, let blogURL = NSURL(string: blogURLString) {
                    yep_openURL(blogURL)

                } else {
                    YepAlert.textInput(title: NSLocalizedString("Set Blog", comment: ""), message: NSLocalizedString("Input your blog's URL.", comment: ""), placeholder: "example.com", oldText: nil, confirmTitle: NSLocalizedString("Set", comment: ""), cancelTitle: NSLocalizedString("Cancel", comment: ""), inViewController: self, withConfirmAction: { text in

                        let blogURLString = text

                        if blogURLString.isEmpty {
                            YepUserDefaults.blogTitle.value = nil
                            YepUserDefaults.blogURLString.value = nil

                            return
                        }

                        guard let blogURL = NSURL(string: blogURLString)?.yep_validSchemeNetworkURL else {
                            YepUserDefaults.blogTitle.value = nil
                            YepUserDefaults.blogURLString.value = nil

                            YepAlert.alertSorry(message: NSLocalizedString("You have entered an invalid URL!", comment: ""), inViewController: self)
                            
                            return
                        }

                        YepHUD.showActivityIndicator()

                        titleOfURL(blogURL, failureHandler: { [weak self] reason, errorMessage in

                            YepHUD.hideActivityIndicator()

                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                            YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set blog failed!", comment: ""), inViewController: self)
                            
                        }, completion: { blogTitle in

                            println("blogTitle: \(blogTitle)")

                            let info: JSONDictionary = [
                                "website_url": blogURLString,
                                "website_title": blogTitle,
                            ]

                            updateMyselfWithInfo(info, failureHandler: { [weak self] reason, errorMessage in

                                YepHUD.hideActivityIndicator()

                                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("Set blog failed!", comment: ""), inViewController: self)

                            }, completion: { success in

                                YepHUD.hideActivityIndicator()

                                dispatch_async(dispatch_get_main_queue()) {
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
                
        case .SocialAccount:

            let index = indexPath.item

            guard let
                profileUser = profileUser,
                providerName = profileUser.providerNameWithIndex(index),
                socialAccount = SocialAccount(rawValue: providerName) else {
                    break
            }

            if profileUser.enabledSocialAccount(socialAccount) {
                performSegueWithIdentifier("showSocialWork\(socialAccount.segue)", sender: providerName)

            } else {
                guard profileUserIsMe else {
                    break
                }

                afterOAuthAction = { [weak self] socialAccount in

                    // 更新自己的 provider enabled 状态
                    let providerName = socialAccount.rawValue
                    
                    dispatch_async(dispatch_get_main_queue()) {

                        guard let
                            realm = try? Realm(),
                            myUserID = YepUserDefaults.userID.value,
                            me = userWithUserID(myUserID, inRealm: realm) else {
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
                        delay(1) {
                            self?.performSegueWithIdentifier("showSocialWork\(socialAccount.segue)", sender: providerName)
                        }
                    }
                }

                do {
                    self.socialAccount = SocialAccount(rawValue: providerName)

                    guard let accessToken = YepUserDefaults.v1AccessToken.value else {
                        performSegueWithIdentifier("presentOAuth", sender: providerName)
                        return
                    }

                    let safariViewController = SFSafariViewController(URL: NSURL(string: "\(socialAccount.authURL)?_tkn=\(accessToken)")!)
                    presentViewController(safariViewController, animated: true, completion: nil)

                    oAuthCompleteAction = {
                        safariViewController.dismissViewControllerAnimated(true, completion: {
                            // OAuth 成功后，自动跳转去显示对应的 social work
                            delay(1) { [weak self] in
                                self?.performSegueWithIdentifier("showSocialWork\(socialAccount.segue)", sender: providerName)
                            }
                        })
                    }
                }
            }

        case .Feeds:

            guard let profileUser = profileUser else {
                break
            }

            let info: [String: AnyObject] = [
                "profileUser": Box(profileUser),
                "feeds": Box(feeds ?? []),
            ]

            performSegueWithIdentifier("showFeedsOfProfileUser", sender: Box(info))

        default:
            break
        }
    }
}

extension ProfileViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if shareView.progress >= 1.0 {
            shareView.shareActionAnimationAndDoFurther({
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.tryShareMyProfile(nil)
                }
            })
        }
    }
}

// MARK: - NSURLConnectionDataDelegate

extension ProfileViewController: NSURLConnectionDataDelegate {
    
    func prepareForOAuthResult(notification: NSNotification) {
        
        oAuthCompleteAction?()

        if let result = notification.object as? NSNumber, socialAccount = self.socialAccount {
            if result == 1 {
                
                socialAccountWithProvider(socialAccount.rawValue, failureHandler: { reason, errorMessage in

                    defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                }, completion: { provider in

                    println("provider: \(provider)")

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.afterOAuthAction?(socialAccount: socialAccount)
                    }
                })
                
            } else {
                
                YepAlert.alertSorry(message: NSLocalizedString("OAuth Error", comment: ""), inViewController: self, withDismissAction: {})
            }
        }
    }
}


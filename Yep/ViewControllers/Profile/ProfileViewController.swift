//
//  ProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift
import MonkeyKing
import Navi
import Crashlytics
import SafariServices
import Kingfisher
import Proposer
import CoreLocation

let profileAvatarAspectRatio: CGFloat = 12.0 / 16.0

enum SocialAccount: String {

    case Dribbble = "dribbble"
    case Github = "github"
    case Instagram = "instagram"
    case Behance = "behance"
    
    var name: String {
        
        switch self {
        case .Dribbble:
            return "Dribbble"
        case .Github:
            return "GitHub"
        case .Behance:
            return "Behance"
        case .Instagram:
            return "Instagram"
        }
    }

    var segue: String {

        switch self {
        case .Dribbble:
            return "Dribbble"
        case .Github:
            return "Github"
        case .Behance:
            return "Behance"
        case .Instagram:
            return "Instagram"
        }
    }
    
    var tintColor: UIColor {
        
        switch self {
        case .Dribbble:
            return UIColor(red:0.91, green:0.28, blue:0.5, alpha:1)
        case .Github:
            return UIColor.blackColor()
        case .Behance:
            return UIColor(red:0, green:0.46, blue:1, alpha:1)
        case .Instagram:
            return UIColor(red:0.15, green:0.36, blue:0.54, alpha:1)
        }
    }

    static let disabledColor: UIColor = UIColor.lightGrayColor()
    
    var iconName: String {
        
        switch self {
        case .Dribbble:
            return "icon_dribbble"
        case .Github:
            return "icon_github"
        case .Behance:
            return "icon_behance"
        case .Instagram:
            return "icon_instagram"
        }
    }
    
    var authURL: NSURL {
        
        switch self {
        case .Dribbble:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/dribbble")!
        case .Github:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/github")!
        case .Behance:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/behance")!
        case .Instagram:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/instagram")!
        }
    }
}

enum ProfileUser {
    case DiscoveredUserType(DiscoveredUser)
    case UserType(User)

    var userID: String {
        switch self {
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.id

        case .UserType(let user):
            return user.userID
        }
    }

    var username: String? {

        var username: String? = nil

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            username = discoveredUser.username

        case .UserType(let user):
            if !user.username.isEmpty {
                username = user.username
            }
        }

        return username
    }

    var nickname: String {
        switch self {
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.nickname

        case .UserType(let user):
            return user.nickname
        }
    }

    var avatarURLString: String? {

        var avatarURLString: String? = nil

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            avatarURLString = discoveredUser.avatarURLString

        case .UserType(let user):
            if !user.avatarURLString.isEmpty {
                avatarURLString = user.avatarURLString
            }
        }
        
        return avatarURLString
    }

    var isMe: Bool {

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.isMe

        case .UserType(let user):
            return user.isMe
        }
    }

    func enabledSocialAccount(socialAccount: SocialAccount) -> Bool {
        var accountEnabled = false

        let providerName = socialAccount.rawValue

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            for provider in discoveredUser.socialAccountProviders {
                if (provider.name == providerName) && provider.enabled {

                    accountEnabled = true

                    break
                }
            }

        case .UserType(let user):
            for provider in user.socialAccountProviders {
                if (provider.name == providerName) && provider.enabled {

                    accountEnabled = true

                    break
                }
            }
        }

        return accountEnabled
    }

    var masterSkillsCount: Int {
        switch self {
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.masterSkills.count
        case .UserType(let user):
            return Int(user.masterSkills.count)
        }
    }

    var learningSkillsCount: Int {
        switch self {
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.learningSkills.count
        case .UserType(let user):
            return Int(user.learningSkills.count)
        }
    }

    var providersCount: Int {

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.socialAccountProviders.filter({ $0.enabled }).count

        case .UserType(let user):

            if user.friendState == UserFriendState.Me.rawValue {
                return user.socialAccountProviders.count

            } else {
                return user.socialAccountProviders.filter("enabled = true").count
            }
        }
    }

    func cellSkillInSkillSet(skillSet: SkillSet, atIndexPath indexPath: NSIndexPath)  -> SkillCell.Skill? {

        switch self {

        case .DiscoveredUserType(let discoveredUser):

            let skill: Skill?
            switch skillSet {
            case .Master:
                skill = discoveredUser.masterSkills[safe: indexPath.item]
            case .Learning:
                skill = discoveredUser.learningSkills[safe: indexPath.item]
            }

            if let skill = skill {
                return SkillCell.Skill(ID: skill.id, localName: skill.localName, coverURLString: skill.coverURLString, category: skill.skillCategory)
            }

        case .UserType(let user):

            let userSkill: UserSkill?
            switch skillSet {
            case .Master:
                userSkill = user.masterSkills[safe: indexPath.item]
            case .Learning:
                userSkill = user.learningSkills[safe: indexPath.item]
            }

            if let userSkill = userSkill {
                return SkillCell.Skill(ID: userSkill.skillID, localName: userSkill.localName, coverURLString: userSkill.coverURLString, category: userSkill.skillCategory)
            }
        }

        return nil
    }

    func providerNameWithIndexPath(indexPath: NSIndexPath) -> String? {

        var providerName: String?

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            if let provider = discoveredUser.socialAccountProviders.filter({ $0.enabled })[safe: indexPath.row] {
                providerName = provider.name
            }

        case .UserType(let user):

            if user.friendState == UserFriendState.Me.rawValue {
                if let provider = user.socialAccountProviders[safe: indexPath.row] {
                    providerName = provider.name
                }

            } else {
                if let provider = user.socialAccountProviders.filter("enabled = true")[safe: indexPath.row] {
                    providerName = provider.name
                }
            }
        }

        return providerName
    }

    var needSeparationLine: Bool {

        return providersCount > 0
    }
}

class ProfileViewController: SegueViewController {
    
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

                let settingsBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_settings"), style: .Plain, target: self, action: "showSettings:")

                customNavigationItem.rightBarButtonItem = settingsBarButtonItem

                NSNotificationCenter.defaultCenter().addObserver(self, selector: "createdFeed:", name: YepConfig.Notification.createdFeed, object: nil)
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
                            if let introduction = introduction {
                                self?.introductionText = introduction
                                self?.updateProfileCollectionView()
                            }
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
    }

    private lazy var listener: Listener = {

        let suffix = NSUUID().UUIDString

        return Listener(nickname: "Profile.Title" + suffix, introduction: "Profile.introductionText" + suffix, avatar: "Profile.Avatar" + suffix)
    }()

    // MARK: Life cycle

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)

        YepUserDefaults.nickname.removeListenerWithName(listener.nickname)
        YepUserDefaults.introduction.removeListenerWithName(listener.introduction)
        YepUserDefaults.avatarURLString.removeListenerWithName(listener.avatar)

        profileCollectionView?.delegate = nil

        println("deinit ProfileViewController")
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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanForLogout:", name: EditProfileViewController.Notification.Logout, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "prepareForOAuthResult:", name: YepConfig.Notification.OAuthResult, object: nil)

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
                    let indexPath = NSIndexPath(forItem: 0, inSection: ProfileSection.Header.rawValue)
                    
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
                            let indexPath = NSIndexPath(forItem: 0, inSection: ProfileSection.Header.rawValue)
                            if let cell = self?.profileCollectionView.cellForItemAtIndexPath(indexPath) as? ProfileHeaderCell {
                                if let avatarURLString = avatarURLString {
                                    cell.blurredAvatarImage = nil // need reblur
                                    cell.updateAvatarWithAvatarURLString(avatarURLString)
                                }
                            }
                        }
                    }

                    NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUIForUsername:", name: EditProfileViewController.Notification.NewUsername, object: nil)
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
                    let shareMyProfileButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "tryShareMyProfile:")
                    customNavigationItem.leftBarButtonItem = shareMyProfileButton
                }

            } else {
                // share others' profile button

                if let _ = profileUser.username {
                    let shareOthersProfileButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "shareOthersProfile:")
                    customNavigationItem.rightBarButtonItem = shareOthersProfileButton
                }
            }
        }

        if profileUserIsMe {
            proposeToAccess(.Location(.WhenInUse), agreed: {
                YepLocationService.turnOn()

                YepLocationService.sharedManager.afterUpdatedLocationAction = { [weak self] newLocation in

                    let indexPath = NSIndexPath(forItem: 0, inSection: ProfileSection.Footer.rawValue)
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

        self.navigationController?.navigationBarHidden = true
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
        let backBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_back"), style: UIBarButtonItemStyle.Plain, target: self, action: "popBack:")

        customNavigationItem.leftBarButtonItem = backBarButtonItem
    }

    @objc private func popBack(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }

    @objc private func cleanForLogout(sender: NSNotification) {
        profileUser = nil
    }

    @objc private func updateUIForUsername(sender: NSNotification) {
        updateProfileCollectionView()
    }

    @objc private func createdFeed(sender: NSNotification) {

        guard self.feeds != nil else {
            return
        }

        let feed = (sender.object as! Box<DiscoveredFeed>).value
        self.feeds!.insert(feed, atIndex: 0)

        let feedAttachments = feeds!.map({ feed -> DiscoveredAttachment? in
            if let attachment = feed.attachment {
                if case let .Images(attachments) = attachment {
                    return attachments.first
                }
            }

            return nil
        })
        self.feedAttachments = feedAttachments

        updateProfileCollectionView()
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
                var stranger = userWithUserID(discoveredUser.id, inRealm: realm)

                if stranger == nil {
                    let newUser = User()

                    newUser.userID = discoveredUser.id

                    newUser.friendState = UserFriendState.Stranger.rawValue

                    let _ = try? realm.write {
                        realm.add(newUser)
                    }

                    stranger = newUser
                }

                if let user = stranger {

                    let _ = try? realm.write {

                        // 更新用户信息

                        user.lastSignInUnixTime = discoveredUser.lastSignInUnixTime

                        user.username = discoveredUser.username ?? ""

                        user.nickname = discoveredUser.nickname

                        if let introduction = discoveredUser.introduction {
                            user.introduction = introduction
                        }
                        
                        user.avatarURLString = discoveredUser.avatarURLString

                        user.longitude = discoveredUser.longitude

                        user.latitude = discoveredUser.latitude

                        if let badge = discoveredUser.badge {
                            user.badge = badge
                        }

                        // 更新技能

                        user.learningSkills.removeAll()
                        let learningUserSkills = userSkillsFromSkills(discoveredUser.learningSkills, inRealm: realm)
                        user.learningSkills.appendContentsOf(learningUserSkills)

                        user.masterSkills.removeAll()
                        let masterUserSkills = userSkillsFromSkills(discoveredUser.masterSkills, inRealm: realm)
                        user.masterSkills.appendContentsOf(masterUserSkills)

                        // 更新 Social Account Provider

                        user.socialAccountProviders.removeAll()
                        let socialAccountProviders = userSocialAccountProvidersFromSocialAccountProviders(discoveredUser.socialAccountProviders)
                        user.socialAccountProviders.appendContentsOf(socialAccountProviders)
                    }

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
                skill = skillInfo["skill"] as? SkillCell.Skill {
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
    
    enum ProfileSection: Int {
        case Header = 0
        case Footer
        case Master
        case Learning
        case SeparationLine
        case SocialAccount
        case SeparationLine2
        case Feeds
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 8
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch section {

        case ProfileSection.Header.rawValue:
            return 1

        case ProfileSection.Master.rawValue:
            return profileUser?.masterSkillsCount ?? 0

        case ProfileSection.Learning.rawValue:
            return profileUser?.learningSkillsCount ?? 0

        case ProfileSection.Footer.rawValue:
            return 1

        case ProfileSection.SeparationLine.rawValue:
            let needSeparationLine = profileUser?.needSeparationLine ?? false
            return needSeparationLine ? 1 : 0
            
        case ProfileSection.SocialAccount.rawValue:
            return profileUser?.providersCount ?? 0

        case ProfileSection.SeparationLine2.rawValue:
            return 1

        case ProfileSection.Feeds.rawValue:
            return 1

        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case ProfileSection.Header.rawValue:
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

        case ProfileSection.Master.rawValue:
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

        case ProfileSection.Learning.rawValue:
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

        case ProfileSection.Footer.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(footerCellIdentifier, forIndexPath: indexPath) as! ProfileFooterCell

            if let profileUser = profileUser {
                cell.configureWithProfileUser(profileUser, introduction: introductionText)
            }

            return cell

        case ProfileSection.SeparationLine.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(separationLineCellIdentifier, forIndexPath: indexPath) as! ProfileSeparationLineCell
            return cell
            
        case ProfileSection.SocialAccount.rawValue:

            if let providerName = profileUser?.providerNameWithIndexPath(indexPath), socialAccount = SocialAccount(rawValue: providerName) {

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

        case ProfileSection.SeparationLine2.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(separationLineCellIdentifier, forIndexPath: indexPath) as! ProfileSeparationLineCell
            return cell

        case ProfileSection.Feeds.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(feedsCellIdentifier, forIndexPath: indexPath) as! ProfileFeedsCell

            cell.configureWithProfileUser(profileUser, feedAttachments: feedAttachments, completion: { [weak self] feeds, feedAttachments in
                self?.feeds = feeds
                self?.feedAttachments = feedAttachments
            })

            return cell

        default:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell
            return cell
        }
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {

            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionHeaderIdentifier, forIndexPath: indexPath) as! ProfileSectionHeaderReusableView

            switch indexPath.section {

            case ProfileSection.Master.rawValue:
                header.titleLabel.text = SkillSet.Master.name

            case ProfileSection.Learning.rawValue:
                header.titleLabel.text = SkillSet.Learning.name

            default:
                header.titleLabel.text = ""
            }

            if profileUserIsMe {

                header.tapAction = { [weak self] in

                    let skillSet: SkillSet

                    switch indexPath.section {

                    case ProfileSection.Master.rawValue:
                        skillSet = .Master

                    case ProfileSection.Learning.rawValue:
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

        switch section {

        case ProfileSection.Header.rawValue:
            return UIEdgeInsets(top: 0, left: 0, bottom: sectionBottomEdgeInset, right: 0)

        case ProfileSection.Master.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: 15, right: sectionRightEdgeInset)

        case ProfileSection.Learning.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case ProfileSection.Footer.rawValue:
            return UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
            
        case ProfileSection.SeparationLine.rawValue:
            return UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)

        case ProfileSection.SocialAccount.rawValue:
            let inset: CGFloat = (profileUser?.providersCount ?? 0) > 0 ? 30 : 0
            return UIEdgeInsets(top: inset, left: 0, bottom: inset, right: 0)

        case ProfileSection.SeparationLine2.rawValue:
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        case ProfileSection.Feeds.rawValue:
            return UIEdgeInsets(top: 30, left: 0, bottom: 30, right: 0)

        default:
            return UIEdgeInsetsZero
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        switch indexPath.section {

        case ProfileSection.Header.rawValue:

            return CGSize(width: collectionViewWidth, height: collectionViewWidth * profileAvatarAspectRatio)

        case ProfileSection.Master.rawValue:

            let skillLocalName = profileUser?.cellSkillInSkillSet(.Master, atIndexPath: indexPath)?.localName ?? ""

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)

            return CGSize(width: rect.width + 24, height: SkillCell.height)

        case ProfileSection.Learning.rawValue:

            let skillLocalName = profileUser?.cellSkillInSkillSet(.Learning, atIndexPath: indexPath)?.localName ?? ""

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)

            return CGSize(width: rect.width + 24, height: SkillCell.height)

        case ProfileSection.Footer.rawValue:
            return CGSize(width: collectionViewWidth, height: footerCellHeight)

        case ProfileSection.SeparationLine.rawValue:
            return CGSize(width: collectionViewWidth, height: 1)
            
        case ProfileSection.SocialAccount.rawValue:
            return CGSize(width: collectionViewWidth, height: (profileUser?.providersCount ?? 0) > 0 ? 40 : 0)

        case ProfileSection.SeparationLine2.rawValue:
            return CGSize(width: collectionViewWidth, height: 1)

        case ProfileSection.Feeds.rawValue:
            return CGSize(width: collectionViewWidth, height: 40)

        default:
            return CGSizeZero
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        guard let profileUser = profileUser else {
            return CGSizeZero
        }

        let normalHeight: CGFloat = 40

        if profileUser.isMe {

            switch section {

            case ProfileSection.Master.rawValue:
                return CGSizeMake(collectionViewWidth, normalHeight)

            case ProfileSection.Learning.rawValue:
                return CGSizeMake(collectionViewWidth, normalHeight)

            default:
                return CGSizeZero
            }

        } else {
            switch section {

            case ProfileSection.Master.rawValue:
                let height: CGFloat = (profileUser.masterSkillsCount > 0 && profileUser.userID != YepUserDefaults.userID.value) ? normalHeight : 0
                return CGSizeMake(collectionViewWidth, height)

            case ProfileSection.Learning.rawValue:
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

        switch indexPath.section {

        case ProfileSection.Learning.rawValue, ProfileSection.Master.rawValue:
            // do in SkillCell's tapAction
            break

        case ProfileSection.SocialAccount.rawValue:

            if let profileUser = profileUser {

                if let providerName = profileUser.providerNameWithIndexPath(indexPath), socialAccount = SocialAccount(rawValue: providerName) {

                    if profileUser.enabledSocialAccount(socialAccount) {
                        performSegueWithIdentifier("showSocialWork\(socialAccount.segue)", sender: providerName)

                    } else {
                        if profileUserIsMe {
                            
                            afterOAuthAction = { [weak self] socialAccount in
                                // 更新自己的 provider enabled 状态
                                let providerName = socialAccount.rawValue
                                
                                dispatch_async(dispatch_get_main_queue()) {
                                    guard let realm = try? Realm() else {
                                        return
                                    }
                                    
                                    if let
                                        myUserID = YepUserDefaults.userID.value,
                                        me = userWithUserID(myUserID, inRealm: realm) {
                                            
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
                            }
                            
                            if isOperatingSystemAtLeastMajorVersion(9) {
                            
                                self.socialAccount = SocialAccount(rawValue: providerName)

                                if #available(iOS 9.0, *) {

                                    guard let accessToken = YepUserDefaults.v1AccessToken.value else {
                                        performSegueWithIdentifier("presentOAuth", sender: providerName)
                                        return
                                    }

                                    let safariViewController = SFSafariViewController(URL: NSURL(string: "\(socialAccount.authURL)?_tkn=\(accessToken)")!)
                                    presentViewController(safariViewController, animated: true, completion: nil)
                                    
                                    oAuthCompleteAction = {
                                        safariViewController.dismissViewControllerAnimated(true, completion: nil)
                                    }

                                } else {
                                    performSegueWithIdentifier("presentOAuth", sender: providerName)
                                }
                                
                            } else {
                                performSegueWithIdentifier("presentOAuth", sender: providerName)
                            }
                        }
                    }
                }
            }

        case ProfileSection.Feeds.rawValue:
            guard let profileUser = profileUser else {
                return
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


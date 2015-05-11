//
//  ProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import RealmSwift

let profileAvatarAspectRatio: CGFloat = 12.0 / 16.0

enum SocialAccount: Int, Printable {
    case Dribbble = 0
    case Github
    case Instagram
    case Behance
    
    var description: String {
        
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
            return NSURL(string: "\(baseURL.absoluteString!)/auth/dribbble")!
        case .Github:
            return NSURL(string: "\(baseURL.absoluteString!)/auth/github")!
        case .Behance:
            return NSURL(string: "\(baseURL.absoluteString!)/auth/behance")!
        case .Instagram:
            return NSURL(string: "\(baseURL.absoluteString!)/auth/instagram")!
        }
    }
}

enum ProfileUser {
    case DiscoveredUserType(DiscoveredUser)
    case UserType(User)
}

class ProfileViewController: CustomNavigationBarViewController {

    var profileUser: ProfileUser?


    @IBOutlet weak var profileCollectionView: UICollectionView!

    @IBOutlet weak var sayHiView: UIView!
    @IBOutlet weak var sayHiButton: UIButton!
    

    let skillCellIdentifier = "SkillCell"
    let headerCellIdentifier = "ProfileHeaderCell"
    let footerCellIdentifier = "ProfileFooterCell"
    let sectionHeaderIdentifier = "ProfileSectionHeaderReusableView"
    let sectionFooterIdentifier = "ProfileSectionFooterReusableView"
    let separationLineCellIdentifier = "ProfileSeparationLineCell"
    let socialAccountCellIdentifier = "ProfileSocialAccountCell"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.profileCollectionView.bounds)
        }()
    lazy var sectionLeftEdgeInset: CGFloat = { return YepConfig.Profile.leftEdgeInset }()
    lazy var sectionRightEdgeInset: CGFloat = { return YepConfig.Profile.rightEdgeInset }()
    lazy var sectionBottomEdgeInset: CGFloat = { return 0 }()

    let introductionText = "I would like to learn Design or Speech, I can teach you iOS Dev in return. 😃"

    var masterSkills = [Skill]()
    var learningSkills = [Skill]()

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextFont()]

    lazy var footerCellHeight: CGFloat = {
        let attributes = [NSFontAttributeName: YepConfig.Profile.introductionLabelFont]
        let labelWidth = self.collectionViewWidth - (YepConfig.Profile.leftEdgeInset + YepConfig.Profile.rightEdgeInset)
        let rect = self.introductionText.boundingRectWithSize(CGSize(width: labelWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes:attributes, context:nil)
        return ceil(rect.height) + 4
        }()


    override func viewDidLoad() {
        super.viewDidLoad()

        profileCollectionView.registerNib(UINib(nibName: skillCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: headerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: headerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: footerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: footerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: separationLineCellIdentifier, bundle: nil), forCellWithReuseIdentifier: separationLineCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: socialAccountCellIdentifier, bundle: nil), forCellWithReuseIdentifier: socialAccountCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: sectionHeaderIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: sectionHeaderIdentifier)
        profileCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: sectionFooterIdentifier)

        profileCollectionView.alwaysBounceVertical = true
        
        automaticallyAdjustsScrollViewInsets = false

        if let tabBarController = tabBarController {
            profileCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGRectGetHeight(tabBarController.tabBar.bounds), right: 0)
        }

        if let profileUser = profileUser {
            switch profileUser {
            case .DiscoveredUserType(let discoveredUser):
                self.navigationItem.title = discoveredUser.nickname
            case .UserType(let user):
                self.navigationItem.title = user.nickname
            }

        } else {
            YepUserDefaults.nickname.bindAndFireListener("ProfileViewController.Title") { nickname in
                self.navigationItem.title = nickname
            }
        }

        if let profileUser = profileUser {
            let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "icon_more"), style: UIBarButtonItemStyle.Plain, target: self, action: "moreAction")
            navigationItem.rightBarButtonItem = moreBarButtonItem

            sayHiButton.setTitle(NSLocalizedString("Say Hi", comment: ""), forState: .Normal)
            sayHiButton.layer.cornerRadius = 5
            sayHiButton.backgroundColor = UIColor.yepTintColor()
            profileCollectionView.contentInset.bottom = sayHiView.bounds.height

        } else {
            userInfo(failureHandler: nil) { userInfo in
                if let skillsData = userInfo["master_skills"] as? [JSONDictionary] {
                    self.masterSkills = skillsFromSkillsData(skillsData)
                }

                if let skillsData = userInfo["learning_skills"] as? [JSONDictionary] {
                    self.learningSkills = skillsFromSkillsData(skillsData)
                }

                dispatch_async(dispatch_get_main_queue()) {
                    self.profileCollectionView.reloadData()
                }
            }

            sayHiView.hidden = true
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showConversation" {
            let vc = segue.destinationViewController as! ConversationViewController
            vc.conversation = sender as! Conversation
            
        } else if segue.identifier == "showSkillHome" {
            if let cell = sender as? SkillCell {
                let vc = segue.destinationViewController as! SkillHomeViewController
                vc.hidesBottomBarWhenPushed = true
                vc.skillName = cell.skillLabel.text
            }

        } else if segue.identifier == "presentOAuth" {
            if let item = sender as? Int {
                let nvc = segue.destinationViewController as! UINavigationController
                let vc = nvc.topViewController as! OAuthViewController
                vc.socialAccount = SocialAccount(rawValue: item)
            }
        }
    }

    // MARK: Actions

    @IBAction func sayHi(sender: UIButton) {

        if let profileUser = profileUser {

            let realm = Realm()

            switch profileUser {

            case .DiscoveredUserType(let discoveredUser):
                var stranger = userWithUserID(discoveredUser.id, inRealm: realm)

                if stranger == nil {
                    let newUser = User()

                    newUser.userID = discoveredUser.id
                    newUser.nickname = discoveredUser.nickname
                    newUser.avatarURLString = discoveredUser.avatarURLString

                    newUser.friendState = UserFriendState.Stranger.rawValue

                    realm.beginWrite()
                    realm.add(newUser)
                    realm.commitWrite()

                    stranger = newUser
                }

                if let stranger = stranger {
                    if stranger.conversation == nil {
                        let newConversation = Conversation()

                        newConversation.type = ConversationType.OneToOne.rawValue
                        newConversation.withFriend = stranger

                        realm.beginWrite()
                        realm.add(newConversation)
                        realm.commitWrite()
                    }

                    if let conversation = stranger.conversation {
                        performSegueWithIdentifier("showConversation", sender: conversation)
                        
                        NSNotificationCenter.defaultCenter().postNotificationName(YepNewMessagesReceivedNotification, object: nil)
                    }
                }

            case .UserType(let user):
                if user.conversation == nil {
                    let newConversation = Conversation()

                    newConversation.type = ConversationType.OneToOne.rawValue
                    newConversation.withFriend = user

                    realm.beginWrite()
                    realm.add(newConversation)
                    realm.commitWrite()
                }

                if let conversation = user.conversation {
                    performSegueWithIdentifier("showConversation", sender: conversation)

                    NSNotificationCenter.defaultCenter().postNotificationName(YepNewMessagesReceivedNotification, object: nil)
                }
            }
        }
    }

    func moreAction() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let reportAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Report", comment: ""), style: .Default) { action -> Void in
            // TODO: reportAction
        }
        alertController.addAction(reportAction)

        let blockAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Block", comment: ""), style: .Destructive) { action -> Void in
            // TODO: blockAction
        }
        alertController.addAction(blockAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(cancelAction)

        self.presentViewController(alertController, animated: true, completion: nil)
    }

}

// MARK: UICollectionView

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    enum ProfileSection: Int {
        case Header = 0
        case Footer
        case Master
        case Learning
        case SeparationLine
        case SocialAccount
    }

    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 6
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch section {

        case ProfileSection.Header.rawValue:
            return 1

        case ProfileSection.Master.rawValue:
            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    return discoveredUser.masterSkills.count
                case .UserType(let user):
                    return Int(user.masterSkills.count)
                }

            } else {
                return masterSkills.count
            }

        case ProfileSection.Learning.rawValue:

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    return discoveredUser.learningSkills.count
                case .UserType(let user):
                    return Int(user.learningSkills.count)
                }

            } else {
                return learningSkills.count
            }

        case ProfileSection.Footer.rawValue:
            return 1

        case ProfileSection.SeparationLine.rawValue:
            return 1
            
        case ProfileSection.SocialAccount.rawValue:
            return 3

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

            } else {
                cell.configureWithMyInfo()
            }

            return cell

        case ProfileSection.Master.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    let skill = discoveredUser.masterSkills[indexPath.item]
                    cell.skillLabel.text = skill.localName
                case .UserType(let user):
                    let userSkill = user.masterSkills[indexPath.item]
                    cell.skillLabel.text = userSkill.localName
                }

            } else {
                let skill = masterSkills[indexPath.item]
                cell.skillLabel.text = skill.localName
            }

            return cell

        case ProfileSection.Learning.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    let skill = discoveredUser.learningSkills[indexPath.item]
                    cell.skillLabel.text = skill.localName
                case .UserType(let user):
                    let userSkill = user.learningSkills[indexPath.item]
                    cell.skillLabel.text = userSkill.localName
                }

            } else {
                let skill = learningSkills[indexPath.item]
                cell.skillLabel.text = skill.localName
            }


            return cell

        case ProfileSection.Footer.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(footerCellIdentifier, forIndexPath: indexPath) as! ProfileFooterCell

            cell.introductionLabel.text = introductionText

            return cell

        case ProfileSection.SeparationLine.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(separationLineCellIdentifier, forIndexPath: indexPath) as! ProfileSeparationLineCell

            return cell
            
        case ProfileSection.SocialAccount.rawValue:
            
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(socialAccountCellIdentifier, forIndexPath: indexPath) as! ProfileSocialAccountCell
            
            if let socialAccount = SocialAccount(rawValue: indexPath.row) {
                cell.iconImageView.image = UIImage(named: socialAccount.iconName)
                cell.nameLabel.text = socialAccount.description
                cell.iconImageView.tintColor = socialAccount.tintColor
                cell.nameLabel.textColor = socialAccount.tintColor
            }
            
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
                header.titleLabel.text = NSLocalizedString("Master", comment: "")

            case ProfileSection.Learning.rawValue:
                header.titleLabel.text = NSLocalizedString("Learning", comment: "")

            default:
                header.titleLabel.text = ""
            }

            return header

        } else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionFooterIdentifier, forIndexPath: indexPath) as! UICollectionReusableView
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
            return UIEdgeInsets(top: 40, left: 0, bottom: 30, right: 0)

        case ProfileSection.SocialAccount.rawValue:
            return UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)

        default:
            return UIEdgeInsetsZero
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        switch indexPath.section {

        case ProfileSection.Header.rawValue:
            return CGSizeMake(collectionViewWidth, collectionViewWidth * profileAvatarAspectRatio)

        case ProfileSection.Master.rawValue:
            var skillLocalName = ""

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    skillLocalName = discoveredUser.masterSkills[indexPath.item].localName
                case .UserType(let user):
                    let userSkill = user.masterSkills[indexPath.item]
                    skillLocalName = userSkill.localName
                }

            } else {
                skillLocalName = masterSkills[indexPath.item].localName
            }

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: skillTextAttributes, context: nil)

            return CGSizeMake(rect.width + 24, SkillCell.height)

        case ProfileSection.Learning.rawValue:
            var skillLocalName = ""

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    skillLocalName = discoveredUser.learningSkills[indexPath.item].localName
                case .UserType(let user):
                    let userSkill = user.learningSkills[indexPath.item]
                    skillLocalName = userSkill.localName
                }

            } else {
                skillLocalName = learningSkills[indexPath.item].localName
            }

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: skillTextAttributes, context: nil)

            return CGSizeMake(rect.width + 24, SkillCell.height)

        case ProfileSection.Footer.rawValue:
            return CGSizeMake(collectionViewWidth, footerCellHeight)

        case ProfileSection.SeparationLine.rawValue:
            return CGSizeMake(collectionViewWidth, 1)
            
        case ProfileSection.SocialAccount.rawValue:
            return CGSizeMake(collectionViewWidth, 40)

        default:
            return CGSizeZero
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        if section == ProfileSection.Master.rawValue || section == ProfileSection.Learning.rawValue {
            return CGSizeMake(collectionViewWidth, 40)

        } else {
            return CGSizeMake(collectionViewWidth, 0)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSizeMake(collectionViewWidth, 0)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == ProfileSection.Learning.rawValue || indexPath.section == ProfileSection.Master.rawValue {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SkillCell
            
            self.performSegueWithIdentifier("showSkillHome", sender: cell)
            
        } else if indexPath.section == ProfileSection.SocialAccount.rawValue {

            performSegueWithIdentifier("presentOAuth", sender: indexPath.item)
        }

    }
}



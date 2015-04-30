//
//  ProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

let profileAvatarAspectRatio: CGFloat = 12.0 / 16.0

class ProfileViewController: UIViewController {

    var discoveredUser: DiscoveredUser?


    @IBOutlet weak var profileCollectionView: UICollectionView!

    @IBOutlet weak var sayHiView: UIView!
    @IBOutlet weak var sayHiButton: UIButton!


    let skillCellIdentifier = "SkillCell"
    let headerCellIdentifier = "ProfileHeaderCell"
    let footerCellIdentifier = "ProfileFooterCell"
    let sectionHeaderIdentifier = "ProfileSectionHeaderReusableView"
    let sectionFooterIdentifier = "ProfileSectionFooterReusableView"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.profileCollectionView.bounds)
        }()
    lazy var sectionLeftEdgeInset: CGFloat = { return 20 }()
    lazy var sectionRightEdgeInset: CGFloat = { return 20 }()
    lazy var sectionBottomEdgeInset: CGFloat = { return 15 }()

    let introductionText = "I would like to learn Design or Speech, I can teach you iOS Dev in return. 😃"

    var masterSkills = [Skill]()
    var learningSkills = [Skill]()

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextFont()]

    lazy var footerCellHeight: CGFloat = {
        let attributes = [NSFontAttributeName: profileIntroductionLabelFont]
        let labelWidth = self.collectionViewWidth - (profileIntroductionLabelLeadingSpaceToContainer + profileIntroductionLabelTrailingSpaceToContainer)
        let rect = self.introductionText.boundingRectWithSize(CGSize(width: labelWidth, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes:attributes, context:nil)
        return ceil(rect.height) + 4
        }()


    override func viewDidLoad() {
        super.viewDidLoad()

        profileCollectionView.registerNib(UINib(nibName: skillCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: headerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: headerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: footerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: footerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: sectionHeaderIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: sectionHeaderIdentifier)
        profileCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: sectionFooterIdentifier)

        profileCollectionView.alwaysBounceVertical = true
        
        automaticallyAdjustsScrollViewInsets = false

        if let tabBarController = tabBarController {
            profileCollectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGRectGetHeight(tabBarController.tabBar.bounds), right: 0)
        }

        if let discoveredUser = discoveredUser {
            self.navigationItem.title = discoveredUser.nickname

        } else {
            YepUserDefaults.nickname.bindAndFireListener("ProfileViewController.Title") { nickname in
                self.navigationItem.title = nickname
            }
        }

        if let discoveredUser = discoveredUser {
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
        
        if let navigationController = navigationController {
            navigationController.navigationBar.backgroundColor = UIColor.clearColor()
            navigationController.navigationBar.translucent = true
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.barStyle = UIBarStyle.BlackTranslucent
            navigationController.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
            
            let textAttributes = [
                NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: UIFont.navigationBarTitleFont()
            ]
            
            navigationController.navigationBar.titleTextAttributes = textAttributes
            navigationController.navigationBar.tintColor = UIColor.whiteColor()
        }

        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: Actions

    @IBAction func sayHi(sender: UIButton) {
        // TODO: sayHi
        println("sayHi")
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
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 4
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        switch section {

        case ProfileSection.Header.rawValue:
            return 1

        case ProfileSection.Master.rawValue:
            if let discoveredUser = discoveredUser {
                return discoveredUser.masterSkills.count

            } else {
                return masterSkills.count
            }

        case ProfileSection.Learning.rawValue:
            if let discoveredUser = discoveredUser {
                return discoveredUser.learningSkills.count

            } else {
                return learningSkills.count
            }

        case ProfileSection.Footer.rawValue:
            return 1

        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case ProfileSection.Header.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(headerCellIdentifier, forIndexPath: indexPath) as! ProfileHeaderCell

            if let discoveredUser = discoveredUser {
                cell.configureWithDiscoveredUser(discoveredUser)

            } else {
                cell.configureWithMyInfo()
            }

            return cell

        case ProfileSection.Master.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell

            if let discoveredUser = discoveredUser {
                let skill = discoveredUser.masterSkills[indexPath.item]
                cell.skillLabel.text = skill.localName

            } else {
                let skill = masterSkills[indexPath.item]
                cell.skillLabel.text = skill.localName
            }

            return cell

        case ProfileSection.Learning.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell

            if let discoveredUser = discoveredUser {
                let skill = discoveredUser.learningSkills[indexPath.item]
                cell.skillLabel.text = skill.localName

            } else {
                let skill = learningSkills[indexPath.item]
                cell.skillLabel.text = skill.localName
            }

            return cell

        case ProfileSection.Footer.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(footerCellIdentifier, forIndexPath: indexPath) as! ProfileFooterCell

            cell.introductionLabel.text = introductionText

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
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case ProfileSection.Learning.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case ProfileSection.Footer.rawValue:
            return UIEdgeInsets(top: 0, left: 0, bottom: sectionBottomEdgeInset, right: 0)

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

            if let discoveredUser = discoveredUser {
                skillLocalName = discoveredUser.masterSkills[indexPath.item].localName

            } else {
                skillLocalName = masterSkills[indexPath.item].localName
            }

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: skillTextAttributes, context: nil)

            return CGSizeMake(rect.width + 24, SkillCell.height)

        case ProfileSection.Learning.rawValue:
            var skillLocalName = ""

            if let discoveredUser = discoveredUser {
                skillLocalName = discoveredUser.learningSkills[indexPath.item].localName
                
            } else {
                skillLocalName = learningSkills[indexPath.item].localName
            }

            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: skillTextAttributes, context: nil)

            return CGSizeMake(rect.width + 24, SkillCell.height)

        case ProfileSection.Footer.rawValue:
            return CGSizeMake(collectionViewWidth, footerCellHeight)

        default:
            return CGSizeZero
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        if section == ProfileSection.Header.rawValue || section == ProfileSection.Footer.rawValue {
            return CGSizeMake(collectionViewWidth, 0)

        } else {
            return CGSizeMake(collectionViewWidth, 40)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSizeMake(collectionViewWidth, 0)
    }
}



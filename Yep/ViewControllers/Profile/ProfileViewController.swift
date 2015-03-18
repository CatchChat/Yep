//
//  ProfileViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

let skillRanckCellIdentifier = "SkillRankCell"
let headerCellIdentifier = "ProfileHeaderCell"
let footerCellIdentifier = "ProfileFooterCell"
let sectionHeaderIdentifier = "ProfileSectionHeaderReusableView"
let sectionFooterIdentifier = "ProfileSectionFooterReusableView"

let screenWidth = UIScreen.mainScreen().bounds.width
let sectionLeftEdgeInset: CGFloat = 20
let sectionRightEdgeInset = sectionLeftEdgeInset
let sectionBottomEdgeInset: CGFloat = 20
let cellWidth = (screenWidth - (sectionLeftEdgeInset + sectionRightEdgeInset)) / 3

let introductionText = "I would like to learn Design or Speech, I can teach you iOS Dev in return. 😃"


class ProfileViewController: UIViewController {

    @IBOutlet weak var profileCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        profileCollectionView.registerNib(UINib(nibName: skillRanckCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillRanckCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: headerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: headerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: footerCellIdentifier, bundle: nil), forCellWithReuseIdentifier: footerCellIdentifier)
        profileCollectionView.registerNib(UINib(nibName: sectionHeaderIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: sectionHeaderIdentifier)
        profileCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: sectionFooterIdentifier)

    }

}

extension ProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    enum ProfileSection: Int {
        case Header = 0
        case Master
        case Learning
        case Footer
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 4
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case ProfileSection.Header.rawValue:
            return 1
        case ProfileSection.Master.rawValue:
            return 5
        case ProfileSection.Learning.rawValue:
            return 2
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
            return cell
        case ProfileSection.Master.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillRanckCellIdentifier, forIndexPath: indexPath) as! SkillRankCell
            cell.rankView.barColor = UIColor.skillMasterColor()
            return cell
        case ProfileSection.Learning.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillRanckCellIdentifier, forIndexPath: indexPath) as! SkillRankCell
            cell.rankView.barColor = UIColor.skillLearningColor()
            return cell
        case ProfileSection.Footer.rawValue:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(footerCellIdentifier, forIndexPath: indexPath) as! ProfileFooterCell
            cell.introductionLabel.text = introductionText
            return cell
        default:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillRanckCellIdentifier, forIndexPath: indexPath) as! SkillRankCell
            return cell
        }
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: sectionHeaderIdentifier, forIndexPath: indexPath) as! ProfileSectionHeaderReusableView

            switch indexPath.section {
            case ProfileSection.Header.rawValue:
                header.titleLabel.text = ""
            case ProfileSection.Master.rawValue:
                header.titleLabel.text = NSLocalizedString("Master", comment: "")
            case ProfileSection.Learning.rawValue:
                header.titleLabel.text = NSLocalizedString("Learning", comment: "")
            case ProfileSection.Footer.rawValue:
                header.titleLabel.text = NSLocalizedString("Introduction", comment: "")
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
            return CGSizeMake(screenWidth, 250)
        case ProfileSection.Master.rawValue:
            return CGSizeMake(cellWidth, 40)
        case ProfileSection.Learning.rawValue:
            return CGSizeMake(cellWidth, 40)
        case ProfileSection.Footer.rawValue:

            let attributes = [NSFontAttributeName: UIFont(name: "HelveticaNeue-Thin", size: 12)!]
            let rect = introductionText.boundingRectWithSize(CGSize(width: screenWidth - 20*2, height: CGFloat(FLT_MAX)), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes:attributes, context:nil)

            return CGSizeMake(screenWidth, ceil(rect.height))
        default:
            return CGSizeMake(cellWidth, 40)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        if section == ProfileSection.Header.rawValue {
            return CGSizeMake(screenWidth, 0)
        } else {
            return CGSizeMake(screenWidth, 40)
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSizeMake(screenWidth, 0)
    }
}



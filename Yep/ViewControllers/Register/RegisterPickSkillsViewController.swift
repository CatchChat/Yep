//
//  RegisterPickSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterPickSkillsViewController: UIViewController {

    @IBOutlet weak var skillsCollectionView: UICollectionView!


    var masterSkills = [String]()
    var learningSkills = [String]()

    let skillCellIdentifier = "SkillCell"
    let addSkillsReusableViewIdentifier = "AddSkillsReusableView"

    let skillCellHeight: CGFloat = 24
    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextFont()]

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.skillsCollectionView.bounds)
        }()

    let sectionLeftEdgeInset: CGFloat = registerPickSkillsLayoutLeftEdgeInset
    let sectionRightEdgeInset: CGFloat = 20
    let sectionBottomEdgeInset: CGFloat = 50


    override func viewDidLoad() {
        super.viewDidLoad()

        skillsCollectionView.registerNib(UINib(nibName: addSkillsReusableViewIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: addSkillsReusableViewIdentifier)
        skillsCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
        skillsCollectionView.registerNib(UINib(nibName: skillCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCellIdentifier)

        masterSkills = ["Love", "Hate"]
        learningSkills = ["Fly", "Say goodbye", "Play hard", "Cry like a baby", "Eat slow", "Run"]
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension RegisterPickSkillsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    enum Section: Int {
        case Master = 0
        case Learning
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case Section.Master.rawValue:
            return masterSkills.count

        case Section.Learning.rawValue:
            return learningSkills.count

        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell

        switch indexPath.section {
        case Section.Master.rawValue:
            cell.skillLabel.text = masterSkills[indexPath.item]

        case Section.Learning.rawValue:
            cell.skillLabel.text = learningSkills[indexPath.item]

        default:
            break
        }

        return cell
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {

            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: addSkillsReusableViewIdentifier, forIndexPath: indexPath) as! AddSkillsReusableView

            switch indexPath.section {

            case Section.Master.rawValue:
                header.skillTypeLabel.text = NSLocalizedString("Master", comment: "")

            case Section.Learning.rawValue:
                header.skillTypeLabel.text = NSLocalizedString("Learning", comment: "")

            default:
                break
            }

            return header

        } else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) as! UICollectionReusableView
            return footer
        }
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        switch section {
        case Section.Master.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case Section.Learning.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        default:
            return UIEdgeInsetsZero
        }
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        var skillString = ""
        
        switch indexPath.section {
        case Section.Master.rawValue:
            skillString = masterSkills[indexPath.item]

        case Section.Learning.rawValue:
            skillString = learningSkills[indexPath.item]

        default:
            break
        }

        let rect = skillString.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: skillCellHeight), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: skillTextAttributes, context: nil)

        return CGSizeMake(rect.width + 24, skillCellHeight)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        return CGSizeMake(collectionViewWidth - (sectionLeftEdgeInset + sectionRightEdgeInset), 70)
    }
}



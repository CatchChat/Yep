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

    let skillCellHeight: CGFloat = 24
    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextFont()]

    override func viewDidLoad() {
        super.viewDidLoad()

        skillsCollectionView.registerNib(UINib(nibName: skillCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCellIdentifier)

        masterSkills = ["Love", "Hate", "Love", "Hate", "Love", "Hate", "Love", "Hate"]
        learningSkills = ["Fly", "Say Goodbye", "Fly", "Say Goodbye", "Fly", "Say Goodbye"]
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

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        switch section {
        case Section.Master.rawValue:
            return UIEdgeInsets(top: 100, left: 20, bottom: 50, right: 20)

        case Section.Learning.rawValue:
            return UIEdgeInsets(top: 0, left: 20, bottom: 50, right: 20)

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
}



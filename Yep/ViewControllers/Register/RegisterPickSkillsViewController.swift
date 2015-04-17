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


    var masterSkills: [String] = ["Love", "Hate"]
    var learningSkills: [String] = ["Fly", "Say goodbye", "Play hard"]

    let skillSelectionCellIdentifier = "SkillSelectionCell"
    let addSkillsReusableViewIdentifier = "AddSkillsReusableView"

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextLargeFont()]

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
        skillsCollectionView.registerNib(UINib(nibName: skillSelectionCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillSelectionCellIdentifier)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "presentSelectSkills" {
            let vc = segue.destinationViewController as! RegisterSelectSkillsViewController

            if let skillSetType = sender as? Int {
                switch skillSetType {
                case SkillSetType.Master.rawValue:
                    vc.annotationText = NSLocalizedString("What are you good at?", comment: "")
                    vc.selectedSkillsSet = Set(self.masterSkills)

                case SkillSetType.Learning.rawValue:
                    vc.annotationText = NSLocalizedString("What are you learning?", comment: "")
                    vc.selectedSkillsSet = Set(self.learningSkills)

                default:
                    break
                }

                vc.selectSkillAction = { (skill, selected) in

                    var success = false

                    switch skillSetType {
                    case SkillSetType.Master.rawValue:
                        if selected {
                            self.masterSkills.append(skill)

                            success = true
                            
                        } else {
                            for (index, masterSkill) in enumerate(self.masterSkills) {
                                if masterSkill == skill {
                                    self.masterSkills.removeAtIndex(index)

                                    success = true

                                    break
                                }
                            }
                        }

                    case SkillSetType.Learning.rawValue:
                        if selected {
                            self.learningSkills.append(skill)

                            success = true

                        } else {
                            for (index, learningSkill) in enumerate(self.learningSkills) {
                                if learningSkill == skill {
                                    self.learningSkills.removeAtIndex(index)

                                    success = true

                                    break
                                }
                            }
                        }

                    default:
                        break
                    }

                    self.skillsCollectionView.reloadData()

                    return success
                }
            }
        }
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

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillSelectionCellIdentifier, forIndexPath: indexPath) as! SkillSelectionCell

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
                header.skillSetType = .Master

            case Section.Learning.rawValue:
                header.skillSetType = .Learning

            default:
                break
            }

            header.addSkillsAction = { skillSetType in
                self.performSegueWithIdentifier("presentSelectSkills", sender: skillSetType.rawValue)
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

        let rect = skillString.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillSelectionCell.height), options: .UsesLineFragmentOrigin | .UsesFontLeading, attributes: skillTextAttributes, context: nil)

        return CGSizeMake(rect.width + 24, SkillSelectionCell.height)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        return CGSizeMake(collectionViewWidth - (sectionLeftEdgeInset + sectionRightEdgeInset), 70)
    }
}



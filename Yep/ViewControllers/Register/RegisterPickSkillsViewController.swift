//
//  RegisterPickSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterPickSkillsViewController: BaseViewController {

    var isRegister = true
    var afterChangeSkillsAction: ((masterSkills: [Skill], learningSkills: [Skill]) -> Void)?

    @IBOutlet weak var skillsCollectionView: UICollectionView!

    @IBOutlet weak var doneButton: UIButton!

    var masterSkills = [Skill]()
    var learningSkills = [Skill]()

    let skillSelectionCellIdentifier = "SkillSelectionCell"
    let addSkillsReusableViewIdentifier = "AddSkillsReusableView"

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextLargeFont()]

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.skillsCollectionView.bounds)
        }()

    let sectionLeftEdgeInset: CGFloat = registerPickSkillsLayoutLeftEdgeInset
    let sectionRightEdgeInset: CGFloat = 20
    let sectionBottomEdgeInset: CGFloat = 50

    var skillCategories: [SkillCategory]?

    lazy var selectSkillsTransitionManager = RegisterPickSkillsSelectSkillsTransitionManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        if !isRegister {
            doneButton.hidden = true

            let doneBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "saveSkills:")
            navigationItem.rightBarButtonItem = doneBarButton

            title = NSLocalizedString("Change Skills", comment: "")
        }

        skillsCollectionView.registerNib(UINib(nibName: addSkillsReusableViewIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: addSkillsReusableViewIdentifier)
        skillsCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
        skillsCollectionView.registerNib(UINib(nibName: skillSelectionCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillSelectionCellIdentifier)

        allSkillCategories(failureHandler: { (reason, errorMessage) -> Void in
            defaultFailureHandler(reason, errorMessage)
            
        }, completion: { skillCategories -> Void in
            self.skillCategories = skillCategories
        })

        //view.backgroundColor = UIColor.redColor()
        //skillsCollectionView.backgroundColor = UIColor.blueColor()
    }

    // MARK: Actions

    func updateSkillsCollectionView() {
        skillsCollectionView.reloadData()
    }

    @IBAction func saveSkills(sender: AnyObject) {

        let addSkillsGroup = dispatch_group_create()

        for skill in masterSkills {
            dispatch_group_enter(addSkillsGroup)

            addSkill(skill, toSkillSet: .Master, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)
                dispatch_group_leave(addSkillsGroup)

            }, completion: { success in
                dispatch_group_leave(addSkillsGroup)
            })
        }

        for skill in learningSkills {
            dispatch_group_enter(addSkillsGroup)

            addSkill(skill, toSkillSet: .Learning, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)
                dispatch_group_leave(addSkillsGroup)

            }, completion: { success in
                dispatch_group_leave(addSkillsGroup)
            })
        }

        dispatch_group_notify(addSkillsGroup, dispatch_get_main_queue()) {

            if self.isRegister {
                if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                    appDelegate.startMainStory()
                }

            } else {
                self.navigationController?.popViewControllerAnimated(true)

                self.afterChangeSkillsAction?(masterSkills: self.masterSkills, learningSkills: self.learningSkills)
            }
        }
    }

    // MARK: Navigaition

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "presentSelectSkills" {
            let vc = segue.destinationViewController as! RegisterSelectSkillsViewController

            vc.modalPresentationStyle = UIModalPresentationStyle.Custom
            vc.transitioningDelegate = selectSkillsTransitionManager

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

                if let skillCategories = skillCategories {
                    vc.skillCategories = skillCategories
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

                                    if !self.isRegister {
                                        deleteSkill(skill, fromSkillSet: .Master, failureHandler: nil, completion: { success in
                                            println("deleteSkill \(skill.localName) from Master: \(success)")
                                        })
                                    }

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

                                    if !self.isRegister {
                                        deleteSkill(skill, fromSkillSet: .Learning, failureHandler: nil, completion: { success in
                                            println("deleteSkill \(skill.localName) from Learning: \(success)")
                                        })
                                    }

                                    success = true

                                    break
                                }
                            }
                        }

                    default:
                        break
                    }

                    self.updateSkillsCollectionView()

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
            let skill = masterSkills[indexPath.item]
            cell.skillLabel.text = skill.localName

        case Section.Learning.rawValue:
            let skill = learningSkills[indexPath.item]
            cell.skillLabel.text = skill.localName

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
            let skill = masterSkills[indexPath.item]
            skillString = skill.localName

        case Section.Learning.rawValue:
            let skill = learningSkills[indexPath.item]
            skillString = skill.localName

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



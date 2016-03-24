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

    var isDirty = false {
        didSet {
            if !isRegister {
                let backBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancel")
                navigationItem.leftBarButtonItem = backBarButtonItem
            }

            navigationItem.rightBarButtonItem?.enabled = true
        }
    }

    
    @IBOutlet weak var introlLabel: UILabel!
    
    var afterChangeSkillsAction: ((masterSkills: [Skill], learningSkills: [Skill]) -> Void)?

    @IBOutlet weak var skillsCollectionView: UICollectionView!

    var masterSkills = [Skill]()
    var learningSkills = [Skill]()

    let skillSelectionCellIdentifier = "SkillSelectionCell"
    let skillAddCellIdentifier = "SkillAddCell"
    let addSkillsReusableViewIdentifier = "AddSkillsReusableView"

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextLargeFont()]

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.skillsCollectionView.bounds)
        }()

    let sectionLeftEdgeInset: CGFloat = registerPickSkillsLayoutLeftEdgeInset
    let sectionRightEdgeInset: CGFloat = registerPickSkillsLayoutRightEdgeInset
    let sectionBottomEdgeInset: CGFloat = 50

    var skillCategories: [SkillCategory]?

    lazy var selectSkillsTransitionManager = RegisterPickSkillsSelectSkillsTransitionManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "saveSkills:")
        navigationItem.rightBarButtonItem = doneBarButtonItem
        navigationItem.rightBarButtonItem?.enabled = false

        introlLabel.text = NSLocalizedString("You may meet different people and content depends on your skills", comment: "")
        
        if !isRegister {
            navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Change Skills", comment: ""))
        } else {
            navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Pick some skills", comment: ""))
        }


        skillsCollectionView.registerNib(UINib(nibName: addSkillsReusableViewIdentifier, bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: addSkillsReusableViewIdentifier)
        skillsCollectionView.registerClass(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "footer")
        skillsCollectionView.registerNib(UINib(nibName: skillSelectionCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillSelectionCellIdentifier)
        skillsCollectionView.registerNib(UINib(nibName: skillAddCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillAddCellIdentifier)

        allSkillCategories(failureHandler: { (reason, errorMessage) -> Void in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
            
        }, completion: { skillCategories -> Void in
            self.skillCategories = skillCategories
        })
    }

    // MARK: Actions

    func updateSkillsCollectionView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.skillsCollectionView.reloadData()
        }
    }

    func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }

    @IBAction func saveSkills(sender: AnyObject) {
        doSaveSkills()
    }

    func doSaveSkills() {

        YepHUD.showActivityIndicator()

        var saveSkillsErrorMessage: String?

        let addSkillsGroup = dispatch_group_create()

        for skill in masterSkills {
            dispatch_group_enter(addSkillsGroup)

            addSkill(skill, toSkillSet: .Master, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                saveSkillsErrorMessage = errorMessage

                dispatch_group_leave(addSkillsGroup)

            }, completion: { success in
                dispatch_group_leave(addSkillsGroup)
            })
        }

        for skill in learningSkills {
            dispatch_group_enter(addSkillsGroup)

            addSkill(skill, toSkillSet: .Learning, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                saveSkillsErrorMessage = errorMessage

                dispatch_group_leave(addSkillsGroup)

            }, completion: { success in
                dispatch_group_leave(addSkillsGroup)
            })
        }

        dispatch_group_notify(addSkillsGroup, dispatch_get_main_queue()) {

            if self.isRegister {
                // 同步一下我的信息，因为 appDelegate.sync() 执行太早，导致初次注册 Profile 里不显示 skills
                syncMyInfoAndDoFurtherAction {

                    YepHUD.hideActivityIndicator()

                    dispatch_async(dispatch_get_main_queue()) {
                        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                            appDelegate.startMainStory()
                        }
                    }
                }

            } else {
                YepHUD.hideActivityIndicator()

                if let errorMessage = saveSkillsErrorMessage {
                    YepAlert.alertSorry(message: errorMessage, inViewController: self)

                } else {
                    self.navigationController?.popViewControllerAnimated(true)

                    self.afterChangeSkillsAction?(masterSkills: self.masterSkills, learningSkills: self.learningSkills)
                }
            }
        }
    }

    // MARK: Navigaition

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "presentSelectSkills" {

            let vc = segue.destinationViewController as! RegisterSelectSkillsViewController

            vc.modalPresentationStyle = UIModalPresentationStyle.Custom
            vc.transitioningDelegate = selectSkillsTransitionManager

            if let skillSetRawValue = sender as? Int, skillSet = SkillSet(rawValue: skillSetRawValue) {

                vc.annotationText = skillSet.annotationText
                vc.failedSelectSkillMessage = skillSet.failedSelectSkillMessage

                switch skillSet {
                case .Master:
                    vc.selectedSkillsSet = Set(masterSkills)
                    vc.anotherSelectedSkillsSet = Set(learningSkills)
                case .Learning:
                    vc.selectedSkillsSet = Set(learningSkills)
                    vc.anotherSelectedSkillsSet = Set(masterSkills)
                }

                if let skillCategories = skillCategories {
                    vc.skillCategories = skillCategories
                }

                vc.selectSkillAction = { [weak self] skill, selected in

                    var success = false

                    if let strongSelf = self {

                        switch skillSet {

                        case .Master:

                            if selected {

                                if strongSelf.learningSkills.filter({ $0.id == skill.id }).count == 0 {

                                    strongSelf.masterSkills.append(skill)

                                    success = true
                                }
                                
                            } else {

                                let skillsToDelete = strongSelf.masterSkills.filter({ $0.id == skill.id })

                                if skillsToDelete.count > 0 {

                                    for skill in skillsToDelete {

                                        if !strongSelf.isRegister {
                                            deleteSkill(skill, fromSkillSet: .Master, failureHandler: nil, completion: { success in
                                                println("deleteSkill \(skill.localName) from Master: \(success)")
                                            })
                                        }
                                    }

                                    strongSelf.masterSkills = strongSelf.masterSkills.filter({ $0.id != skill.id })
                                    
                                    success = true
                                }
                            }

                        case .Learning:

                            if selected {
                                if strongSelf.masterSkills.filter({ $0.id == skill.id }).count == 0 {

                                    strongSelf.learningSkills.append(skill)

                                    success = true
                                }

                            } else {

                                let skillsToDelete = strongSelf.learningSkills.filter({ $0.id == skill.id })

                                if skillsToDelete.count > 0 {

                                    for skill in skillsToDelete {

                                        if !strongSelf.isRegister {
                                            deleteSkill(skill, fromSkillSet: .Learning, failureHandler: nil, completion: { success in
                                                println("deleteSkill \(skill.localName) from Learning: \(success)")
                                            })
                                        }
                                    }

                                    strongSelf.learningSkills = strongSelf.learningSkills.filter({ $0.id != skill.id })

                                    success = true
                                }
                            }
                        }

                        strongSelf.updateSkillsCollectionView()

                        if !strongSelf.isDirty {
                            strongSelf.isDirty = success
                        }
                    }

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
            return masterSkills.count + 1

        case Section.Learning.rawValue:
            return learningSkills.count + 1

        default:
            return 0
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        switch indexPath.section {

        case Section.Master.rawValue:

            if indexPath.item < masterSkills.count {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillSelectionCellIdentifier, forIndexPath: indexPath) as! SkillSelectionCell

                let skill = masterSkills[indexPath.item]

                cell.skillLabel.text = skill.localName

                return cell

            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillAddCellIdentifier, forIndexPath: indexPath) as! SkillAddCell

                cell.skillSet = .Master

                cell.addSkillsAction = { [weak self] skillSet in

                    if let _ = self?.skillCategories {
                        self?.performSegueWithIdentifier("presentSelectSkills", sender: skillSet.rawValue)

                    } else {
                        allSkillCategories(failureHandler: { (reason, errorMessage) -> Void in
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        }, completion: { skillCategories -> Void in
                            self?.skillCategories = skillCategories
                        })
                    }
                }

                return cell
            }

        case Section.Learning.rawValue:
            if indexPath.item < learningSkills.count {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillSelectionCellIdentifier, forIndexPath: indexPath) as! SkillSelectionCell

                let skill = learningSkills[indexPath.item]

                cell.skillLabel.text = skill.localName

                return cell

            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillAddCellIdentifier, forIndexPath: indexPath) as! SkillAddCell

                cell.skillSet = .Learning

                cell.addSkillsAction = { [weak self] skillSet in

                    if let _ = self?.skillCategories {
                        self?.performSegueWithIdentifier("presentSelectSkills", sender: skillSet.rawValue)

                    } else {
                        allSkillCategories(failureHandler: { (reason, errorMessage) -> Void in
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                        }, completion: { skillCategories -> Void in
                            self?.skillCategories = skillCategories
                        })
                    }
                }

                return cell
            }

        default:
            return UICollectionViewCell()
        }
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {

            let header = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: addSkillsReusableViewIdentifier, forIndexPath: indexPath) as! AddSkillsReusableView

            switch indexPath.section {

            case Section.Master.rawValue:
                header.skillSet = .Master

            case Section.Learning.rawValue:
                header.skillSet = .Learning

            default:
                break
            }

            return header

        } else {
            let footer = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) 
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
            if indexPath.item < masterSkills.count {
                let skill = masterSkills[indexPath.item]
                skillString = skill.localName

            } else {
                return CGSize(width: SkillSelectionCell.height, height: SkillSelectionCell.height)
            }

        case Section.Learning.rawValue:
            if indexPath.item < learningSkills.count {
                let skill = learningSkills[indexPath.item]
                skillString = skill.localName

            } else {
                return CGSize(width: SkillSelectionCell.height, height: SkillSelectionCell.height)
            }

        default:
            break
        }

        let rect = skillString.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillSelectionCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)

        return CGSize(width: rect.width + 24, height: SkillSelectionCell.height)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        return CGSizeMake(collectionViewWidth - (sectionLeftEdgeInset + sectionRightEdgeInset), 70)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {

        case Section.Master.rawValue:
            if indexPath.item == masterSkills.count {
                if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? SkillAddCell {
                    cell.addSkillsAction?(cell.skillSet)
                }
            }

        case Section.Learning.rawValue:
            if indexPath.item == learningSkills.count {
                if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? SkillAddCell {
                    cell.addSkillsAction?(cell.skillSet)
                }
            }

        default:
            break
        }
    }
}



//
//  RegisterPickSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepNetworking

final class RegisterPickSkillsViewController: BaseViewController {

    var isRegister = true

    var isDirty = false {
        didSet {
            if !isRegister {
                let backBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(RegisterPickSkillsViewController.cancel))
                navigationItem.leftBarButtonItem = backBarButtonItem
            }

            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }

    @IBOutlet weak var introlLabel: UILabel!
    
    var afterChangeSkillsAction: ((_ masterSkills: [Skill], _ learningSkills: [Skill]) -> Void)?

    @IBOutlet weak var skillsCollectionView: UICollectionView!

    var masterSkills = [Skill]()
    var learningSkills = [Skill]()

    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextLargeFont()]

    lazy var collectionViewWidth: CGFloat = {
        return self.skillsCollectionView.bounds.width
    }()

    let sectionLeftEdgeInset: CGFloat = registerPickSkillsLayoutLeftEdgeInset
    let sectionRightEdgeInset: CGFloat = registerPickSkillsLayoutRightEdgeInset
    let sectionBottomEdgeInset: CGFloat = 50

    var skillCategories: [SkillCategory]?

    lazy var selectSkillsTransitionManager = RegisterPickSkillsSelectSkillsTransitionManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(RegisterPickSkillsViewController.saveSkills(_:)))
        navigationItem.rightBarButtonItem = doneBarButtonItem
        navigationItem.rightBarButtonItem?.isEnabled = false

        introlLabel.text = NSLocalizedString("You may meet different people and content depends on your skills", comment: "")
        
        if !isRegister {
            navigationItem.titleView = NavigationTitleLabel(title: String.trans_titleChangeSkills)
        } else {
            navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Pick some skills", comment: ""))
        }

        skillsCollectionView.registerNibOf(SkillSelectionCell)
        skillsCollectionView.registerNibOf(SkillAddCell)

        skillsCollectionView.registerHeaderNibOf(AddSkillsReusableView)
        skillsCollectionView.registerFooterClassOf(UICollectionReusableView)

        allSkillCategories(failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)
            
        }, completion: { [weak self] skillCategories in
            self?.skillCategories = skillCategories
        })
    }

    // MARK: Actions

    func updateSkillsCollectionView() {
        SafeDispatch.async { [weak self] in
            self?.skillsCollectionView.reloadData()
        }
    }

    @objc fileprivate func cancel() {
        navigationController?.popViewController(animated: true)
    }

    @objc fileprivate func saveSkills(_ sender: AnyObject) {
        doSaveSkills()
    }

    func doSaveSkills() {

        YepHUD.showActivityIndicator()

        var saveSkillsErrorMessage: String?

        let addSkillsGroup = DispatchGroup()

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

        addSkillsGroup.notify(queue: DispatchQueue.main) { [weak self] in

            guard let strongSelf = self else { return }

            if strongSelf.isRegister {

                sharedStore().dispatch(MobilePhoneUpdateAction(mobilePhone: nil))

                // 同步一下我的信息，因为 appDelegate.sync() 执行太早，导致初次注册 Profile 里不显示 skills
                syncMyInfoAndDoFurtherAction {

                    YepHUD.hideActivityIndicator()

                    SafeDispatch.async {
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
                    strongSelf.navigationController?.popViewController(animated: true)

                    strongSelf.afterChangeSkillsAction?(masterSkills: strongSelf.masterSkills, learningSkills: strongSelf.learningSkills)
                }
            }
        }
    }

    // MARK: Navigaition

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "presentSelectSkills" {

            let vc = segue.destination as! RegisterSelectSkillsViewController

            vc.modalPresentationStyle = UIModalPresentationStyle.custom
            vc.transitioningDelegate = selectSkillsTransitionManager

            if let skillSetRawValue = sender as? Int, let skillSet = SkillSet(rawValue: skillSetRawValue) {

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
        case master = 0
        case learning
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {

        case Section.master.rawValue:
            return masterSkills.count + 1

        case Section.learning.rawValue:
            return learningSkills.count + 1

        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch (indexPath as NSIndexPath).section {

        case Section.master.rawValue:

            if indexPath.item < masterSkills.count {
                let cell: SkillSelectionCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                let skill = masterSkills[indexPath.item]

                cell.skillLabel.text = skill.localName

                return cell

            } else {
                let cell: SkillAddCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

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

        case Section.learning.rawValue:
            if indexPath.item < learningSkills.count {
                let cell: SkillSelectionCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                let skill = learningSkills[indexPath.item]

                cell.skillLabel.text = skill.localName

                return cell

            } else {
                let cell: SkillAddCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

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

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionElementKindSectionHeader {

            let header: AddSkillsReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, forIndexPath: indexPath)

            switch (indexPath as NSIndexPath).section {

            case Section.master.rawValue:
                header.skillSet = .Master

            case Section.learning.rawValue:
                header.skillSet = .Learning

            default:
                break
            }

            return header

        } else {
            let footer: UICollectionReusableView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, forIndexPath: indexPath)
            return footer
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        switch section {
            
        case Section.master.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        case Section.learning.rawValue:
            return UIEdgeInsets(top: 0, left: sectionLeftEdgeInset, bottom: sectionBottomEdgeInset, right: sectionRightEdgeInset)

        default:
            return UIEdgeInsets.zero
        }
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {

        var skillString = ""
        
        switch indexPath.section {

        case Section.master.rawValue:
            if indexPath.item < masterSkills.count {
                let skill = masterSkills[indexPath.item]
                skillString = skill.localName

            } else {
                return CGSize(width: SkillSelectionCell.height, height: SkillSelectionCell.height)
            }

        case Section.learning.rawValue:
            if indexPath.item < learningSkills.count {
                let skill = learningSkills[indexPath.item]
                skillString = skill.localName

            } else {
                return CGSize(width: SkillSelectionCell.height, height: SkillSelectionCell.height)
            }

        default:
            break
        }

        let rect = skillString.boundingRect(with: CGSize(width: CGFloat(FLT_MAX), height: SkillSelectionCell.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: skillTextAttributes, context: nil)

        return CGSize(width: rect.width + 24, height: SkillSelectionCell.height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {

        return CGSize(width: collectionViewWidth - (sectionLeftEdgeInset + sectionRightEdgeInset), height: 70)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).section {

        case Section.master.rawValue:
            if indexPath.item == masterSkills.count {
                if let cell = collectionView.cellForItem(at: indexPath) as? SkillAddCell {
                    cell.addSkillsAction?(cell.skillSet)
                }
            }

        case Section.learning.rawValue:
            if indexPath.item == learningSkills.count {
                if let cell = collectionView.cellForItem(at: indexPath) as? SkillAddCell {
                    cell.addSkillsAction?(cell.skillSet)
                }
            }

        default:
            break
        }
    }
}


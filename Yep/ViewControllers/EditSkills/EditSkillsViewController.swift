//
//  EditSkillsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/10.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler
import RealmSwift

class EditSkillsViewController: BaseViewController {

    var skillSet: SkillSet?
    var afterChangedSkillsAction: (() -> Void)?

    private var realm: Realm!
    private var me: User?

    @IBOutlet private weak var skillsTableView: UITableView!

    @IBOutlet private weak var addSkillsView: BottomButtonView!

    private lazy var selectSkillsTransitionManager = RegisterPickSkillsSelectSkillsTransitionManager()

    private var masterSkills = [Skill]()
    private var learningSkills = [Skill]()

    private var skillCategories: [SkillCategory]?

    private let editSkillCellID = "EditSkillCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //animatedOnNavigationBar = false

        title = skillSet?.name
        // get all skill categories

        allSkillCategories(failureHandler: { (reason, errorMessage) -> Void in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

        }, completion: { skillCategories -> Void in
            self.skillCategories = skillCategories
        })

        // table view

        var contentInset = skillsTableView.contentInset
        contentInset.bottom = addSkillsView.frame.height
        skillsTableView.contentInset = contentInset

        skillsTableView.rowHeight = 60

        var separatorInset = skillsTableView.separatorInset
        separatorInset.left = Ruler.iPhoneHorizontal(15, 20, 25).value
        skillsTableView.separatorInset = separatorInset

        skillsTableView.registerNib(UINib(nibName: editSkillCellID, bundle: nil), forCellReuseIdentifier: editSkillCellID)

        // add skills view

        addSkillsView.title = NSLocalizedString("Add Skills", comment: "")

        addSkillsView.tapAction = { [weak self] in

            if self?.skillCategories == nil {
                return
            }

            let storyboard = UIStoryboard(name: "Intro", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("RegisterSelectSkillsViewController") as! RegisterSelectSkillsViewController

            vc.modalPresentationStyle = UIModalPresentationStyle.Custom
            vc.transitioningDelegate = self?.selectSkillsTransitionManager

            if let strongSelf = self, me = strongSelf.me, skillSet = strongSelf.skillSet {

                strongSelf.masterSkills = skillsFromUserSkillList(me.masterSkills)
                strongSelf.learningSkills = skillsFromUserSkillList(me.learningSkills)

                vc.annotationText = skillSet.annotationText
                vc.failedSelectSkillMessage = skillSet.failedSelectSkillMessage

                switch skillSet {
                case .Master:
                    vc.selectedSkillsSet = Set(strongSelf.masterSkills)
                    vc.anotherSelectedSkillsSet = Set(strongSelf.learningSkills)
                case .Learning:
                    vc.selectedSkillsSet = Set(strongSelf.learningSkills)
                    vc.anotherSelectedSkillsSet = Set(strongSelf.masterSkills)
                }

                if let skillCategories = self?.skillCategories {
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

                                    addSkill(skill, toSkillSet: .Master, failureHandler: nil, completion: { _ in })

                                    success = true
                                }

                            } else {

                                let skillsToDelete = strongSelf.masterSkills.filter({ $0.id == skill.id })

                                if skillsToDelete.count > 0 {

                                    for skill in skillsToDelete {

                                        guard let realm = try? Realm() else {
                                            return success
                                        }

                                        if let userSkill = userSkillWithSkillID(skill.id, inRealm: realm) {
                                            let _ = try? realm.write {
                                                realm.delete(userSkill)
                                            }
                                        }

                                        deleteSkill(skill, fromSkillSet: .Master, failureHandler: nil, completion: { success in
                                            println("deleteSkill \(skill.localName) from Master: \(success)")
                                        })
                                    }

                                    strongSelf.masterSkills = strongSelf.masterSkills.filter({ $0.id != skill.id })

                                    success = true
                                }
                            }

                        case .Learning:

                            if selected {
                                if strongSelf.masterSkills.filter({ $0.id == skill.id }).count == 0 {

                                    strongSelf.learningSkills.append(skill)

                                    addSkill(skill, toSkillSet: .Learning, failureHandler: nil, completion: { _ in })

                                    success = true
                                }

                            } else {

                                let skillsToDelete = strongSelf.learningSkills.filter({ $0.id == skill.id })

                                if skillsToDelete.count > 0 {

                                    for skill in skillsToDelete {

                                        guard let realm = try? Realm() else {
                                            return success
                                        }

                                        if let userSkill = userSkillWithSkillID(skill.id, inRealm: realm) {
                                            let _ = try? realm.write {
                                                realm.delete(userSkill)
                                            }
                                        }

                                        deleteSkill(skill, fromSkillSet: .Learning, failureHandler: nil, completion: { success in
                                            println("deleteSkill \(skill.localName) from Learning: \(success)")
                                        })
                                    }
                                    
                                    strongSelf.learningSkills = strongSelf.learningSkills.filter({ $0.id != skill.id })
                                    
                                    success = true
                                }
                            }
                        }

                        strongSelf.updateSkillsTableView()
                        strongSelf.afterChangedSkillsAction?()
                    }
                    
                    return success
                }
            }

            vc.syncSkillsFromServerAction = { [weak self] in
                syncMyInfoAndDoFurtherAction {
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.updateSkillsTableView()
                        self?.afterChangedSkillsAction?()
                    }
                }
            }

            self?.navigationController?.presentViewController(vc, animated: true, completion: nil)
        }

        // prepare realm & me

        realm = try! Realm()

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {
                self.me = me
        }
    }

    // MARK: Actions

    private func updateSkillsTableView() {
        skillsTableView.reloadData()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension EditSkillsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let me = me, skillSet = skillSet {
            switch skillSet {
            case .Master:
                return me.masterSkills.count
            case .Learning:
                return me.learningSkills.count
            }
        }

        return 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(editSkillCellID) as! EditSkillCell

        var userSkill: UserSkill?
        if let me = me, skillSet = skillSet {
            switch skillSet {
            case .Master:
                userSkill = me.masterSkills[indexPath.row]
            case .Learning:
                userSkill = me.learningSkills[indexPath.row]
            }
        }

        cell.userSkill = userSkill

        cell.removeSkillAction = { [weak self] cell, userSkill in

            if let me = self?.me, skillSet = self?.skillSet {

                // delete from Server

                let skillLocalName = userSkill.localName

                deleteSkillWithID(userSkill.skillID, fromSkillSet: skillSet, failureHandler: nil, completion: { success in
                    println("deleteSkill \(skillLocalName) from \(skillSet.name): \(success)")
                })

                // 不能直接捕捉 indexPath，不然删除一个后，再删除后面的 Skill 时 indexPath 就不对了
                var rowToDelete: Int?
                switch skillSet {
                case .Master:
                    rowToDelete = me.masterSkills.indexOf(userSkill)
                case .Learning:
                    rowToDelete = me.learningSkills.indexOf(userSkill)
                }

                // delete from local

                let _ = try? self?.realm.write {
                    self?.realm.delete(userSkill)

                    // 防止连续点击时 Realm 出错
                    cell.userSkill = nil
                }

                if let rowToDelete = rowToDelete {
                    let indexPathToDelete = NSIndexPath(forRow: rowToDelete, inSection: 0)
                    self?.skillsTableView.deleteRowsAtIndexPaths([indexPathToDelete], withRowAnimation: .Automatic)
                }

                // update Profile's UI

                self?.afterChangedSkillsAction?()
            }
        }

        return cell
    }
}


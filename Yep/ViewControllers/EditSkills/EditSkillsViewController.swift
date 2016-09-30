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
import YepKit

final class EditSkillsViewController: BaseViewController {

    var skillSet: SkillSet?
    var afterChangedSkillsAction: (() -> Void)?

    fileprivate var realm: Realm!
    fileprivate var me: User?

    @IBOutlet fileprivate weak var skillsTableView: UITableView!

    @IBOutlet fileprivate weak var addSkillsView: BottomButtonView!

    fileprivate lazy var selectSkillsTransitionManager = RegisterPickSkillsSelectSkillsTransitionManager()

    fileprivate var masterSkills = [Skill]()
    fileprivate var learningSkills = [Skill]()

    fileprivate var skillCategories: [SkillCategory]?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = skillSet?.name

        // get all skill categories

        allSkillCategories(failureHandler: nil, completion: { [weak self] skillCategories in
            self?.skillCategories = skillCategories
        })

        // table view

        var contentInset = skillsTableView.contentInset
        contentInset.bottom = addSkillsView.frame.height
        skillsTableView.contentInset = contentInset

        skillsTableView.rowHeight = 60

        var separatorInset = skillsTableView.separatorInset
        separatorInset.left = Ruler.iPhoneHorizontal(15, 20, 25).value
        skillsTableView.separatorInset = separatorInset

        skillsTableView.registerNibOf(EditSkillCell.self)

        // add skills view

        addSkillsView.title = NSLocalizedString("title.add_skills", comment: "")

        addSkillsView.tapAction = { [weak self] in

            if self?.skillCategories == nil {
                return
            }

            let vc = UIStoryboard.Scene.registerSelectSkills

            vc.modalPresentationStyle = .custom
            vc.transitioningDelegate = self?.selectSkillsTransitionManager

            if let strongSelf = self, let me = strongSelf.me, let skillSet = strongSelf.skillSet {

                strongSelf.masterSkills = skillsFromUserSkillList(me.masterSkills)
                strongSelf.learningSkills = skillsFromUserSkillList(me.learningSkills)

                vc.annotationText = skillSet.annotationText
                vc.failedSelectSkillMessage = skillSet.failedSelectSkillMessage

                switch skillSet {
                case .master:
                    vc.selectedSkillsSet = Set(strongSelf.masterSkills)
                    vc.anotherSelectedSkillsSet = Set(strongSelf.learningSkills)
                case .learning:
                    vc.selectedSkillsSet = Set(strongSelf.learningSkills)
                    vc.anotherSelectedSkillsSet = Set(strongSelf.masterSkills)
                }

                if let skillCategories = self?.skillCategories {
                    vc.skillCategories = skillCategories
                }

                vc.selectSkillAction = { [weak self] skill, selected in

                    guard let strongSelf = self else {
                        return false
                    }

                    var success = false

                    switch skillSet {

                    case .master:

                        if selected {

                            if strongSelf.learningSkills.filter({ $0.id == skill.id }).count == 0 {

                                strongSelf.masterSkills.append(skill)

                                addSkill(skill, toSkillSet: .master, failureHandler: nil, completion: { _ in })

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

                                    deleteSkill(skill, fromSkillSet: .master, failureHandler: nil, completion: { success in
                                        println("deleteSkill \(skill.localName) from Master: \(success)")
                                    })
                                }

                                strongSelf.masterSkills = strongSelf.masterSkills.filter({ $0.id != skill.id })

                                success = true
                            }
                        }

                    case .learning:

                        if selected {
                            if strongSelf.masterSkills.filter({ $0.id == skill.id }).count == 0 {

                                strongSelf.learningSkills.append(skill)

                                addSkill(skill, toSkillSet: .learning, failureHandler: nil, completion: { _ in })

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

                                    deleteSkill(skill, fromSkillSet: .learning, failureHandler: nil, completion: { success in
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

                    return success
                }
            }

            vc.syncSkillsFromServerAction = {
                syncMyInfoAndDoFurtherAction {
                    SafeDispatch.async { [weak self] in
                        self?.updateSkillsTableView()
                        self?.afterChangedSkillsAction?()
                    }
                }
            }

            self?.navigationController?.present(vc, animated: true, completion: nil)
        }

        // prepare realm & me

        realm = try! Realm()

        self.me = meInRealm(realm)
    }

    // MARK: Actions

    fileprivate func updateSkillsTableView() {

        SafeDispatch.async { [weak self] in
            self?.skillsTableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension EditSkillsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if let me = me, let skillSet = skillSet {
            switch skillSet {
            case .master:
                return me.masterSkills.count
            case .learning:
                return me.learningSkills.count
            }
        }

        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: EditSkillCell = tableView.dequeueReusableCell()

        var userSkill: UserSkill?
        if let me = me, let skillSet = skillSet {
            switch skillSet {
            case .master:
                userSkill = me.masterSkills[indexPath.row]
            case .learning:
                userSkill = me.learningSkills[indexPath.row]
            }
        }

        cell.userSkill = userSkill

        cell.removeSkillAction = { [weak self] cell, userSkill in

            if let me = self?.me, let skillSet = self?.skillSet {

                // delete from Server

                let skillLocalName = userSkill.localName

                deleteSkillWithID(userSkill.skillID, fromSkillSet: skillSet, failureHandler: nil, completion: { success in
                    println("deleteSkill \(skillLocalName) from \(skillSet.name): \(success)")
                })

                // 不能直接捕捉 indexPath，不然删除一个后，再删除后面的 Skill 时 indexPath 就不对了
                var rowToDelete: Int?
                switch skillSet {
                case .master:
                    rowToDelete = me.masterSkills.index(of: userSkill)
                case .learning:
                    rowToDelete = me.learningSkills.index(of: userSkill)
                }

                // delete from local

                let _ = try? self?.realm.write {
                    self?.realm.delete(userSkill)

                    // 防止连续点击时 Realm 出错
                    cell.userSkill = nil
                }

                if let rowToDelete = rowToDelete {
                    let indexPathToDelete = IndexPath(row: rowToDelete, section: 0)
                    self?.skillsTableView.deleteRows(at: [indexPathToDelete], with: .automatic)
                }

                // update Profile's UI

                self?.afterChangedSkillsAction?()
            }
        }

        return cell
    }
}


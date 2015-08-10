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

    var realm: Realm!
    var me: User?

    @IBOutlet weak var skillsTableView: UITableView!

    @IBOutlet weak var addSkillsView: BottomButtonView!


    let editSkillCellID = "EditSkillCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        animatedOnNavigationBar = false

        title = NSLocalizedString("Edit Skills", comment: "")

        var contentInset = skillsTableView.contentInset
        contentInset.bottom = addSkillsView.frame.height
        skillsTableView.contentInset = contentInset

        skillsTableView.rowHeight = 60

        var separatorInset = skillsTableView.separatorInset
        separatorInset.left = Ruler.match(.iPhoneWidths(15, 20, 25))
        skillsTableView.separatorInset = separatorInset

        skillsTableView.registerNib(UINib(nibName: editSkillCellID, bundle: nil), forCellReuseIdentifier: editSkillCellID)


        addSkillsView.title = NSLocalizedString("Add Skills", comment: "")


        realm = Realm()

        if let
            myUserID = YepUserDefaults.userID.value,
            me = userWithUserID(myUserID, inRealm: realm) {
                self.me = me
        }
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

        cell.removeSkillAction = { [weak self] userSkill in

            if let me = self?.me, skillSet = self?.skillSet {

                // delete from Server

                let skillLocalName = userSkill.localName

                deleteSkillWithID(userSkill.skillID, fromSkillSet: skillSet, failureHandler: nil, completion: { success in
                    println("deleteSkill \(skillLocalName) from \(skillSet): \(success)")
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

                self?.realm.write {
                    self?.realm.delete(userSkill)
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


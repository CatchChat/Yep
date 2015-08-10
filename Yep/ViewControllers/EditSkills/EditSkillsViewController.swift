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

    var skillSetType: SkillHomeState?
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

        if let me = me, skillSetType = skillSetType {
            switch skillSetType {
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
        if let me = me, skillSetType = skillSetType {
            switch skillSetType {
            case .Master:
                userSkill = me.masterSkills[indexPath.row]
            case .Learning:
                userSkill = me.learningSkills[indexPath.row]
            }
        }

        cell.skillLabel.text = userSkill?.localName

        cell.removeSkillAction = { [weak self] in

            if let me = self?.me, skillSetType = self?.skillSetType {

                let userSkill: UserSkill

                switch skillSetType {
                case .Master:
                    userSkill = me.masterSkills[indexPath.row]

                case .Learning:
                    userSkill = me.learningSkills[indexPath.row]
                }

                self?.realm.write {
                    self?.realm.delete(userSkill)
                }

                self?.skillsTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)

                self?.afterChangedSkillsAction?()

                // TODO: server
            }
        }

        return cell
    }
}


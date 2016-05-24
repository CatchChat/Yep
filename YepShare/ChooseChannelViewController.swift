//
//  ChooseChannelViewController.swift
//  Yep
//
//  Created by NIX on 16/5/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

class ChooseChannelViewController: UITableViewController {

    var pickedSkillAction: ((skill: Skill) -> Void)?

    private let skills: [Skill] = {
        if let
            myUserID = YepUserDefaults.userID.value,
            realm = try? Realm(),
            me = userWithUserID(myUserID, inRealm: realm) {

            let skills = skillsFromUserSkillList(me.masterSkills) + skillsFromUserSkillList(me.learningSkills)

            return skills
        }

        return []
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Choose Channel"

        tableView.tableFooterView = UIView()
    }

    // MARK: - Actions

    @IBAction func cancel(sender: UIBarButtonItem) {

        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func done(sender: UIBarButtonItem) {

        if let indexPath = tableView.indexPathForSelectedRow {
            let skill = skills[indexPath.row]
            pickedSkillAction?(skill: skill)
        }

        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return skills.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("ChannelCell", forIndexPath: indexPath)
        let skill = skills[indexPath.row]
        cell.textLabel?.text = skill.localName
        return cell
    }
}


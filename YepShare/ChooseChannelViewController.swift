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

    @IBOutlet weak var doneButton: UIBarButtonItem! {
        didSet {
            doneButton.enabled = false
        }
    }

    private lazy var selectedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 50/255.0, green: 167/255.0, blue: 255/255.0, alpha: 1.0)
        return view
    }()

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

        title = NSLocalizedString("Choose Channel", comment: "") 

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
        cell.selectedBackgroundView = selectedBackgroundView
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        doneButton.enabled = true
    }
}


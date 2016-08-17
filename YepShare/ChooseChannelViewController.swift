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

    var currentPickedSkill: Skill?

    var pickedSkillAction: ((skill: Skill?) -> Void)?

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
        guard let me = me() else {
            return []
        }

        let skills = skillsFromUserSkillList(me.masterSkills) + skillsFromUserSkillList(me.learningSkills)
        return skills
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

        pickedSkillAction?(skill: currentPickedSkill)

        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view data source

    enum Section: Int {
        case DefaultSkill
        case Skills
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {
        case .DefaultSkill:
            return 1
        case .Skills:
            return skills.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier("ChannelCell", forIndexPath: indexPath)

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {
        case .DefaultSkill:
            currentPickedSkill = nil
            cell.textLabel?.text = NSLocalizedString("Default", comment: "")
        case .Skills:
            let skill = skills[indexPath.row]
            cell.textLabel?.text = skill.localName
        }

        cell.selectedBackgroundView = selectedBackgroundView

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {
        case .DefaultSkill:
            currentPickedSkill = nil
        case .Skills:
            currentPickedSkill = skills[indexPath.row]
        }

        doneButton.enabled = true
    }
}


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

    var pickedSkillAction: ((_ skill: Skill?) -> Void)?

    @IBOutlet weak var doneButton: UIBarButtonItem! {
        didSet {
            doneButton.isEnabled = false
        }
    }

    fileprivate lazy var selectedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 50/255.0, green: 167/255.0, blue: 255/255.0, alpha: 1.0)
        return view
    }()

    fileprivate let skills: [Skill] = {
        guard let me = me() else {
            return []
        }

        let skills = skillsFromUserSkillList(me.masterSkills) + skillsFromUserSkillList(me.learningSkills)
        return skills
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleChooseChannel

        tableView.tableFooterView = UIView()
    }

    // MARK: - Actions

    @IBAction func cancel(_ sender: UIBarButtonItem) {

        dismiss(animated: true, completion: nil)
    }

    @IBAction func done(_ sender: UIBarButtonItem) {

        pickedSkillAction?(currentPickedSkill)

        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    enum Section: Int {
        case defaultSkill
        case skills
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError()
        }

        switch section {
        case .defaultSkill:
            return 1
        case .skills:
            return skills.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ChannelCell", for: indexPath)

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {
        case .defaultSkill:
            currentPickedSkill = nil
            cell.textLabel?.text = NSLocalizedString("Default", comment: "")
        case .skills:
            let skill = skills[indexPath.row]
            cell.textLabel?.text = skill.localName
        }

        cell.selectedBackgroundView = selectedBackgroundView

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }

        switch section {
        case .defaultSkill:
            currentPickedSkill = nil
        case .skills:
            currentPickedSkill = skills[indexPath.row]
        }

        doneButton.isEnabled = true
    }
}


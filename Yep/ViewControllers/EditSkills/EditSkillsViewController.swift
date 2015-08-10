//
//  EditSkillsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/10.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class EditSkillsViewController: BaseViewController {

    var skillSetType: SkillHomeState?

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

        println(skillSetType?.rawValue)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension EditSkillsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCellWithIdentifier(editSkillCellID) as! EditSkillCell

        cell.skillLabel.text = "Skill"

        return cell
    }
}


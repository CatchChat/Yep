//
//  EditSkillsViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/10.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class EditSkillsViewController: BaseViewController {


    @IBOutlet weak var skillsTableView: UITableView!

    @IBOutlet weak var addSkillsView: BottomButtonView!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        animatedOnNavigationBar = false

        title = NSLocalizedString("Edit Skills", comment: "")

        var contentInset = skillsTableView.contentInset
        contentInset.bottom = addSkillsView.frame.height
        skillsTableView.contentInset = contentInset
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension EditSkillsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = UITableViewCell()

        cell.textLabel?.text = "Hello"

        return cell
    }
}


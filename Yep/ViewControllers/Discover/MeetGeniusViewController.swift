//
//  MeetGeniusViewController.swift
//  Yep
//
//  Created by NIX on 16/5/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class MeetGeniusViewController: UIViewController {

    let geniusInterviewCellID = "GeniusInterviewCell"

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableFooterView = UIView()
            tableView.rowHeight = 90
            tableView.registerNib(UINib(nibName: geniusInterviewCellID, bundle: nil), forCellReuseIdentifier: geniusInterviewCellID)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension MeetGeniusViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(geniusInterviewCellID, forIndexPath: indexPath) as! GeniusInterviewCell
        return cell
    }
}


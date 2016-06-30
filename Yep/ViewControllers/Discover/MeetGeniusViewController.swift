//
//  MeetGeniusViewController.swift
//  Yep
//
//  Created by NIX on 16/5/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class MeetGeniusViewController: UIViewController {

    var showGeniusInterviewAction: (() -> Void)?

    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.tableHeaderView = MeetGeniusShowView(frame: CGRect(x: 0, y: 0, width: 100, height: 180))
            tableView.tableFooterView = UIView()

            tableView.rowHeight = 90

            tableView.registerNibOf(GeniusInterviewCell)
            tableView.registerNibOf(LoadMoreTableViewCell)
        }
    }

    var geniusInterviews: [GeniusInterview] = []

    private var canLoadMore: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        println("tableView.tableHeaderView: \(tableView.tableHeaderView)")
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

    private enum Section: Int {
        case GeniusInterview
        case LoadMore
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            return geniusInterviews.count

        case .LoadMore:
            return 1
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            let cell: GeniusInterviewCell = tableView.dequeueReusableCell()
            let geniusInterview = geniusInterviews[indexPath.row]
            cell.configure(withGeniusInterview: geniusInterview)
            return cell

        case .LoadMore:
            let cell: LoadMoreTableViewCell = tableView.dequeueReusableCell()
            cell.isLoading = true
            return cell
        }
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            break

        case .LoadMore:
            guard let cell = cell as? LoadMoreTableViewCell else {
                break
            }

            guard canLoadMore else {
                cell.isLoading = false
                break
            }

            println("load more feeds")

            if !cell.isLoading {
                cell.isLoading = true
            }

            // TODO
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid Section")
        }

        switch section {

        case .GeniusInterview:
            showGeniusInterviewAction?()

        case .LoadMore:
            break
        }
    }
}


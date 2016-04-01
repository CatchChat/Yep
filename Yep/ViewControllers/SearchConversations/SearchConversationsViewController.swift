//
//  SearchConversationsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchConversationsViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.placeholder = NSLocalizedString("Search", comment: "")
        }
    }
    @IBOutlet weak var searchBarTopConstraint: NSLayoutConstraint!

    private let headerIdentifier = "TableSectionTitleView"

    @IBOutlet weak var resultsTableView: UITableView! {
        didSet {
            resultsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            resultsTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            resultsTableView.registerClass(TableSectionTitleView.self, forHeaderFooterViewReuseIdentifier: headerIdentifier)

            resultsTableView.rowHeight = 80
            resultsTableView.tableFooterView = UIView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: true)
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

//
//  SearchConversationsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchConversationsViewController: UIViewController {

    var originalNavigationControllerDelegate: UINavigationControllerDelegate?
    private var conversationsSearchTransition: ConversationsSearchTransition?

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

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let delegate = conversationsSearchTransition {
            navigationController?.delegate = delegate
        }

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] _ in
            self?.searchBarTopConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }, completion: nil)

        searchBar.becomeFirstResponder()
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

// MARK: - UISearchBarDelegate

extension SearchConversationsViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        (tabBarController as? YepTabBarController)?.setTabBarHidden(false, animated: true)

        navigationController?.popViewControllerAnimated(true)
    }
}

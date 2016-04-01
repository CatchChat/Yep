//
//  SearchConversationsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import KeyboardMan

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
    private let cellIdentifier = "SearchedContactsCell"

    @IBOutlet weak var resultsTableView: UITableView! {
        didSet {
            resultsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            resultsTableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)

            resultsTableView.registerClass(TableSectionTitleView.self, forHeaderFooterViewReuseIdentifier: headerIdentifier)
            resultsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)

            resultsTableView.rowHeight = 80
            resultsTableView.tableFooterView = UIView()
        }
    }

    private let keyboardMan = KeyboardMan()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Search Contacts"

        keyboardMan.animateWhenKeyboardAppear = { [weak self] _, keyboardHeight, _ in
            self?.resultsTableView.contentInset.bottom = keyboardHeight
            self?.resultsTableView.scrollIndicatorInsets.bottom = keyboardHeight
        }

        keyboardMan.animateWhenKeyboardDisappear = { [weak self] _ in
            self?.resultsTableView.contentInset.bottom = 0
            self?.resultsTableView.scrollIndicatorInsets.bottom = 0
        }
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

    private func hideKeyboard() {

        searchBar.resignFirstResponder()
    }
}

// MARK: - UISearchBarDelegate

extension SearchConversationsViewController: UISearchBarDelegate {

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {

        searchBar.text = nil
        searchBar.resignFirstResponder()

        (tabBarController as? YepTabBarController)?.setTabBarHidden(false, animated: true)

        navigationController?.popViewControllerAnimated(true)
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {

        hideKeyboard()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension SearchConversationsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case Friend
        case MessageRecord
        case Feed
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 3
    }

    private func numberOfRowsInSection(section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {
        case .Friend:
            return 2
        case .MessageRecord:
            return 2
        case .Feed:
            return 3
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return numberOfRowsInSection(section)
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        guard numberOfRowsInSection(section) > 0 else {
            return nil
        }

        guard let section = Section(rawValue: section) else {
            return nil
        }

        let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(headerIdentifier) as? TableSectionTitleView

        switch section {
        case .Friend:
            header?.titleLabel.text = NSLocalizedString("Friends", comment: "")
        case .MessageRecord:
            header?.titleLabel.text = NSLocalizedString("Messages", comment: "")
        case .Feed:
            header?.titleLabel.text = NSLocalizedString("Joined Feeds", comment: "")
        }

        return header
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {

        guard numberOfRowsInSection(section) > 0 else {
            return 0
        }

        return 25
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! SearchedContactsCell
        return cell
    }
}


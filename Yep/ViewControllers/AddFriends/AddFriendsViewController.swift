//
//  AddFriendsViewController.swift
//  Yep
//
//  Created by NIX on 15/5/19.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Proposer

final class AddFriendsViewController: SegueViewController {

    @IBOutlet fileprivate weak var addFriendsTableView: UITableView! {
        didSet {
            addFriendsTableView.rowHeight = 60

            addFriendsTableView.registerNibOf(AddFriendSearchCell.self)
            addFriendsTableView.registerNibOf(AddFriendMoreCell.self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("title.add_friends", comment: "")
    }

    fileprivate var isFirstAppear: Bool = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            delay(0.2) { [weak self] in
                 self?.tryShowKeyboard()
            }
        }

        isFirstAppear = false
    }

    fileprivate var addFriendSearchCell: AddFriendSearchCell? {

        let searchIndexPath = IndexPath(row: 0, section: Section.search.rawValue)
        return addFriendsTableView.cellForRow(at: searchIndexPath) as? AddFriendSearchCell
    }

    fileprivate func tryShowKeyboard() {

        addFriendSearchCell?.searchTextField.becomeFirstResponder()
    }

    fileprivate func tryHideKeyboard() {

        addFriendSearchCell?.searchTextField.resignFirstResponder()
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSearchedUsers" {
            if let searchText = sender as? String {
                let vc = segue.destination as! SearchedUsersViewController
                vc.searchText = searchText.trimming(.whitespaceAndNewline)
            }
        }
    }
}

extension AddFriendsViewController: UITableViewDataSource, UITableViewDelegate {

    fileprivate enum Section: Int {
        case search = 0
        case more
    }

    fileprivate enum More: Int, CustomStringConvertible {
        case contacts

        var description: String {
            switch self {
            case .contacts:
                return String.trans_titleFriendsInContacts
            }
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .search:
            return 1

        case .more:
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .search:
            let cell: AddFriendSearchCell = tableView.dequeueReusableCell()

            cell.searchTextField.returnKeyType = .search
            cell.searchTextField.delegate = self

            return cell

        case .more:
            let cell: AddFriendMoreCell = tableView.dequeueReusableCell()

            cell.annotationLabel.text = More(rawValue: indexPath.row)?.description

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        tryHideKeyboard()

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .search:
            break

        case .more:
            guard let row = More(rawValue: indexPath.row) else {
                fatalError("Invalid row!")
            }

            switch row {

            case .contacts:

                let propose: Propose = {
                    proposeToAccess(.contacts, agreed: { [weak self] in
                        self?.performSegue(withIdentifier: "showFriendsInContacts", sender: nil)

                    }, rejected: { [weak self] in
                        self?.alertCanNotAccessContacts()
                    })
                }

                showProposeMessageIfNeedForContactsAndTryPropose(propose)
            }
        }
    }
}

extension AddFriendsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

        let text = textField.text

        textField.resignFirstResponder()

        performSegue(withIdentifier: "showSearchedUsers", sender: text)

        return true
    }
}


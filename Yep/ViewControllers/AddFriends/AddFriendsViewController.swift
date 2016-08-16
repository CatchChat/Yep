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

    @IBOutlet private weak var addFriendsTableView: UITableView! {
        didSet {
            addFriendsTableView.rowHeight = 60

            addFriendsTableView.registerNibOf(AddFriendSearchCell)
            addFriendsTableView.registerNibOf(AddFriendMoreCell)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("title.add_friends", comment: "")
    }

    private var isFirstAppear: Bool = true

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if isFirstAppear {
            delay(0.2) { [weak self] in
                 self?.tryShowKeyboard()
            }
        }

        isFirstAppear = false
    }

    private var addFriendSearchCell: AddFriendSearchCell? {

        let searchIndexPath = NSIndexPath(forRow: 0, inSection: Section.Search.rawValue)
        return addFriendsTableView.cellForRowAtIndexPath(searchIndexPath) as? AddFriendSearchCell
    }

    private func tryShowKeyboard() {

        addFriendSearchCell?.searchTextField.becomeFirstResponder()
    }

    private func tryHideKeyboard() {

        addFriendSearchCell?.searchTextField.resignFirstResponder()
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSearchedUsers" {
            if let searchText = sender as? String {
                let vc = segue.destinationViewController as! SearchedUsersViewController
                vc.searchText = searchText.trimming(.WhitespaceAndNewline)
            }
        }
    }
}

extension AddFriendsViewController: UITableViewDataSource, UITableViewDelegate {

    private enum Section: Int {
        case Search = 0
        case More
    }

    private enum More: Int, CustomStringConvertible {
        case Contacts
        //case FaceToFace

        var description: String {
            switch self {

            case .Contacts:
                return NSLocalizedString("Friends in Contacts", comment: "")

            //case .FaceToFace:
            //    return NSLocalizedString("Face to Face", comment: "")
            }
        }
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {

        case Section.Search.rawValue:
            return 1

        case Section.More.rawValue:
            return 1

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {

        case Section.Search.rawValue:
            let cell: AddFriendSearchCell = tableView.dequeueReusableCell()

            cell.searchTextField.returnKeyType = .Search
            cell.searchTextField.delegate = self

            return cell

        case Section.More.rawValue:
            let cell: AddFriendMoreCell = tableView.dequeueReusableCell()

            cell.annotationLabel.text = More(rawValue: indexPath.row)?.description

            return cell

        default:
            return UITableViewCell()
        }
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        tryHideKeyboard()

        if indexPath.section == Section.More.rawValue {

            switch indexPath.row {

            case More.Contacts.rawValue:

                let propose: Propose = {
                    proposeToAccess(.Contacts, agreed: { [weak self] in
                        self?.performSegueWithIdentifier("showFriendsInContacts", sender: nil)

                    }, rejected: { [weak self] in
                        self?.alertCanNotAccessContacts()
                    })
                }

                showProposeMessageIfNeedForContactsAndTryPropose(propose)

            //case More.FaceToFace.rawValue:
            //    break
                
            default:
                break
            }
        }
    }
}

extension AddFriendsViewController: UITextFieldDelegate {

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        let text = textField.text

        textField.resignFirstResponder()

        performSegueWithIdentifier("showSearchedUsers", sender: text)

        return true
    }
}


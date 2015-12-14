//
//  AddFriendsViewController.swift
//  Yep
//
//  Created by NIX on 15/5/19.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AddressBook
import Proposer

class AddFriendsViewController: UIViewController {

    @IBOutlet private weak var addFriendsTableView: UITableView!

    private let addFriendSearchCellIdentifier = "AddFriendSearchCell"
    private let addFriendMoreCellIdentifier = "AddFriendMoreCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Add Friends", comment: "")


        addFriendsTableView.rowHeight = 60

        addFriendsTableView.registerNib(UINib(nibName: addFriendSearchCellIdentifier, bundle: nil), forCellReuseIdentifier: addFriendSearchCellIdentifier)
        addFriendsTableView.registerNib(UINib(nibName: addFriendMoreCellIdentifier, bundle: nil), forCellReuseIdentifier: addFriendMoreCellIdentifier)
    }

    // MARK: Navigation

    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {

        guard navigationController?.topViewController == self else {
            return false
        }

        return true
    }

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

        static var caseCount: Int {
            var max: Int = 0
            while let _ = self.init(rawValue: ++max) {}
            return max
        }
    }

    private enum More: Int, CustomStringConvertible {
        case Contacts
        //case FaceToFace

        static var caseCount: Int {
            var max: Int = 0
            while let _ = self.init(rawValue: ++max) {}
            return max
        }

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
        return Section.caseCount
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {

        case Section.Search.rawValue:
            return 1

        case Section.More.rawValue:
            return More.caseCount

        default:
            return 0
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {

        case Section.Search.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(addFriendSearchCellIdentifier) as! AddFriendSearchCell

            cell.searchTextField.returnKeyType = .Search
            cell.searchTextField.delegate = self
            cell.searchTextField.becomeFirstResponder()

            return cell

        case Section.More.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(addFriendMoreCellIdentifier) as! AddFriendMoreCell

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


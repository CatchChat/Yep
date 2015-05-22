//
//  AddFriendsViewController.swift
//  Yep
//
//  Created by NIX on 15/5/19.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class AddFriendsViewController: UIViewController {

    @IBOutlet weak var addFriendsTableView: UITableView!

    let addFriendSearchCellIdentifier = "AddFriendSearchCell"
    let addFriendMoreCellIdentifier = "AddFriendMoreCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Add Friends", comment: "")


        addFriendsTableView.rowHeight = 60

        addFriendsTableView.registerNib(UINib(nibName: addFriendSearchCellIdentifier, bundle: nil), forCellReuseIdentifier: addFriendSearchCellIdentifier)
        addFriendsTableView.registerNib(UINib(nibName: addFriendMoreCellIdentifier, bundle: nil), forCellReuseIdentifier: addFriendMoreCellIdentifier)
    }

    // MARK: Actions
    
    @IBAction func done(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
        // TODO: done add friend
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSearchedUsers" {
            if let mobile = sender as? String {
                let vc = segue.destinationViewController as! SearchedUsersViewController
                vc.mobile = mobile
            }
        }
    }
}

extension AddFriendsViewController: UITableViewDataSource, UITableViewDelegate {

    enum Section: Int {
        case Search = 0
        case More

        static var caseCount: Int {
            var max: Int = 0
            while let _ = self(rawValue: ++max) {}
            return max
        }
    }

    enum More: Int, Printable {
        case Contacts
        case FaceToFace

        static var caseCount: Int {
            var max: Int = 0
            while let _ = self(rawValue: ++max) {}
            return max
        }

        var description: String {
            switch self {

            case .Contacts:
                return NSLocalizedString("Friends in Contacts", comment: "")

            case .FaceToFace:
                return NSLocalizedString("Face to Face", comment: "")
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

            cell.searchTextField.delegate = self

            return cell

        case Section.More.rawValue:
            let cell = tableView.dequeueReusableCellWithIdentifier(addFriendMoreCellIdentifier) as! AddFriendMoreCell

            cell.annotationLabel.text = More(rawValue: indexPath.row)?.description

            return cell

        default:
            return UITableViewCell()
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


//
//  FriendsInContactsViewController.swift
//  Yep
//
//  Created by NIX on 15/6/1.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import APAddressBook

class FriendsInContactsViewController: BaseViewController {

    struct Notification {
        static let NewFriends = "NewFriendsInContactsNotification"
    }

    @IBOutlet weak var friendsTableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    lazy var addressBook: APAddressBook = {
        let addressBook = APAddressBook()
        addressBook.fieldsMask = APContactField(rawValue: APContactField.CompositeName.rawValue | APContactField.Phones.rawValue)
        return addressBook
        }()

    var discoveredUsers = [DiscoveredUser]() {
        didSet {
            if discoveredUsers.count > 0 {
                updateDiscoverTableView()

                NSNotificationCenter.defaultCenter().postNotificationName(Notification.NewFriends, object: nil)

            } else {
                let label = UILabel(frame: CGRect(x: 0, y: 0, width: friendsTableView.bounds.width, height: 240))

                label.textAlignment = .Center
                label.text = NSLocalizedString("No more new friends.", comment: "")
                label.textColor = UIColor.lightGrayColor()

                friendsTableView.tableFooterView = label
            }
        }
    }
    
    let cellIdentifier = "ContactsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Available Friends", comment: "")

        friendsTableView.separatorColor = UIColor.yepCellSeparatorColor()
        friendsTableView.separatorInset = YepConfig.ContactsCell.separatorInset
        
        friendsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        friendsTableView.rowHeight = 80
        friendsTableView.tableFooterView = UIView()

        addressBook.loadContacts{ (contacts: [AnyObject]!, error: NSError!) in
            if let contacts = contacts as? [APContact] {

                var uploadContacts = [UploadContact]()

                for contact in contacts {

                    let name = contact.compositeName

                    if let phones = contact.phones as? [String] {
                        for phone in phones {
                            let uploadContact: UploadContact = ["name": name, "number": phone]
                            uploadContacts.append(uploadContact)
                        }
                    }
                }

                //println(uploadContacts)

                self.activityIndicator.startAnimating()

                friendsInContacts(uploadContacts, failureHandler: { (reason, errorMessage) in
                    defaultFailureHandler(reason, errorMessage)

                    dispatch_async(dispatch_get_main_queue()) {
                        self.activityIndicator.stopAnimating()
                    }

                }, completion: { discoveredUsers in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.discoveredUsers = discoveredUsers

                        self.activityIndicator.stopAnimating()
                    }
                })

            } else if (error != nil) {
                YepAlert.alertSorry(message: error.localizedDescription, inViewController: self)
            }
        }
    }

    // MARK: Actions

    func updateDiscoverTableView() {
        friendsTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = discoveredUsers[indexPath.row]

                let vc = segue.destinationViewController as! ProfileViewController

                if discoveredUser.id != YepUserDefaults.userID.value {
                    vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                }

                vc.setBackButtonWithTitle()

                vc.hidesBottomBarWhenPushed = true
            }
        }
    }

}

// MARK: UITableViewDataSource, UITableViewDelegate

extension FriendsInContactsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let discoveredUser = discoveredUsers[indexPath.row]

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5

        let avatarURLString = discoveredUser.avatarURLString
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                cell.avatarImageView.image = roundImage
            }
        }

        cell.joinedDateLabel.text = discoveredUser.introduction

        let distance = discoveredUser.distance.format(".1")
        cell.lastTimeSeenLabel.text = "\(distance) km | \(discoveredUser.lastSignInAt.timeAgo)"

        cell.nameLabel.text = discoveredUser.nickname

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}


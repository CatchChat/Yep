//
//  SearchedUsersViewController.swift
//  Yep
//
//  Created by NIX on 15/5/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedUsersViewController: UIViewController {

    var mobile = "18602354812"

    @IBOutlet weak var searchedUsersTableView: UITableView!

    var searchedUsers = [DiscoveredUser]() {
        didSet {
            updateSearchedUsersTableView()
        }
    }

    let cellIdentifier = "ContactsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Searched Users", comment: "")

        searchedUsersTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        searchedUsersTableView.rowHeight = 80


        searchUsersByQ(mobile, failureHandler: { (reason, errorMessage) in
            defaultFailureHandler(reason, errorMessage)

        }, completion: { users in
            dispatch_async(dispatch_get_main_queue()) {
                self.searchedUsers = users
            }
        })
    }

    // MARK: Actions

    func updateSearchedUsersTableView() {
        searchedUsersTableView.reloadData()
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = searchedUsers[indexPath.row]

                let vc = segue.destinationViewController as! ProfileViewController

                vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)

                vc.setBackButtonWithTitle()

                vc.hidesBottomBarWhenPushed = true
            }
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension SearchedUsersViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchedUsers.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        let discoveredUser = searchedUsers[indexPath.row]

        let radius = min(CGRectGetWidth(cell.avatarImageView.bounds), CGRectGetHeight(cell.avatarImageView.bounds)) * 0.5

        let avatarURLString = discoveredUser.avatarURLString
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                cell.avatarImageView.image = roundImage
            }
        }

        cell.joinedDateLabel.text = discoveredUser.introduction
        let distance = discoveredUser.distance.format(".1")
        cell.lastTimeSeenLabel.text = "\(distance)km | \(discoveredUser.lastSignInAt.timeAgo)"

        cell.nameLabel.text = discoveredUser.nickname

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}
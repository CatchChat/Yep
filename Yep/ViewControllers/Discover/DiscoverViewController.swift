//
//  DiscoverViewController.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverViewController: BaseViewController {

    @IBOutlet weak var discoverTableView: UITableView!
    
    @IBOutlet weak var filterButtonItem: UIBarButtonItem!
    
    let cellIdentifier = "ContactsCell"

    var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            filterButtonItem.title = discoveredUserSortStyle.name

            discoverUsers(masterSkills: [], learningSkills: [], discoveredUserSortStyle: discoveredUserSortStyle, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)

            }, completion: { discoveredUsers in
                dispatch_async(dispatch_get_main_queue()) {
                    self.discoveredUsers = discoveredUsers
                }
            })
        }
    }

    var discoveredUsers = [DiscoveredUser]() {
        didSet {
            updateDiscoverTableView()
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()
        
        discoverTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        discoverTableView.rowHeight = 80

        discoveredUserSortStyle = .Default
    }


    // MARK: Actions

    @IBAction func showFilters(sender: UIBarButtonItem) {
        moreAction()
    }
    
    func moreAction() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let nearbyAction: UIAlertAction = UIAlertAction(title: DiscoveredUserSortStyle.Distance.name, style: .Default) { action -> Void in
            self.discoveredUserSortStyle = .Distance
        }
        alertController.addAction(nearbyAction)
        
        let timeAction: UIAlertAction = UIAlertAction(title: DiscoveredUserSortStyle.LastSignIn.name, style: .Default) { action -> Void in
            self.discoveredUserSortStyle = .LastSignIn
        }
        alertController.addAction(timeAction)
        
        let defaultAction: UIAlertAction = UIAlertAction(title: DiscoveredUserSortStyle.Default.name, style: .Default) { action -> Void in
            self.discoveredUserSortStyle = .Default
        }
        alertController.addAction(defaultAction)

        let cancelAction: UIAlertAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .Cancel) { action -> Void in
        }
        alertController.addAction(cancelAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func updateDiscoverTableView() {
        self.discoverTableView.reloadData()
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        if segue.identifier == "showProfile" {
            if let indexPath = sender as? NSIndexPath {
                let discoveredUser = discoveredUsers[indexPath.row]

                let vc = segue.destinationViewController as! ProfileViewController
                
                vc.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                
                vc.setBackButtonWithTitle()

                vc.hidesBottomBarWhenPushed = true
            }
        }
    }
}

// MARK: UITableViewDataSource, UITableViewDelegate

extension DiscoverViewController: UITableViewDataSource, UITableViewDelegate {

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



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

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    let cellIdentifier = "ContactsCell"

    var discoveredUserSortStyle: DiscoveredUserSortStyle = .Default {
        didSet {
            filterButtonItem.title = discoveredUserSortStyle.nameWithArrow

            activityIndicator.startAnimating()

            discoverUsers(masterSkillIDs: [], learningSkillIDs: [], discoveredUserSortStyle: discoveredUserSortStyle, failureHandler: { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {
                    self.activityIndicator.stopAnimating()
                }

            }, completion: { discoveredUsers in
                dispatch_async(dispatch_get_main_queue()) {
                    self.discoveredUsers = discoveredUsers
                    self.activityIndicator.stopAnimating()
                }
            })
        }
    }

    var discoveredUsers = [DiscoveredUser]() {
        willSet {
            if newValue.count == 0 {
                discoverTableView.tableFooterView = InfoView(NSLocalizedString("No discovered users.", comment: ""))
            }
        }
        didSet {
            updateDiscoverTableView()
        }
    }

    lazy var filterView: DiscoverFilterView = DiscoverFilterView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Discover", comment: "")

        view.backgroundColor = UIColor.whiteColor()

        discoverTableView.separatorColor = UIColor.yepCellSeparatorColor()
        discoverTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        discoverTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        discoverTableView.rowHeight = 80

        discoverTableView.tableFooterView = UIView()

        discoveredUserSortStyle = .Default
    }


    // MARK: Actions

    @IBAction func showFilters(sender: UIBarButtonItem) {

        filterView.currentDiscoveredUserSortStyle = discoveredUserSortStyle
        
        filterView.filterAction = { discoveredUserSortStyle in
            self.discoveredUserSortStyle = discoveredUserSortStyle
        }

        if let window = view.window {
            filterView.showInView(window)
        }
    }

    func updateDiscoverTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            //self.discoverTableView.reloadData()
            self.discoverTableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
        }
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

extension DiscoverViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredUsers.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell
        
        let discoveredUser = discoveredUsers[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser, tableView: tableView, indexPath: indexPath)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        performSegueWithIdentifier("showProfile", sender: indexPath)
    }
}



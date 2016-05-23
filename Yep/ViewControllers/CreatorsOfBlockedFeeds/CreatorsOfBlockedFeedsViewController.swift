//
//  CreatorsOfBlockedFeedsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepConfig
import RealmSwift

final class CreatorsOfBlockedFeedsViewController: BaseViewController {

    @IBOutlet private weak var blockedCreatorsTableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private let cellIdentifier = "ContactsCell"

    private var blockedCreators = [DiscoveredUser]() {
        willSet {
            if newValue.count == 0 {
                blockedCreatorsTableView.tableFooterView = InfoView(NSLocalizedString("No blocked creators.", comment: ""))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Blocked Creators", comment: "")

        blockedCreatorsTableView.separatorColor = UIColor.yepCellSeparatorColor()
        blockedCreatorsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

        blockedCreatorsTableView.registerNib(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        blockedCreatorsTableView.rowHeight = 80
        blockedCreatorsTableView.tableFooterView = UIView()

        activityIndicator.startAnimating()

        creatorsOfBlockedFeeds(failureHandler: { [weak self] reason, errorMessage in
            dispatch_async(dispatch_get_main_queue()) {
                self?.activityIndicator.stopAnimating()
            }

            let errorMessage = errorMessage ?? NSLocalizedString("Netword Error: Faild to get blocked creator!", comment: "")
            YepAlert.alertSorry(message: errorMessage, inViewController: self)

        }, completion: { blockedCreators in
            dispatch_async(dispatch_get_main_queue()) { [weak self] in
                self?.activityIndicator.stopAnimating()

                self?.blockedCreators = blockedCreators
                self?.blockedCreatorsTableView.reloadData()
            }
        })
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destinationViewController as! ProfileViewController

            if let discoveredUser = (sender as? Box<DiscoveredUser>)?.value {
                vc.profileUser = .DiscoveredUserType(discoveredUser)
            }

            vc.hidesBottomBarWhenPushed = true

            vc.setBackButtonWithTitle()

        default:
            break
        }
    }
}

extension CreatorsOfBlockedFeedsViewController: UITableViewDataSource, UITabBarDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedCreators.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ContactsCell

        cell.selectionStyle = .None

        let discoveredUser = blockedCreators[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser)

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        let discoveredUser = blockedCreators[indexPath.row]
        performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
    }

    // Edit (for Unblock)

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {

        if editingStyle == .Delete {

            let discoveredUser = blockedCreators[indexPath.row]

            unblockFeedsFromCreator(userID: discoveredUser.id, failureHandler: nil, completion: { success in
                println("unblockFeedsFromCreator \(success)")

                dispatch_async(dispatch_get_main_queue()) { [weak self] in

                    if let strongSelf = self {
                        if let index = strongSelf.blockedCreators.indexOf(discoveredUser)  {

                            strongSelf.blockedCreators.removeAtIndex(index)

                            let indexPathToDelete = NSIndexPath(forRow: index, inSection: 0)
                            strongSelf.blockedCreatorsTableView.deleteRowsAtIndexPaths([indexPathToDelete], withRowAnimation: .Automatic)
                        }
                    }
                }
            })
        }
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return NSLocalizedString("Unblock", comment: "")
    }
}


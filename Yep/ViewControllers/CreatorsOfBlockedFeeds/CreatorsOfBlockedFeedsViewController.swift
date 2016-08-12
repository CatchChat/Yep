//
//  CreatorsOfBlockedFeedsViewController.swift
//  Yep
//
//  Created by NIX on 16/4/13.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

final class CreatorsOfBlockedFeedsViewController: BaseViewController {

    @IBOutlet private weak var blockedCreatorsTableView: UITableView! {
        didSet {
            blockedCreatorsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            blockedCreatorsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            blockedCreatorsTableView.rowHeight = 80
            blockedCreatorsTableView.tableFooterView = UIView()

            blockedCreatorsTableView.registerNibOf(ContactsCell)
        }
    }
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!

    private var blockedCreators = [DiscoveredUser]() {
        willSet {
            if newValue.count == 0 {
                blockedCreatorsTableView.tableFooterView = InfoView(NSLocalizedString("No Blocked Creators", comment: ""))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleBlockedCreators

        activityIndicator.startAnimating()

        creatorsOfBlockedFeeds(failureHandler: { [weak self] reason, errorMessage in
            SafeDispatch.async {
                self?.activityIndicator.stopAnimating()
            }

            let errorMessage = errorMessage ?? NSLocalizedString("Network Error: Failed to get blocked creator!", comment: "")
            YepAlert.alertSorry(message: errorMessage, inViewController: self)

        }, completion: { blockedCreators in
            SafeDispatch.async { [weak self] in
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

            let discoveredUser = (sender as! Box<DiscoveredUser>).value
            vc.prepare(withDiscoveredUser: discoveredUser)

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

        let cell: ContactsCell = tableView.dequeueReusableCell()

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

                SafeDispatch.async { [weak self] in

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


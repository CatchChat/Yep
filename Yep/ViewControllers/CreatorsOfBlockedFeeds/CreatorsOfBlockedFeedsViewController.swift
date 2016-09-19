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

    @IBOutlet fileprivate weak var blockedCreatorsTableView: UITableView! {
        didSet {
            blockedCreatorsTableView.separatorColor = UIColor.yepCellSeparatorColor()
            blockedCreatorsTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            blockedCreatorsTableView.rowHeight = 80
            blockedCreatorsTableView.tableFooterView = UIView()

            blockedCreatorsTableView.registerNibOf(ContactsCell)
        }
    }
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    fileprivate var blockedCreators = [DiscoveredUser]() {
        willSet {
            if newValue.count == 0 {
                blockedCreatorsTableView.tableFooterView = InfoView(String.trans_promptNoBlockedFeedCreators)
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":
            let vc = segue.destination as! ProfileViewController

            let discoveredUser = (sender as! Box<DiscoveredUser>).value
            vc.prepare(with: discoveredUser)

        default:
            break
        }
    }
}

extension CreatorsOfBlockedFeedsViewController: UITableViewDataSource, UITabBarDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedCreators.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()

        cell.selectionStyle = .none

        let discoveredUser = blockedCreators[indexPath.row]

        cell.configureWithDiscoveredUser(discoveredUser)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let discoveredUser = blockedCreators[indexPath.row]
        performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(discoveredUser))
    }

    // Edit (for Unblock)

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

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
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: IndexPath) -> String? {
        return NSLocalizedString("Unblock", comment: "")
    }
}


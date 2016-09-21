//
//  BlackListViewController.swift
//  Yep
//
//  Created by nixzhu on 15/8/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

final class BlackListViewController: BaseViewController {

    @IBOutlet fileprivate weak var blockedUsersTableView: UITableView! {
        didSet {
            blockedUsersTableView.separatorColor = UIColor.yepCellSeparatorColor()
            blockedUsersTableView.separatorInset = YepConfig.ContactsCell.separatorInset

            blockedUsersTableView.rowHeight = 80
            blockedUsersTableView.tableFooterView = UIView()

            blockedUsersTableView.registerNibOf(ContactsCell.self)
        }
    }
    @IBOutlet fileprivate weak var activityIndicator: UIActivityIndicatorView!

    fileprivate var blockedUsers: [DiscoveredUser] = [] {
        willSet {
            if newValue.count == 0 {
                blockedUsersTableView.tableFooterView = InfoView(String.trans_promptNoBlockedUsers)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String.trans_titleBlockedUsers

        activityIndicator.startAnimating()

        blockedUsersByMe(failureHandler: { (reason, errorMessage) in
            SafeDispatch.async { [weak self] in
                self?.activityIndicator.stopAnimating()
            }

            let message = errorMessage ?? "Failed to get blocked users!"
            YepAlert.alertSorry(message: message, inViewController: self)

        }, completion: { blockedUsers in
            SafeDispatch.async { [weak self] in
                self?.activityIndicator.stopAnimating()

                self?.blockedUsers = blockedUsers
                self?.blockedUsersTableView.reloadData()
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

extension BlackListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: ContactsCell = tableView.dequeueReusableCell()
        cell.selectionStyle = .none

        let discoveredUser = blockedUsers[indexPath.row]
        cell.configureWithDiscoveredUser(discoveredUser)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let discoveredUser = blockedUsers[indexPath.row]
        performSegue(withIdentifier: "showProfile", sender: Box<DiscoveredUser>(discoveredUser))
    }

    // Edit (for Unblock)

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

            let discoveredUser = blockedUsers[indexPath.row]

            unblockUserWithUserID(discoveredUser.id, failureHandler: nil, completion: { success in
                println("unblockUserWithUserID \(success)")

                SafeDispatch.async { [weak self] in

                    guard let realm = try? Realm() else {
                        return
                    }

                    if let user = userWithUserID(discoveredUser.id, inRealm: realm) {
                        let _ = try? realm.write {
                            user.blocked = false
                        }
                    }

                    if let strongSelf = self {
                        if let index = strongSelf.blockedUsers.index(of: discoveredUser)  {

                            strongSelf.blockedUsers.remove(at: index)

                            let indexPathToDelete = IndexPath(row: index, section: 0)
                            strongSelf.blockedUsersTableView.deleteRows(at: [indexPathToDelete], with: .automatic)
                        }
                    }
                }
            })
        }
    }

    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return NSLocalizedString("Unblock", comment: "")
    }
}


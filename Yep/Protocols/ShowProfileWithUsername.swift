//
//  ShowProfileWithUsername.swift
//  Yep
//
//  Created by NIX on 16/8/1.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

protocol ShowProfileWithUsername: class {

   func tryShowProfileWithUsername(username: String)
}

extension ShowProfileWithUsername where Self: UIViewController {

    private func show(profileUser: ProfileUser) {

        guard navigationController?.topViewController == self else {
            return
        }

        performSegueWithIdentifier("showProfileWithUsername", sender: Box<ProfileUser>(profileUser))
    }

    func tryShowProfileWithUsername(username: String) {

        if let realm = try? Realm(), user = userWithUsername(username, inRealm: realm) {
            let profileUser = ProfileUser.UserType(user)

            delay(0.1) { [weak self] in
                self?.show(profileUser)
            }

        } else {
            discoverUserByUsername(username, failureHandler: { [weak self] reason, errorMessage in
                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("User not found!", comment: ""), inViewController: self)

            }, completion: { discoveredUser in
                SafeDispatch.async { [weak self] in
                    let profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
                    self?.show(profileUser)
                }
            })
        }
    }
}

extension ConversationViewController: ShowProfileWithUsername {
}

extension ProfileViewController: ShowProfileWithUsername {
}



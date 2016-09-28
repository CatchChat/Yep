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

   func tryShowProfileWithUsername(_ username: String)
}

extension ShowProfileWithUsername where Self: UIViewController {

    fileprivate func show(_ profileUser: ProfileUser) {

        guard navigationController?.topViewController == self else {
            return
        }

        performSegue(withIdentifier: "showProfileWithUsername", sender: profileUser)
    }

    func tryShowProfileWithUsername(_ username: String) {

        if let realm = try? Realm(), let user = userWithUsername(username, inRealm: realm) {
            let profileUser = ProfileUser.userType(user)

            _ = delay(0.1) { [weak self] in
                self?.show(profileUser)
            }

        } else {
            discoverUserByUsername(username, failureHandler: { [weak self] reason, errorMessage in
                YepAlert.alertSorry(message: errorMessage ?? NSLocalizedString("User not found!", comment: ""), inViewController: self)

            }, completion: { discoveredUser in
                SafeDispatch.async { [weak self] in
                    let profileUser = ProfileUser.discoveredUserType(discoveredUser)
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



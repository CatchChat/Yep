//
//  ProfileViewController+Prepare.swift
//  Yep
//
//  Created by NIX on 16/7/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit

extension ProfileViewController {

    func prepare(withDiscoveredUser discoveredUser: DiscoveredUser) {

        if discoveredUser.id != YepUserDefaults.userID.value {
            self.profileUser = ProfileUser.DiscoveredUserType(discoveredUser)
        }

        self.setBackButtonWithTitle()

        self.hidesBottomBarWhenPushed = true
    }

    func prepare(withUser user: User) {

        if user.userID != YepUserDefaults.userID.value {
            self.profileUser = ProfileUser.UserType(user)
        }

        self.setBackButtonWithTitle()

        self.hidesBottomBarWhenPushed = true
    }
}


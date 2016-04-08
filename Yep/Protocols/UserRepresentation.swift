//
//  UserRepresentation.swift
//  Yep
//
//  Created by NIX on 16/4/8.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

protocol UserRepresentation {

    var userID: String { get }
    var nickname: String { get }
    var mentionedUsername: String? { get }
    var avatarURLString: String { get }

    var lastSignInUnixTime: NSTimeInterval { get }
}

extension User: UserRepresentation {

}

extension DiscoveredUser: UserRepresentation {

    var userID: String {
        return id
    }
}
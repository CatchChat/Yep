//
//  ModelTypes.swift
//  Yep
//
//  Created by nixzhu on 16/1/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

protocol UserType {

    var userID: String { get }
    var username: String? { get }
    var nickname: String { get }
    var introduction: String { get }
    var avatarURLString: String { get }
    var badge: String? { get }

    var createdUnixTime: NSTimeInterval { get }
    var lastSignInUnixTime: NSTimeInterval { get }

    var longitude: Double { get }
    var latitude: Double { get }

    
}

protocol FeedType {

    var feedID: String { get }
    var allowComment: Bool { get }
    var kind: FeedKind? { get }

    var createdUnixTime: NSTimeInterval { get }
    var updatedUnixTime: NSTimeInterval { get }

    var creator: UserType? { get }
}
//
//  ClearTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep
@testable import YepKit
import RealmSwift

final class ClearTests: XCTestCase {

    func testCleanRealmAndCaches() {

        cleanRealmAndCaches()

        let realm = try! Realm()

        do {
            let noMessages = realm.objects(Message.self).isEmpty
            XCTAssertTrue(noMessages)
        }

        do {
            let noUsers = realm.objects(User.self).isEmpty
            XCTAssertTrue(noUsers)
        }

        do {
            let noGroups = realm.objects(Group.self).isEmpty
            XCTAssertTrue(noGroups)
        }

        do {
            let noFeeds = realm.objects(Feed.self).isEmpty
            XCTAssertTrue(noFeeds)
        }

        do {
            let path = FileManager.yepMessageCachesURL()?.path
            let noMessageCacheFiles = try! FileManager.default.contentsOfDirectory(atPath: path!).isEmpty
            XCTAssertTrue(noMessageCacheFiles)
        }

        do {
            let path = FileManager.yepAvatarCachesURL()?.path
            let noAvatarCacheFiles = try! FileManager.default.contentsOfDirectory(atPath: path!).isEmpty
            XCTAssertTrue(noAvatarCacheFiles)
        }
    }
}


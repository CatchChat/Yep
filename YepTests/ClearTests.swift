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
            let noMessages = realm.objects(Message).isEmpty
            XCTAssertTrue(noMessages)
        }

        do {
            let noUsers = realm.objects(User).isEmpty
            XCTAssertTrue(noUsers)
        }

        do {
            let noGroups = realm.objects(Group).isEmpty
            XCTAssertTrue(noGroups)
        }

        do {
            let noFeeds = realm.objects(Feed).isEmpty
            XCTAssertTrue(noFeeds)
        }

        do {
            let path = NSFileManager.yepMessageCachesURL()?.path
            let noMessageCacheFiles = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(path!).isEmpty
            XCTAssertTrue(noMessageCacheFiles)
        }

        do {
            let path = NSFileManager.yepAvatarCachesURL()?.path
            let noAvatarCacheFiles = try! NSFileManager.defaultManager().contentsOfDirectoryAtPath(path!).isEmpty
            XCTAssertTrue(noAvatarCacheFiles)
        }
    }
}


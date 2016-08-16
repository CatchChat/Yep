//
//  SyncTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import YepKit

final class SyncTests: XCTestCase {

    func testSyncFriendships() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("sync friendships")

        syncFriendshipsAndDoFurtherAction {
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(20, handler: nil)
    }

    func testSyncUnreadMessages() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("sync unread messages")

        syncUnreadMessagesAndDoFurtherAction { _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(20, handler: nil)
    }
}


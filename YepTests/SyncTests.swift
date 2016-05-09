//
//  SyncTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

#if !JPUSH
    
import XCTest
@testable import Yep

final class SyncTests: XCTestCase {

    func testSyncFriendships() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("sync friendships")

        syncFriendshipsAndDoFurtherAction {
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssert(true, "Pass")
    }

    func testSyncGroups() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("sync groups")

        syncGroupsAndDoFurtherAction {
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssert(true, "Pass")
    }

    func testSyncUnreadMessages() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("sync unread messages")

        syncUnreadMessagesAndDoFurtherAction { _ in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssert(true, "Pass")
    }
}

#endif


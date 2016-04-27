//
//  ServerTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep

class ServerTests: XCTestCase {

    func testGetHotWords() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get hot words")

        hotWordsOfSearchFeeds(failureHandler: nil, completion: { hotWords in
            if !hotWords.isEmpty {
                expectation.fulfill()
            }
        })

        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssert(true, "Pass")
    }

    func testGetFeedsWithKeyword() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get feeds with keyword")

        feedsWithKeyword("hello", skillID: nil, userID: nil, pageIndex: 1, perPage: 30, failureHandler: nil) { feeds in
            if !feeds.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssert(true, "Pass")
    }

    func testJoinAndLeaveGroup() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get feeds with keyword")

        feedsWithKeyword("iOS", skillID: nil, userID: nil, pageIndex: 1, perPage: 1, failureHandler: nil) { feeds in
            if let firstFeed = feeds.first {
                let groupID = firstFeed.groupID
                joinGroup(groupID: groupID, failureHandler: nil, completion: {
                    leaveGroup(groupID: groupID, failureHandler: nil, completion: {
                        expectation.fulfill()
                    })
                })
            }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssert(true, "Pass")
    }
}


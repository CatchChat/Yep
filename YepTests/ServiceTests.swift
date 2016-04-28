//
//  ServerTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep

class ServiceTests: XCTestCase {

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

        let expectation = expectationWithDescription("join and leave group")

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

    func testSendMessageToGroup() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("send message to group")

        feedsWithKeyword("Yep", skillID: nil, userID: nil, pageIndex: 1, perPage: 1, failureHandler: nil) { feeds in

            if let firstFeed = feeds.first {
                let groupID = firstFeed.groupID

                dispatch_async(dispatch_get_main_queue()) {
                    sendText("How do you do?", toRecipient: groupID, recipientType: "Circle", afterCreatedMessage: { _ in }, failureHandler: nil, completion: { success in

                        if success {
                            meIsMemberOfGroup(groupID: groupID, failureHandler: nil, completion: { yes in
                                if yes {
                                    leaveGroup(groupID: groupID, failureHandler: nil, completion: {
                                    })

                                    expectation.fulfill()
                                }
                            })
                        }
                    })
                }
            }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssert(true, "Pass")
    }
}


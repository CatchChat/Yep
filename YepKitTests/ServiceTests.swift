//
//  ServerTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import YepKit

final class ServiceTests: XCTestCase {

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
    }

    func testGetFeedsWithKeyword() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get feeds with keyword")

        feedsWithKeyword("hello", skillID: nil, userID: nil, pageIndex: 1, perPage: 30, failureHandler: nil) { feeds, _ in
            if !feeds.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testJoinAndLeaveGroup() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("join and leave group")

        feedsWithKeyword("iOS", skillID: nil, userID: nil, pageIndex: 1, perPage: 1, failureHandler: nil) { feeds, _ in
            if let firstFeed = feeds.first {
                let groupID = firstFeed.groupID
                joinGroup(groupID: groupID, failureHandler: nil, completion: {
                    leaveGroup(groupID: groupID, failureHandler: nil, completion: {
                        expectation.fulfill()
                    })
                })
            }
        }

        waitForExpectationsWithTimeout(15, handler: nil)
    }

    func testSendMessageToGroup() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("send message to group")

        feedsWithKeyword("Yep", skillID: nil, userID: nil, pageIndex: 1, perPage: 1, failureHandler: nil) { feeds, _ in

            if let firstFeed = feeds.first {
                let groupID = firstFeed.groupID

                SafeDispatch.async {
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
    }

    func testUpdateAvatar() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("update avatar")

        let bundle = NSBundle(forClass: ServiceTests.self)
        let image = UIImage(named: "coolie", inBundle: bundle, compatibleWithTraitCollection: nil)!
        let imageData = UIImageJPEGRepresentation(image, Config.avatarCompressionQuality())!

        updateAvatarWithImageData(imageData, failureHandler: nil, completion: { newAvatarURLString in
            userInfo(failureHandler: nil) { myUserInfo in
                if let avatarInfo = myUserInfo["avatar"] as? [String: AnyObject], avatarURLString = avatarInfo["url"] as? String {
                    if newAvatarURLString == avatarURLString {
                        expectation.fulfill()
                    }
                }
            }
        })
        //expectation.fulfill() // tmp workaround

        waitForExpectationsWithTimeout(30, handler: nil)
    }

    func testGetCreatorsOfBlockedFeeds() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get creators of blocked feeds")

        creatorsOfBlockedFeeds(failureHandler: nil, completion: { creators in
            print("creatorsOfBlockedFeeds.count: \(creators.count)")
            expectation.fulfill()
        })

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testGetUsersMatchWithUsernamePrefix() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let usernamePrefix = "t"

        let expectation = expectationWithDescription("get users match with username prefix: \(usernamePrefix)")

        usersMatchWithUsernamePrefix(usernamePrefix, failureHandler: nil) { users in
            if !users.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testGetMyConversations() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get my conversations")

        myConversations(maxMessageID: nil, failureHandler: nil) { result in

            if
                let userInfos = result["users"] as? [[String: AnyObject]] where !userInfos.isEmpty,
                let groupInfos = result["circles"] as? [[String: AnyObject]] where !groupInfos.isEmpty,
                let messageInfos = result["messages"] as? [[String: AnyObject]] where !messageInfos.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }
}


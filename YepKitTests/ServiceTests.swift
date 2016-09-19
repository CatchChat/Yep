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

        let expectation = self.expectation(description: "get hot words")

        hotWordsOfSearchFeeds(failureHandler: nil, completion: { hotWords in
            if !hotWords.isEmpty {
                expectation.fulfill()
            }
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetFeedsWithKeyword() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = self.expectation(description: "get feeds with keyword")

        feedsWithKeyword("hello", skillID: nil, userID: nil, pageIndex: 1, perPage: 30, failureHandler: nil) { feeds in
            if !feeds.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testJoinAndLeaveGroup() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = self.expectation(description: "join and leave group")

        feedsWithKeyword("iOS", skillID: nil, userID: nil, pageIndex: 1, perPage: 1, failureHandler: nil) { feeds in
            let validFeeds = feeds.flatMap({ $0 })
            if let firstFeed = validFeeds.first {
                let groupID = firstFeed.groupID
                joinGroup(groupID: groupID, failureHandler: nil, completion: {
                    leaveGroup(groupID: groupID, failureHandler: nil, completion: {
                        expectation.fulfill()
                    })
                })
            }
        }

        waitForExpectations(timeout: 15, handler: nil)
    }

    func testSendMessageToGroup() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = self.expectation(description: "send message to group")

        feedsWithKeyword("Yep", skillID: nil, userID: nil, pageIndex: 1, perPage: 1, failureHandler: nil) { feeds in

            let validFeeds = feeds.flatMap({ $0 })

            if let firstFeed = validFeeds.first {
                let groupID = firstFeed.groupID

                let recipient = Recipient(type: ConversationType.Group, ID: groupID)
                SafeDispatch.async {
                    sendText("How do you do?", toRecipient: recipient, afterCreatedMessage: { _ in }, failureHandler: nil, completion: { success in

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

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testUpdateAvatar() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = self.expectation(description: "update avatar")

        let bundle = Bundle(for: ServiceTests.self)
        let image = UIImage(named: "coolie", in: bundle, compatibleWith: nil)!
        let imageData = UIImageJPEGRepresentation(image, Config.avatarCompressionQuality)!

        updateAvatarWithImageData(imageData, failureHandler: nil, completion: { newAvatarURLString in
            userInfo(failureHandler: nil) { myUserInfo in
                if let avatarInfo = myUserInfo["avatar"] as? [String: AnyObject], let avatarURLString = avatarInfo["url"] as? String {
                    if newAvatarURLString == avatarURLString {
                        expectation.fulfill()
                    }
                }
            }
        })
        //expectation.fulfill() // tmp workaround

        waitForExpectations(timeout: 30, handler: nil)
    }

    func testGetCreatorsOfBlockedFeeds() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = self.expectation(description: "get creators of blocked feeds")

        creatorsOfBlockedFeeds(failureHandler: nil, completion: { creators in
            print("creatorsOfBlockedFeeds.count: \(creators.count)")
            expectation.fulfill()
        })

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetUsersMatchWithUsernamePrefix() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let usernamePrefix = "t"

        let expectation = self.expectation(description: "get users match with username prefix: \(usernamePrefix)")

        usersMatchWithUsernamePrefix(usernamePrefix, failureHandler: nil) { users in
            if !users.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testGetMyConversations() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = self.expectation(description: "get my conversations")

        myConversations(maxMessageID: nil, failureHandler: nil) { result in

            if
                let userInfos = result["users"] as? [[String: AnyObject]] , !userInfos.isEmpty,
                let groupInfos = result["circles"] as? [[String: AnyObject]] , !groupInfos.isEmpty,
                let messageInfos = result["messages"] as? [[String: AnyObject]] , !messageInfos.isEmpty {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}


//
//  SocialWorkTests.swift
//  Yep
//
//  Created by NIX on 16/5/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import YepKit

final class SocialWorkTests: XCTestCase {

    func testGetGithubSocialWorks() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get github social works")

        tokensOfSocialAccounts(failureHandler: nil, completion: { tokensOfSocialAccounts in

            if let githubToken = tokensOfSocialAccounts.githubToken {
                githubReposWithToken(githubToken, failureHandler: nil, completion: { githubRepos in
                    println("githubRepos count: \(githubRepos.count)")
                    if !githubRepos.isEmpty {
                        expectation.fulfill()
                    }
                })

            } else {
                expectation.fulfill()
            }
        })

        waitForExpectationsWithTimeout(30, handler: nil)
    }

    func testGetDribbbleSocialWorks() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("get dribbble social works")

        tokensOfSocialAccounts(failureHandler: nil, completion: { tokensOfSocialAccounts in

            if let dribbbleToken = tokensOfSocialAccounts.dribbbleToken {
                dribbbleShotsWithToken(dribbbleToken, failureHandler: nil, completion: { dribbbleShots in
                    println("dribbbleShots count: \(dribbbleShots.count)")
                    if !dribbbleShots.isEmpty {
                        expectation.fulfill()
                    }
                })

            } else {
                expectation.fulfill()
            }
        })

        waitForExpectationsWithTimeout(30, handler: nil)
    }
}


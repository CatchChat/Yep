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
}


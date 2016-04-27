//
//  SyncTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import XCTest
@testable import Yep

class SyncTests: XCTestCase {

    func testSyncFriendships() {

        guard YepUserDefaults.isLogined else {
            return
        }

        let expectation = expectationWithDescription("x")

        syncFriendshipsAndDoFurtherAction { 
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)

        XCTAssert(true, "Pass")
    }
}


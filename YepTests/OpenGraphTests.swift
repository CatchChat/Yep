//
//  OpenGraphTests.swift
//  Yep
//
//  Created by NIX on 16/4/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep

class OpenGraphTests: XCTestCase {

    func testBaiduOpenGraph() {

        let baiduURL = NSURL(string: "http://www.baidu.com")!

        let expectation = expectationWithDescription("baidu open graph")

        openGraphWithURL(baiduURL, failureHandler: nil) { openGraph in

            print("openGraph: \(openGraph)")
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssert(true, "Pass")
    }
}


//
//  FunctionTests.swift
//  Yep
//
//  Created by NIX on 16/5/10.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import Yep

final class FunctionTests: XCTestCase {

    func testValidSchemeNetworkURL() {

        do {
            let url = NSURL(string: "twitter.com/nixzhu")!
            let validSchemeURL = url.yep_validSchemeNetworkURL
            XCTAssertNotNil(validSchemeURL)

            XCTAssertEqual(validSchemeURL!.scheme, "http")
        }

        do {
            let url = NSURL(string: "http://blog.zhowkev.in")!
            let validSchemeURL = url.yep_validSchemeNetworkURL
            XCTAssertNotNil(validSchemeURL)
        }

        do {
            let url = NSURL(string: "ftp://test.com")!
            let validSchemeURL = url.yep_validSchemeNetworkURL
            XCTAssertEqual(validSchemeURL, nil)
        }
    }
}


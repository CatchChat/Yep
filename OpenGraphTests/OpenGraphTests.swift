//
//  OpenGraphTests.swift
//  OpenGraphTests
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import OpenGraph

final class OpenGraphTests: XCTestCase {

    func testBaiduOpenGraph() {

        let baiduURL = URL(string: "http://www.baidu.com")!

        let expectation = self.expectation(description: "baidu open graph")

        openGraphWithURL(baiduURL, failureHandler: nil) { openGraph in

            print("baidu openGraph: \(openGraph)")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testItunesOpenGraph() {

        // 单曲
        let iTunesURL = URL(string: "https://itunes.apple.com/cn/album/hello-single/id1051365605?i=1051366040&l=en")!

        let queryItem = URLQueryItem(name: "at", value: "1010l9k7")

        let expectation = self.expectation(description: "iTunes open graph")

        openGraphWithURL(iTunesURL, failureHandler: nil) { openGraph in

            print("iTunes openGraph: \(openGraph)")

            if openGraph.url.opengraphtests_containsQueryItem(queryItem) {
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testGetTitleOfURL() {

        let url = URL(string: "https://www.apple.com")!

        let expectation = self.expectation(description: "get title of URL: \(url)")

        titleOfURL(url, failureHandler: nil, completion: { title in

            print("title: \(title)")

            if !title.isEmpty {
                expectation.fulfill()
            }
        })
        
        waitForExpectations(timeout: 10, handler: nil)
    }
}


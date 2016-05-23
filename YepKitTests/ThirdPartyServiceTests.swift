//
//  ThirdPartyServiceTests.swift
//  Yep
//
//  Created by NIX on 16/5/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import YepKit
import CoreLocation

final class ThirdPartyServiceTests: XCTestCase {

    func testSearchFoursquareVenues() {

        let expectation = expectationWithDescription("search foursquare venues")

        let coordinate = CLLocationCoordinate2D(latitude: 20.03, longitude: 110.33)

        foursquareVenuesNearby(coordinate: coordinate, failureHandler: nil, completion: { venues in
            println("venues count: \(venues.count)")
            if !venues.isEmpty {
                expectation.fulfill()
            }
        })

        waitForExpectationsWithTimeout(10, handler: nil)
    }
}


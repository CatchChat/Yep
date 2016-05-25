//
//  YepUITests.swift
//  YepUITests
//
//  Created by NIX on 16/4/25.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest

final class YepUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPostTextFeed() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        app.tabBars.buttons["Feeds"].tap()
        app.navigationBars["Feeds"].buttons["Add"].tap()
        app.tables.staticTexts["Text & Photos"].tap()

        let scrollViewsQuery = app.scrollViews
        let textView = scrollViewsQuery.childrenMatchingType(.TextView).element
        textView.tap()
        textView.typeText("42_1984")
        app.navigationBars["New Feed"].buttons["Post"].tap()
    }

    func testChangeNickname() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        app.tabBars.buttons["Profile"].tap()
        app.buttons["icon settings"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.cells.elementBoundByIndex(0).tap()
        tablesQuery.staticTexts["Nickname"].tap()
        
        let cell = tablesQuery.childrenMatchingType(.Cell).elementBoundByIndex(0)
        let textField = cell.childrenMatchingType(.TextField).element
        textField.tap()
        textField.clearAndEnterText("NIX\(abs(NSUUID().UUIDString.hash))")

        app.buttons["Done"].tap()

        app.navigationBars["Nickname"].buttons["Edit Profile"].tap()
        app.navigationBars["Edit Profile"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["Profile"].tap()
    }

    func testSearchUsers() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        app.tabBars.buttons["Contacts"].tap()
        app.navigationBars["Contacts"].buttons["Add"].tap()
        
        let textField = app.tables.childrenMatchingType(.Cell).elementBoundByIndex(0).childrenMatchingType(.TextField).element
        textField.tap()
        textField.typeText("kevin14")
        app.buttons["Search"].tap()

        app.tables.staticTexts["kevin14"].tap()

        app.navigationBars["kevin14"].buttons["icon back"].tap()
    }

    func testSearchInConversations() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        let tablesQuery = app.tables
        tablesQuery.searchFields["Search"].tap()

        let textField = app.searchFields["Search"]
        textField.tap()
        textField.typeText("app")
        app.buttons["Done"].tap()

        //tablesQuery.staticTexts["大家期待Pay吗？要看看相关的API了 www.apple.com/cn/apple-pay/"].tap()

        //app.navigationBars["Conversation"].buttons["Search"].tap()

        app.buttons["Cancel"].tap()
    }

    func testSearchInContacts() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        app.tabBars.buttons["Contacts"].tap()
        app.tables.searchFields["Search Friend"].tap()

        let textField = app.searchFields["Search Friend"]
        textField.tap()
        textField.typeText("test")
        app.buttons["Done"].tap()

        app.tables.staticTexts["test"].tap()

        app.navigationBars["test"].buttons["icon back"].tap()

        app.buttons["Cancel"].tap()
    }

    func testSearchInFeeds() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        app.tabBars.buttons["Feeds"].tap()
        app.tables.searchFields["Search Feeds"].tap()

        let textField = app.searchFields["Search Feeds"]
        textField.tap()
        textField.typeText("Hello")
        app.buttons["Done"].tap()

        app.buttons["Cancel"].tap()
    }
}


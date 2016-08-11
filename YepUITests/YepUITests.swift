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

    func testPostTextFeed() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        let tab = app.tabBars.buttons["Feeds"]

        guard tab.exists else {
            return
        }

        tab.tap()

        let add = app.navigationBars["Feeds"].buttons["Add"]
        guard add.exists else {
            return
        }

        add.tap()
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

        let tab = app.tabBars.buttons["Profile"]

        guard tab.exists else {
            return
        }

        tab.tap()

        let button = app.buttons["icon settings"]

        guard button.exists else {
            return
        }

        button.tap()
        
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

        let tab = app.tabBars.buttons["Contacts"]

        guard tab.exists else {
            return
        }

        tab.tap()

        let add = app.navigationBars["Contacts"].buttons["Add"]
        guard add.exists else {
            return
        }
        add.tap()
        
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

        let textField = app.tables.searchFields["Search"]
        guard textField.exists else {
            return
        }
        textField.tap()

        let textField2 = app.searchFields["Search"]
        guard textField2.exists else {
            return
        }
        textField2.typeText("app")
        app.buttons["Done"].tap()

        app.buttons["Cancel"].tap()
    }

    func testSearchInContacts() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        let tab = app.tabBars.buttons["Contacts"]

        guard tab.exists else {
            return
        }

        tab.tap()

        let search = app.tables.searchFields["Search Friend"]
        guard search.exists else {
            return
        }
        search.tap()

        let textField = app.searchFields["Search Friend"]
        guard textField.exists else {
            return
        }
        textField.tap()
        textField.typeText("test")
        app.buttons["Done"].tap()

        let test = app.tables.staticTexts["test"]
        guard test.exists else {
            return
        }
        test.tap()

        app.navigationBars["test"].buttons["icon back"].tap()

        app.buttons["Cancel"].tap()
    }

    func testSearchInFeeds() {

        let app = XCUIApplication()

        guard app.tabBars.count > 0 else {
            return
        }

        let tab = app.tabBars.buttons["Feeds"]

        guard tab.exists else {
            return
        }

        tab.tap()

        let search = app.tables.searchFields["Search Feeds"]
        guard search.exists else {
            return
        }
        search.tap()

        let textField = app.searchFields["Search Feeds"]
        guard textField.exists else {
            return
        }
        textField.tap()
        textField.typeText("Hello")
        app.buttons["Done"].tap()

        app.buttons["Cancel"].tap()
    }
}


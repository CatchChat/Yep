//
//  RealmTests.swift
//  Yep
//
//  Created by NIX on 16/4/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest
@testable import YepKit
import RealmSwift

final class RealmTests: XCTestCase {

    func testCreateMessageAndDelete() {

        let realm = try! Realm()

        let messages: [Message] = (0..<100).map({ index in
            let message = Message()
            message.messageID = "test\(index)"
            return message
        })

        do {
            messages.forEach({
                realm.beginWrite()
                realm.add($0)
                try! realm.commitWrite()
            })

            let firstMessage = messages.first!
            XCTAssertFalse(firstMessage.invalidated)
        }

        realm.refresh()

        do {
            messages.forEach({
                realm.beginWrite()
                realm.delete($0)
                try! realm.commitWrite()
            })

            let lastMessage = messages.last!
            XCTAssertTrue(lastMessage.invalidated)
        }
    }
}


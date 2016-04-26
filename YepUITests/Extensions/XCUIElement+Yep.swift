//
//  XCUIElement+Yep.swift
//  Yep
//
//  Created by NIX on 16/4/26.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import XCTest

extension XCUIElement {

    func clearAndEnterText(text: String) -> Void {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        var deleteString: String = ""
        for _ in stringValue.characters {
            deleteString += "\u{8}"
        }
        self.typeText(deleteString)

        self.typeText(text)
    }
}


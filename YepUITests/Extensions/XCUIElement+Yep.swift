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

        guard let stringValue = value as? String else {
            return
        }

        var deleteString: String = ""
        for _ in stringValue.characters {
            deleteString += "\u{8}"
        }
        typeText(deleteString)

        typeText(text)
    }
}


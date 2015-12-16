//
//  ChatTextContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/8/25.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatTextContainerView: UIView {

    override func canBecomeFirstResponder() -> Bool {
        return false
    }

    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        if action == "copyText" {
            return true
        } else if action == "deleteTextMessage" {
            return true
        }

        return false
    }

    var copyTextAction: (() -> Void)?
    var deleteTextMessageAction: (() -> Void)?

    func copyText() {
        println("copyText")
        copyTextAction?()
    }

    func deleteTextMessage() {
        println("deleteTextMessage")
        deleteTextMessageAction?()
    }
}

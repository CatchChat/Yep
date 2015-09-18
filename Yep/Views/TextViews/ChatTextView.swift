//
//  ChatTextView.swift
//  Yep
//
//  Created by NIX on 15/6/26.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatTextView: UITextView {

    var menuLongPressGestureRecognizer: UILongPressGestureRecognizer!

    override func canBecomeFirstResponder() -> Bool {
        return false
    }

    override func addGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {

        if NSProcessInfo().isOperatingSystemAtLeastVersion(NSOperatingSystemVersion(majorVersion: 9, minorVersion: 0, patchVersion: 0)) {
            if let longPressGestureRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
                return
            }
        }

        super.addGestureRecognizer(gestureRecognizer)
    }
}


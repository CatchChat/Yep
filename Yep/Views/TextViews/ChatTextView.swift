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
                if longPressGestureRecognizer.minimumPressDuration == 0.5 {
                    return
                    //longPressGestureRecognizer.delegate = self
                    //longPressGestureRecognizer.enabled = false
                    //longPressGestureRecognizer.numberOfTouchesRequired = 5

                }
            }
        }

        super.addGestureRecognizer(gestureRecognizer)
    }

//    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        if gestureRecognizer is UILongPressGestureRecognizer {
//            return false
//        }
//
//        return super.gestureRecognizerShouldBegin(gestureRecognizer)
//    }
}


extension ChatTextView: UIGestureRecognizerDelegate {

//    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        if gestureRecognizer is UILongPressGestureRecognizer {
//            return false
//        }
//
//        return super.gestureRecognizerShouldBegin(gestureRecognizer)
//    }

//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }

//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOfGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer is UILongPressGestureRecognizer {
//            return true
//        }
//        return false
//    }

//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//
//        if gestureRecognizer is UILongPressGestureRecognizer {
//            return true
//        }
//
//        return false
//    }

//    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
//        if gestureRecognizer is UILongPressGestureRecognizer {
//            return false
//        }
//
//        return true
//    }
}


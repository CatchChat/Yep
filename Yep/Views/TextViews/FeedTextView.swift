//
//  FeedTextView.swift
//  Yep
//
//  Created by nixzhu on 15/10/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class FeedTextView: UITextView {
    
    override var canBecomeFirstResponder : Bool {
        return false
    }

    var touchesBeganAction: (() -> Void)?
    var touchesEndedAction: (() -> Void)?
    var touchesCancelledAction: (() -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touchesBeganAction?()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchesEndedAction?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchesCancelledAction?()
    }
    
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        
        // iOS 9 以上，强制不添加文字选择长按手势，免去触发选择文字
        // 共有四种长按手势，iOS 9 正式版里分别加了两次：0.1 Reveal，0.12 tap link，0.5 selection， 0.75 press link
        if let longPressGestureRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
            if longPressGestureRecognizer.minimumPressDuration == 0.5 {
                return
            }
        }

        super.addGestureRecognizer(gestureRecognizer)
    }
}


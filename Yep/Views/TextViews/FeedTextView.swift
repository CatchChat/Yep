//
//  FeedTextView.swift
//  Yep
//
//  Created by nixzhu on 15/10/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedTextView: UITextView {
    
    var tapGesture: UITapGestureRecognizer!
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        tapGesture = UITapGestureRecognizer(target: self, action: "doTap")
        addGestureRecognizer(tapGesture)
    }
    
    func doTap() {
        if let touchesEndedAction = touchesEndedAction {
            touchesEndedAction()
        }
    }

    override func canBecomeFirstResponder() -> Bool {
        return false
    }

    var touchesBeganAction: (() -> Void)?
    var touchesEndedAction: (() -> Void)?
    var touchesCancelledAction: (() -> Void)?

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        touchesBeganAction?()
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
//        touchesEndedAction?()
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        touchesCancelledAction?()
    }
    
    override func addGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        
        // iOS 9 以上，强制不添加文字选择长按手势，免去触发选择文字
        // 共有四种长按手势，iOS 9 正式版里分别加了两次：0.1 Reveal，0.12 tap link，0.5 selection， 0.75 press link
        if isOperatingSystemAtLeastMajorVersion(9) {
            if let longPressGestureRecognizer = gestureRecognizer as? UILongPressGestureRecognizer {
                if longPressGestureRecognizer.minimumPressDuration == 0.5 {
                    return
                }
            }
        }
        
        super.addGestureRecognizer(gestureRecognizer)
    }
}




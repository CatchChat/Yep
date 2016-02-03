//
//  UIButton+Yep.swift
//  Yep
//
//  Created by kevinzhow on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepButton: UIButton {
    
    var yepTouchBegin : (() -> ())?
    
    var yepTouchesEnded : (() -> ())?
    
    var yepTouchesCancelled : (() -> ())?
    
    var yepTouchesMoved : (() -> ())?
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        if let yepTouchBegin = yepTouchBegin {
            yepTouchBegin()
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        if let yepTouchesEnded = yepTouchesEnded {
            yepTouchesEnded()
        }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        if let yepTouchesCancelled = yepTouchesCancelled {
            yepTouchesCancelled()
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)

        if let yepTouchesMoved = yepTouchesMoved {
            yepTouchesMoved()
        }
    }
}

    
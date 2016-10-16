//
//  UIButton+Yep.swift
//  Yep
//
//  Created by kevinzhow on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class YepButton: UIButton {
    
    var yepTouchBegin : (() -> ())?
    
    var yepTouchesEnded : (() -> ())?
    
    var yepTouchesCancelled : (() -> ())?
    
    var yepTouchesMoved : (() -> ())?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if let yepTouchBegin = yepTouchBegin {
            yepTouchBegin()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        if let yepTouchesEnded = yepTouchesEnded {
            yepTouchesEnded()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        if let yepTouchesCancelled = yepTouchesCancelled {
            yepTouchesCancelled()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)

        if let yepTouchesMoved = yepTouchesMoved {
            yepTouchesMoved()
        }
    }
}

    

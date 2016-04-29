//
//  TouchClosuresView.swift
//  Yep
//
//  Created by nixzhu on 15/10/13.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class TouchClosuresView: UIView {

    var touchesBeganAction: (() -> Void)?
    var touchesEndedAction: (() -> Void)?
    var touchesCancelledAction: (() -> Void)?

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchesBeganAction?()
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        touchesEndedAction?()
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        touchesCancelledAction?()
    }
}


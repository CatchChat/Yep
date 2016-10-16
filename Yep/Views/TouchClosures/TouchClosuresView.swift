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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesBeganAction?()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEndedAction?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesCancelledAction?()
    }
}


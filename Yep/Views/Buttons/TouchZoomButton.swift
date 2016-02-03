//
//  TouchZoomButton.swift
//  Yep
//
//  Created by NIX on 15/4/21.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import pop

class TouchZoomButton: UIButton {

    enum TouchZoom {
        case In
        case Out
    }

    var touchZoom: TouchZoom = .Out

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        switch touchZoom {

        case .In:
            scaleBigger()

        case .Out:
            scaleSmaller()
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)

        scaleNormal()
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)

        scaleNormal()
    }

    private func scaleBigger() {
        layer.pop_removeAnimationForKey("scaleNormal")

        let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        anim.springBounciness = 10
        anim.springSpeed = 20
        anim.fromValue = NSValue(CGPoint: CGPoint(x: 1.0, y: 1.0))
        anim.toValue = NSValue(CGPoint: CGPoint(x: 1.1, y: 1.1))

        layer.pop_addAnimation(anim, forKey: "scaleBigger")
    }

    private func scaleSmaller() {
        layer.pop_removeAnimationForKey("scaleNormal")

        let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        anim.springBounciness = 10
        anim.springSpeed = 20
        anim.fromValue = NSValue(CGPoint: CGPoint(x: 1.0, y: 1.0))
        anim.toValue = NSValue(CGPoint: CGPoint(x: 0.9, y: 0.9))

        layer.pop_addAnimation(anim, forKey: "scaleSmaller")
    }

    private func scaleNormal() {
        layer.pop_removeAnimationForKey("scaleSmaller")

        let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        anim.springBounciness = 10
        anim.springSpeed = 20
        //anim.fromValue = NSValue(CGPoint: CGPoint(x: 1.2, y: 1.2))
        anim.toValue = NSValue(CGPoint: CGPoint(x: 1.0, y: 1.0))

        layer.pop_addAnimation(anim, forKey: "scaleNormal")
    }
}


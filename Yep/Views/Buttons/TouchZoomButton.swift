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
        case `in`
        case out
    }

    var touchZoom: TouchZoom = .out

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        switch touchZoom {

        case .in:
            scaleBigger()

        case .out:
            scaleSmaller()
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)

        scaleNormal()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)

        scaleNormal()
    }

    fileprivate func scaleBigger() {
        layer.pop_removeAnimation(forKey: "scaleNormal")

        let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        anim?.springBounciness = 10
        anim?.springSpeed = 20
        anim?.fromValue = NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0))
        anim?.toValue = NSValue(cgPoint: CGPoint(x: 1.1, y: 1.1))

        layer.pop_add(anim, forKey: "scaleBigger")
    }

    fileprivate func scaleSmaller() {
        layer.pop_removeAnimation(forKey: "scaleNormal")

        let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        anim?.springBounciness = 10
        anim?.springSpeed = 20
        anim?.fromValue = NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0))
        anim?.toValue = NSValue(cgPoint: CGPoint(x: 0.9, y: 0.9))

        layer.pop_add(anim, forKey: "scaleSmaller")
    }

    fileprivate func scaleNormal() {
        layer.pop_removeAnimation(forKey: "scaleSmaller")

        let anim = POPSpringAnimation(propertyNamed: kPOPLayerScaleXY)
        anim?.springBounciness = 10
        anim?.springSpeed = 20
        //anim.fromValue = NSValue(CGPoint: CGPoint(x: 1.2, y: 1.2))
        anim?.toValue = NSValue(cgPoint: CGPoint(x: 1.0, y: 1.0))

        layer.pop_add(anim, forKey: "scaleNormal")
    }
}


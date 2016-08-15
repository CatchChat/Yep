//
//  UIMotionEffect+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/15.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UIMotionEffect {

    class func twoAxesShift(strength: Float) -> UIMotionEffect {

        func motion(type: UIInterpolatingMotionEffectType) -> UIInterpolatingMotionEffect {
            let keyPath = type == .TiltAlongHorizontalAxis ? "center.x" : "center.y"
            let motion = UIInterpolatingMotionEffect(keyPath: keyPath, type: type)
            motion.minimumRelativeValue = -strength
            motion.maximumRelativeValue = strength
            return motion
        }

        let group = UIMotionEffectGroup()
        group.motionEffects = [
            motion(.TiltAlongHorizontalAxis),
            motion(.TiltAlongVerticalAxis),
        ]
        return group
    }
}


//
//  UIMotionEffect+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/15.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UIInterpolatingMotionEffectType {

    var yep_centerKeyPath: String {
        switch self {
        case .tiltAlongHorizontalAxis:
            return "center.x"
        case .tiltAlongVerticalAxis:
            return "center.y"
        }
    }
}

extension UIMotionEffect {

    class func yep_twoAxesShift(_ strength: Float) -> UIMotionEffect {

        func motion(_ type: UIInterpolatingMotionEffectType) -> UIInterpolatingMotionEffect {
            let keyPath = type.yep_centerKeyPath
            let motion = UIInterpolatingMotionEffect(keyPath: keyPath, type: type)
            motion.minimumRelativeValue = -strength
            motion.maximumRelativeValue = strength
            return motion
        }

        let group = UIMotionEffectGroup()
        group.motionEffects = [
            motion(.tiltAlongHorizontalAxis),
            motion(.tiltAlongVerticalAxis),
        ]
        return group
    }
}


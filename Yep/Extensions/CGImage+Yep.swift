//
//  CGImage+Yep.swift
//  Yep
//
//  Created by nixzhu on 16/1/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

extension CGImage {

    var yep_extendedCanvasCGImage: CGImage {

        let width = CGImageGetWidth(self)
        let height = CGImageGetHeight(self)

        guard width > 0 && height > 0 else {
            return self
        }

        func hasAlpha() -> Bool {
            let alpha = CGImageGetAlphaInfo(self)
            switch alpha {
            case .First, .Last, .PremultipliedFirst, .PremultipliedLast:
                return true
            default:
                return false
            }
        }

        var bitmapInfo = CGBitmapInfo.ByteOrder32Little.rawValue
        if hasAlpha() {
            bitmapInfo |= CGImageAlphaInfo.PremultipliedFirst.rawValue
        } else {
            bitmapInfo |= CGImageAlphaInfo.NoneSkipFirst.rawValue
        }

        guard let context = CGBitmapContextCreate(nil, width, height, 8, 0, CGColorSpaceCreateDeviceRGB(), bitmapInfo) else {
            return self
        }

        CGContextDrawImage(context, CGRect(x: 0, y: 0, width: width, height: height), self)

        guard let newCGImage = CGBitmapContextCreateImage(context) else {
            return self
        }
        
        return newCGImage
    }
}


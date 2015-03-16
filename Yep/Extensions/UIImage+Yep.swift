//
//  UIImage+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

extension UIImage {

    func roundImageOfRadius(radius: CGFloat) -> UIImage {
        return self.largestCenteredSquareImage().resizeToTargetSize(CGSize(width: radius * 2, height: radius * 2)).roundImage()
    }

    func largestCenteredSquareImage() -> UIImage {
        let scale = self.scale

        let originalWidth  = self.size.width * scale
        let originalHeight = self.size.height * scale

        let edge: CGFloat
        if originalWidth > originalHeight {
            edge = originalHeight
        } else {
            edge = originalWidth
        }

        let posX = (originalWidth  - edge) / 2.0
        let posY = (originalHeight - edge) / 2.0

        let cropSquare = CGRectMake(posX, posY, edge, edge)

        let imageRef = CGImageCreateWithImageInRect(self.CGImage, cropSquare)

        return UIImage(CGImage: imageRef, scale: scale, orientation: self.imageOrientation)!
    }

    func resizeToTargetSize(targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height

        let scale = UIScreen.mainScreen().scale
        let newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(scale * size.width * heightRatio, scale * size.height * heightRatio)
        } else {
            newSize = CGSizeMake(scale * size.width * widthRatio, scale * size.height * widthRatio)
        }

        let rect = CGRectMake(0, 0, newSize.width, newSize.height)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }

    func roundImage() -> UIImage {
        let scale: CGFloat = self.scale

        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)

        let context = UIGraphicsGetCurrentContext()

        var transform = CGAffineTransformConcat(CGAffineTransformIdentity, CGAffineTransformMakeScale(1.0, -1.0))
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0.0, self.size.height))
        CGContextConcatCTM(context, transform)

        let drawRect = CGRect(origin: CGPointZero, size: self.size)

        CGContextAddEllipseInRect(context, drawRect.largestCenteredSquare())
        CGContextClip(context)

        CGContextDrawImage(context, drawRect, self.CGImage)

        let roundImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return roundImage
    }
}

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

    func fixRotation() -> UIImage {
        if self.imageOrientation == .Up {
            return self
        }

        let width = self.size.width
        let height = self.size.height

        var transform = CGAffineTransformIdentity

        switch self.imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, width, height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))

        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))

        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))

        default:
            break
        }

        switch self.imageOrientation {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);

        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);

        default:
            break
        }

        let selfCGImage = self.CGImage
        var context = CGBitmapContextCreate(nil, Int(width), Int(height), CGImageGetBitsPerComponent(selfCGImage), 0, CGImageGetColorSpace(selfCGImage), CGImageGetBitmapInfo(selfCGImage));

        CGContextConcatCTM(context, transform)

        switch self.imageOrientation {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            CGContextDrawImage(context, CGRectMake(0,0, height, width), selfCGImage)

        default:
            CGContextDrawImage(context, CGRectMake(0,0, width, height), selfCGImage)
        }

        let cgImage = CGBitmapContextCreateImage(context)
        return UIImage(CGImage: cgImage)!
    }
}

// MARK: Message Image

enum MessageImageTailDirection {
    case Left
    case Right
}

extension UIImage {

    func cropToAspectRatio(aspectRatio: CGFloat) -> UIImage {
        let size = self.size

        let originalAspectRatio = size.width / size.height

        var rect = CGRectZero

        if originalAspectRatio > aspectRatio {
            let width = size.height * aspectRatio
            rect = CGRect(x: (size.width - width) * 0.5, y: 0, width: width, height: size.height)

        } else if originalAspectRatio < aspectRatio {
            let height = size.width / aspectRatio
            rect = CGRect(x: 0, y: (size.height - height) * 0.5, width: size.width, height: height)

        } else {
            return self
        }

        let cgImage = CGImageCreateWithImageInRect(self.CGImage, rect)
        return UIImage(CGImage: cgImage)!
    }

    private func bubblePathWithTailDirection(tailDirection: MessageImageTailDirection, size: CGSize) -> UIBezierPath {
        let scale = UIScreen.mainScreen().scale

        let cornerRadius: CGFloat = 20 * scale
        let tailOffset: CGFloat = 8 * scale
        let tailHeight: CGFloat = 8 * scale

        let width = size.width
        let height = size.height

        if tailDirection == .Right {

            let bubble = UIBezierPath()

            bubble.moveToPoint(CGPoint(x: cornerRadius, y: 0))
            bubble.addArcWithCenter(CGPoint(x: cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 1.5), endAngle: CGFloat(M_PI), clockwise: false)

            bubble.addLineToPoint(CGPoint(x: 0, y: height - cornerRadius))
            bubble.addArcWithCenter(CGPoint(x: cornerRadius, y: height - cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI * 0.5), clockwise: false)

            bubble.addLineToPoint(CGPoint(x: width - (cornerRadius + tailOffset), y: height))
            bubble.addArcWithCenter(CGPoint(x: width - (cornerRadius + tailOffset), y: height - cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 0.5), endAngle: CGFloat(M_PI * 2), clockwise: false)

            bubble.addLineToPoint(CGPoint(x: width, y: height - cornerRadius - tailHeight * 0.5))
            bubble.addLineToPoint(CGPoint(x: width - tailOffset, y: height - cornerRadius - tailHeight))

            bubble.addLineToPoint(CGPoint(x: width - tailOffset, y: cornerRadius))
            bubble.addArcWithCenter(CGPoint(x: width - (cornerRadius + tailOffset), y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(0), endAngle: CGFloat(M_PI * 1.5), clockwise: false)

            bubble.closePath()

            return bubble

        } else {

            let bubble = UIBezierPath()

            bubble.moveToPoint(CGPoint(x: width - cornerRadius, y: 0))
            bubble.addArcWithCenter(CGPoint(x: width - cornerRadius, y: cornerRadius), radius: cornerRadius, startAngle: -CGFloat(M_PI * 0.5), endAngle: 0, clockwise: true)

            bubble.addLineToPoint(CGPoint(x: width, y: height - cornerRadius))
            bubble.addArcWithCenter(CGPoint(x: width - cornerRadius, y: height - cornerRadius), radius: cornerRadius, startAngle: 0, endAngle: CGFloat(M_PI * 0.5), clockwise: true)

            bubble.addLineToPoint(CGPoint(x: cornerRadius + tailOffset, y: height))
            bubble.addArcWithCenter(CGPoint(x: cornerRadius + tailOffset, y: height - cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI * 0.5), endAngle: CGFloat(M_PI), clockwise: true)

            bubble.addLineToPoint(CGPoint(x: 0, y: height - cornerRadius - tailHeight * 0.5))
            bubble.addLineToPoint(CGPoint(x: tailOffset, y: height - cornerRadius - tailHeight))

            bubble.addLineToPoint(CGPoint(x: tailOffset, y: cornerRadius))
            bubble.addArcWithCenter(CGPoint(x: cornerRadius + tailOffset, y: cornerRadius), radius: cornerRadius, startAngle: CGFloat(M_PI), endAngle: CGFloat(M_PI * 1.5), clockwise: true)

            bubble.closePath()

            return bubble
        }
    }

    func bubbleImageWithTailDirection(tailDirection: MessageImageTailDirection) -> UIImage {
        let scale: CGFloat = self.scale

        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)

        let context = UIGraphicsGetCurrentContext()

        var transform = CGAffineTransformConcat(CGAffineTransformIdentity, CGAffineTransformMakeScale(1.0, -1.0))
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0.0, self.size.height))
        CGContextConcatCTM(context, transform)

        let drawRect = CGRect(origin: CGPointZero, size: self.size)

        let bubble = bubblePathWithTailDirection(tailDirection, size: self.size)
        CGContextAddPath(context, bubble.CGPath)
        CGContextClip(context)

        CGContextDrawImage(context, drawRect, self.CGImage)

        let roundImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        
        return roundImage
    }

//    func bubbleImageWithTailDirection(tailDirection: MessageImageTailDirection, size: CGSize) -> UIImage {
//        let bubbleImage = self.fixRotation().cropToAspectRatio(size.width / size.height).resizeToTargetSize(size).bubbleImageWithTailDirection(tailDirection)
//
//        return bubbleImage
//    }
}

extension UIImage {

    func imageWithGradientTintColor(tintColor: UIColor) -> UIImage {
        return imageWithTintColor(tintColor, blendMode: kCGBlendModeOverlay)
    }


    func imageWithTintColor(tintColor: UIColor, blendMode: CGBlendMode) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        tintColor.setFill()

        let bounds = CGRect(origin: CGPointZero, size: size)

        UIRectFill(bounds)

        self.drawInRect(bounds, blendMode: blendMode, alpha: 1)

        if blendMode.value != kCGBlendModeDestinationIn.value {
            self.drawInRect(bounds, blendMode: kCGBlendModeDestinationIn, alpha: 1)
        }

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return tintedImage
    }
}

extension UIImage {

    func renderAtSize(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)

        //let scale: CGFloat = self.scale

        //UIGraphicsBeginImageContextWithOptions(self.size, false, scale)

        let context = UIGraphicsGetCurrentContext()

        self.drawInRect(CGRect(origin: CGPointZero, size: size))

        let cgImage = CGBitmapContextCreateImage(context)

        let image = UIImage(CGImage: cgImage)!

        UIGraphicsEndImageContext()

        return image
    }


    func maskWithImage(maskImage: UIImage) -> UIImage {
        //UIGraphicsBeginImageContext(size)

        let scale = UIScreen.mainScreen().scale
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)

        let context = UIGraphicsGetCurrentContext()

        var transform = CGAffineTransformConcat(CGAffineTransformIdentity, CGAffineTransformMakeScale(1.0, -1.0))
        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0.0, self.size.height))
        CGContextConcatCTM(context, transform)

        let drawRect = CGRect(origin: CGPointZero, size: self.size)

        CGContextClipToMask(context, drawRect, maskImage.CGImage)

        CGContextDrawImage(context, drawRect, self.CGImage)

        let roundImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()
        
        return roundImage
    }

    func bubbleImageWithTailDirection(tailDirection: MessageImageTailDirection, size: CGSize) -> UIImage {

        let scale = UIScreen.mainScreen().scale
        let orientation: UIImageOrientation = tailDirection == .Left ? .Up : .UpMirrored
        var maskImage = UIImage(CGImage: UIImage(named: "left_tail_image_bubble")!.CGImage, scale: scale, orientation: orientation)!
        maskImage = maskImage.resizableImageWithCapInsets(UIEdgeInsets(top: 25, left: 26, bottom: 20, right: 20), resizingMode: UIImageResizingMode.Stretch)
        maskImage = maskImage.renderAtSize(size)

        let bubbleImage = self.fixRotation().cropToAspectRatio(size.width / size.height).resizeToTargetSize(size).maskWithImage(maskImage)

        return bubbleImage
    }

//    func maskWithImage(maskImage: UIImage) -> UIImage {
//        //UIGraphicsBeginImageContext(size)
//        
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
//        let context = CGBitmapContextCreate(nil, Int(maskImage.size.width), Int(maskImage.size.height), 8, 0, colorSpace, bitmapInfo)
//
////        var transform = CGAffineTransformConcat(CGAffineTransformIdentity, CGAffineTransformMakeScale(1.0, -1.0))
////        transform = CGAffineTransformConcat(transform, CGAffineTransformMakeTranslation(0.0, self.size.height))
////        CGContextConcatCTM(context, transform)
//
//        let drawRect = CGRect(origin: CGPointZero, size: self.size)
//
//        CGContextClipToMask(context, drawRect, maskImage.CGImage)
//
//        CGContextDrawImage(context, drawRect, self.CGImage)
//
//        let cgImage = CGBitmapContextCreateImage(context)!
//
//        //UIGraphicsEndImageContext()
//
//        return UIImage(CGImage: cgImage)!
//    }
}

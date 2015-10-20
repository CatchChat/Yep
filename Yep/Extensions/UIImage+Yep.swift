//
//  UIImage+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

extension UIImage {

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
        let context = CGBitmapContextCreate(nil, Int(width), Int(height), CGImageGetBitsPerComponent(selfCGImage), 0, CGImageGetColorSpace(selfCGImage), CGImageGetBitmapInfo(selfCGImage).rawValue);

        CGContextConcatCTM(context, transform)

        switch self.imageOrientation {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            CGContextDrawImage(context, CGRectMake(0,0, height, width), selfCGImage)

        default:
            CGContextDrawImage(context, CGRectMake(0,0, width, height), selfCGImage)
        }

        let cgImage = CGBitmapContextCreateImage(context)!
        return UIImage(CGImage: cgImage)
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

        let cgImage = CGImageCreateWithImageInRect(self.CGImage, rect)!
        return UIImage(CGImage: cgImage)
    }
/*
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

    func bubbleImageWithTailDirection(tailDirection: MessageImageTailDirection, size: CGSize) -> UIImage {
        let bubbleImage = self.fixRotation().cropToAspectRatio(size.width / size.height).resizeToTargetSize(size).bubbleImageWithTailDirection(tailDirection)

        return bubbleImage
    }
*/
}

extension UIImage {

    func imageWithGradientTintColor(tintColor: UIColor) -> UIImage {
        return imageWithTintColor(tintColor, blendMode: CGBlendMode.Overlay)
    }


    func imageWithTintColor(tintColor: UIColor, blendMode: CGBlendMode) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        tintColor.setFill()

        let bounds = CGRect(origin: CGPointZero, size: size)

        UIRectFill(bounds)

        self.drawInRect(bounds, blendMode: blendMode, alpha: 1)

        if blendMode != CGBlendMode.DestinationIn {
            self.drawInRect(bounds, blendMode: CGBlendMode.DestinationIn, alpha: 1)
        }

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return tintedImage
    }
}

extension UIImage {

    func renderAtSize(size: CGSize) -> UIImage {

        // 确保 size 为整数，防止 mask 里出现白线
        let size = CGSize(width: ceil(size.width), height: ceil(size.height))

        UIGraphicsBeginImageContextWithOptions(size, false, 0) // key

        let context = UIGraphicsGetCurrentContext()

        drawInRect(CGRect(origin: CGPointZero, size: size))

        let cgImage = CGBitmapContextCreateImage(context)!

        let image = UIImage(CGImage: cgImage)

        UIGraphicsEndImageContext()

        return image
    }

    func maskWithImage(maskImage: UIImage) -> UIImage {

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

    struct BubbleMaskImage {

        static let leftTail: UIImage = {
            let scale = UIScreen.mainScreen().scale
            let orientation: UIImageOrientation = .Up
            var maskImage = UIImage(CGImage: UIImage(named: "left_tail_image_bubble")!.CGImage!, scale: scale, orientation: orientation)
            maskImage = maskImage.resizableImageWithCapInsets(UIEdgeInsets(top: 25, left: 27, bottom: 20, right: 20), resizingMode: UIImageResizingMode.Stretch)
            return maskImage
            }()

        static let rightTail: UIImage = {
            let scale = UIScreen.mainScreen().scale
            let orientation: UIImageOrientation = .UpMirrored
            var maskImage = UIImage(CGImage: UIImage(named: "left_tail_image_bubble")!.CGImage!, scale: scale, orientation: orientation)
            maskImage = maskImage.resizableImageWithCapInsets(UIEdgeInsets(top: 25, left: 27, bottom: 20, right: 20), resizingMode: UIImageResizingMode.Stretch)
            return maskImage
            }()
    }

    func bubbleImageWithTailDirection(tailDirection: MessageImageTailDirection, size: CGSize, forMap: Bool = false) -> UIImage {

        //let orientation: UIImageOrientation = tailDirection == .Left ? .Up : .UpMirrored

        let maskImage: UIImage

        if tailDirection == .Left {
            maskImage = BubbleMaskImage.leftTail.renderAtSize(size)
        } else {
            maskImage = BubbleMaskImage.rightTail.renderAtSize(size)
        }

        if forMap {
            let image = cropToAspectRatio(size.width / size.height).resizeToTargetSize(size)

            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)

            image.drawAtPoint(CGPointZero)

            //let bottomShadowImage = UIImage(named: "location_bottom_shadow")!
            //bottomShadowImage.drawAtPoint(CGPoint(x: 0, y: image.size.height - 20))
            /*
            let scale = UIScreen.mainScreen().scale
            let orientation: UIImageOrientation = .Up
            var bottomShadowImage = UIImage(CGImage: UIImage(named: "location_bottom_shadow")!.CGImage, scale: scale, orientation: orientation)!
            bottomShadowImage = bottomShadowImage.resizableImageWithCapInsets(UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1), resizingMode: UIImageResizingMode.Stretch)
            bottomShadowImage.drawInRect(CGRect(x: 0, y: image.size.height - 20, width: image.size.width, height: 20))
            */
            let bottomShadowImage = UIImage(named: "location_bottom_shadow")!
            let bottomShadowHeightRatio: CGFloat = 0.185 // 20 / 108
            bottomShadowImage.drawInRect(CGRect(x: 0, y: floor(image.size.height * (1 - bottomShadowHeightRatio)), width: image.size.width, height: ceil(image.size.height * bottomShadowHeightRatio)))

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()

            let bubbleImage = finalImage.maskWithImage(maskImage)
            
            return bubbleImage
        }

        // fixRotation 会消耗大量内存，改在发送前做
        let bubbleImage = /*self.fixRotation().*/cropToAspectRatio(size.width / size.height).resizeToTargetSize(size).maskWithImage(maskImage)

        return bubbleImage
    }

}

// MARK: - Decode

extension UIImage {

    func decodedImage() -> UIImage {
        return decodedImage(scale: scale)
    }

    func decodedImage(scale scale: CGFloat) -> UIImage {
        let imageRef = CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context = CGBitmapContextCreate(nil, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef), 8, 0, colorSpace, bitmapInfo.rawValue)

        if let context = context {
            let rect = CGRectMake(0, 0, CGFloat(CGImageGetWidth(imageRef)), CGFloat(CGImageGetHeight(imageRef)))
            CGContextDrawImage(context, rect, imageRef)
            let decompressedImageRef = CGBitmapContextCreateImage(context)!

            return UIImage(CGImage: decompressedImageRef, scale: scale, orientation: imageOrientation) ?? self
        }

        return self
    }
}


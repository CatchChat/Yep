//
//  UIImage+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler
import ImageIO
import MobileCoreServices

extension UIImage {

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

        let imageRef = CGImageCreateWithImageInRect(self.CGImage, cropSquare)!

        return UIImage(CGImage: imageRef, scale: scale, orientation: self.imageOrientation)
    }

    func resizeToTargetSize(targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height

        let scale = UIScreen.mainScreen().scale
        let newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSizeMake(scale * floor(size.width * heightRatio), scale * floor(size.height * heightRatio))
        } else {
            newSize = CGSizeMake(scale * floor(size.width * widthRatio), scale * floor(size.height * widthRatio))
        }

        let rect = CGRectMake(0, 0, floor(newSize.width), floor(newSize.height))

        //println("size: \(size), newSize: \(newSize), rect: \(rect)")

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.drawInRect(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }

    func scaleToMinSideLength(sideLength: CGFloat) -> UIImage {

        let pixelSideLength = sideLength * UIScreen.mainScreen().scale

        //println("pixelSideLength: \(pixelSideLength)")
        //println("size: \(size)")

        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale

        //println("pixelWidth: \(pixelWidth)")
        //println("pixelHeight: \(pixelHeight)")

        let newSize: CGSize

        if pixelWidth > pixelHeight {

            guard pixelHeight > pixelSideLength else {
                return self
            }

            let newHeight = pixelSideLength
            let newWidth = (pixelSideLength / pixelHeight) * pixelWidth
            newSize = CGSize(width: floor(newWidth), height: floor(newHeight))

        } else {

            guard pixelWidth > pixelSideLength else {
                return self
            }

            let newWidth = pixelSideLength
            let newHeight = (pixelSideLength / pixelWidth) * pixelHeight
            newSize = CGSize(width: floor(newWidth), height: floor(newHeight))
        }

        if scale == UIScreen.mainScreen().scale {
            let newSize = CGSize(width: floor(newSize.width / scale), height: floor(newSize.height / scale))
            //println("A scaleToMinSideLength newSize: \(newSize)")

            UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
            let rect = CGRectMake(0, 0, newSize.width, newSize.height)
            self.drawInRect(rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let image = newImage {
                return image
            }

            return self

        } else {
            //println("B scaleToMinSideLength newSize: \(newSize)")
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            let rect = CGRectMake(0, 0, newSize.width, newSize.height)
            self.drawInRect(rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let image = newImage {
                return image
            }

            return self
        }
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
            let orientation: UIImageOrientation = .Up
            var maskImage = UIImage(CGImage: UIImage(named: "right_tail_image_bubble")!.CGImage!, scale: scale, orientation: orientation)
            maskImage = maskImage.resizableImageWithCapInsets(UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 27), resizingMode: UIImageResizingMode.Stretch)
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

// MARK: Resize

extension UIImage {

    func resizeToSize(size: CGSize, withTransform transform: CGAffineTransform, drawTransposed: Bool, interpolationQuality: CGInterpolationQuality) -> UIImage? {

        let newRect = CGRectIntegral(CGRect(origin: CGPointZero, size: size))
        let transposedRect = CGRect(origin: CGPointZero, size: CGSize(width: size.height, height: size.width))

        let bitmapContext = CGBitmapContextCreate(nil, Int(newRect.width), Int(newRect.height), CGImageGetBitsPerComponent(CGImage), 0, CGImageGetColorSpace(CGImage), CGImageGetBitmapInfo(CGImage).rawValue)

        CGContextConcatCTM(bitmapContext, transform)

        CGContextSetInterpolationQuality(bitmapContext, interpolationQuality)

        CGContextDrawImage(bitmapContext, drawTransposed ? transposedRect : newRect, CGImage)

        let newCGImage = CGBitmapContextCreateImage(bitmapContext)!
        let newImage = UIImage(CGImage: newCGImage)

        return newImage
    }

    func transformForOrientationWithSize(size: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransformIdentity

        switch imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))

        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))

        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))

        default:
            break
        }

        switch imageOrientation {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)

        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)

        default:
            break
        }

        return transform
    }

    func resizeToSize(size: CGSize, withInterpolationQuality interpolationQuality: CGInterpolationQuality) -> UIImage? {

        let drawTransposed: Bool

        switch imageOrientation {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            drawTransposed = true
        default:
            drawTransposed = false
        }

        return resizeToSize(size, withTransform: transformForOrientationWithSize(size), drawTransposed: drawTransposed, interpolationQuality: interpolationQuality)
    }
}

extension UIImage {

    var yep_avarageColor: UIColor {

        let rgba = UnsafeMutablePointer<CUnsignedChar>.alloc(4)
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceRGB()!
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context: CGContextRef = CGBitmapContextCreate(rgba, 1, 1, 8, 4, colorSpace, info.rawValue)!

        CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), CGImage)

        let alpha: CGFloat = (rgba[3] > 0) ? (CGFloat(rgba[3]) / 255.0) : 1
        let multiplier = alpha / 255.0

        return UIColor(red: CGFloat(rgba[0]) * multiplier, green: CGFloat(rgba[1]) * multiplier, blue: CGFloat(rgba[2]) * multiplier, alpha: alpha)
    }
}

// MARK: Progressive

extension UIImage {

    var yep_progressiveImage: UIImage? {

        guard let cgImage = CGImage else {
            return nil
        }

        let data = NSMutableData()

        guard let distination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
            return nil
        }

        let jfifProperties = [
            kCGImagePropertyJFIFIsProgressive as String: kCFBooleanTrue as Bool,
            kCGImagePropertyJFIFXDensity as String: 72,
            kCGImagePropertyJFIFYDensity as String: 72,
            kCGImagePropertyJFIFDensityUnit as String: 1,
        ]

        let properties = [
            kCGImageDestinationLossyCompressionQuality as String: 0.9,
            kCGImagePropertyJFIFDictionary as String: jfifProperties,
        ]

        CGImageDestinationAddImage(distination, cgImage, properties)

        guard CGImageDestinationFinalize(distination) else {
            return nil
        }

        guard data.length > 0 else {
            return nil
        }

        guard let progressiveImage = UIImage(data: data) else {
            return nil
        }

        return progressiveImage
    }
}


//
//  UIImage+Yep.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices.UTType
import Ruler

public extension UIImage {

    public var yep_fixedSize: CGSize {

        let imageWidth = self.size.width
        let imageHeight = self.size.height

        let fixedImageWidth: CGFloat
        let fixedImageHeight: CGFloat

        if imageWidth > imageHeight {
            fixedImageHeight = min(imageHeight, Config.Media.imageHeight)
            fixedImageWidth = imageWidth * (fixedImageHeight / imageHeight)
        } else {
            fixedImageWidth = min(imageWidth, Config.Media.imageWidth)
            fixedImageHeight = imageHeight * (fixedImageWidth / imageWidth)
        }

        return CGSize(width: fixedImageWidth, height: fixedImageHeight)
    }
}

public extension UIImage {

    public func largestCenteredSquareImage() -> UIImage {
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

        let cropSquare = CGRect(x: posX, y: posY, width: edge, height: edge)

        let imageRef = self.cgImage!.cropping(to: cropSquare)!

        return UIImage(cgImage: imageRef, scale: scale, orientation: self.imageOrientation)
    }

    public func resizeToTargetSize(_ targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize.width  / self.size.width
        let heightRatio = targetSize.height / self.size.height

        let scale = UIScreen.main.scale
        let newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: scale * floor(size.width * heightRatio), height: scale * floor(size.height * heightRatio))
        } else {
            newSize = CGSize(width: scale * floor(size.width * widthRatio), height: scale * floor(size.height * widthRatio))
        }

        let rect = CGRect(x: 0, y: 0, width: floor(newSize.width), height: floor(newSize.height))

        //println("size: \(size), newSize: \(newSize), rect: \(rect)")

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage!
    }

    public func scaleToMinSideLength(_ sideLength: CGFloat) -> UIImage {

        let pixelSideLength = sideLength * UIScreen.main.scale

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

        if scale == UIScreen.main.scale {
            let newSize = CGSize(width: floor(newSize.width / scale), height: floor(newSize.height / scale))
            //println("A scaleToMinSideLength newSize: \(newSize)")

            UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let image = newImage {
                return image
            }

            return self

        } else {
            //println("B scaleToMinSideLength newSize: \(newSize)")
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
            self.draw(in: rect)
            let newImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()

            if let image = newImage {
                return image
            }

            return self
        }
    }

    public func fixRotation() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }

        let width = self.size.width
        let height = self.size.height

        var transform = CGAffineTransform.identity

        switch self.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: width, y: height)
            transform = transform.rotated(by: CGFloat(M_PI))

        case .left, .leftMirrored:
            transform = transform.translatedBy(x: width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))

        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))

        default:
            break
        }

        switch self.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: width, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);

        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);

        default:
            break
        }

        let selfCGImage = self.cgImage
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: selfCGImage!.bitsPerComponent, bytesPerRow: 0, space: selfCGImage!.colorSpace!, bitmapInfo: selfCGImage!.bitmapInfo.rawValue);

        context!.concatenate(transform)

        switch self.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context!.draw(selfCGImage!, in: CGRect(x: 0,y: 0, width: height, height: width))

        default:
            context!.draw(selfCGImage!, in: CGRect(x: 0,y: 0, width: width, height: height))
        }

        let cgImage = context!.makeImage()!
        return UIImage(cgImage: cgImage)
    }
}

// MARK: Message Image

public enum MessageImageTailDirection {
    case left
    case right
}

public extension UIImage {

    public func cropToAspectRatio(_ aspectRatio: CGFloat) -> UIImage {
        let size = self.size

        let originalAspectRatio = size.width / size.height

        var rect = CGRect.zero

        if originalAspectRatio > aspectRatio {
            let width = size.height * aspectRatio
            rect = CGRect(x: (size.width - width) * 0.5, y: 0, width: width, height: size.height)

        } else if originalAspectRatio < aspectRatio {
            let height = size.width / aspectRatio
            rect = CGRect(x: 0, y: (size.height - height) * 0.5, width: size.width, height: height)

        } else {
            return self
        }

        let cgImage = self.cgImage!.cropping(to: rect)!
        return UIImage(cgImage: cgImage)
    }
}

public extension UIImage {

    public func imageWithGradientTintColor(_ tintColor: UIColor) -> UIImage {

        return imageWithTintColor(tintColor, blendMode: CGBlendMode.overlay)
    }

    public func imageWithTintColor(_ tintColor: UIColor, blendMode: CGBlendMode) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        tintColor.setFill()

        let bounds = CGRect(origin: CGPoint.zero, size: size)

        UIRectFill(bounds)

        self.draw(in: bounds, blendMode: blendMode, alpha: 1)

        if blendMode != CGBlendMode.destinationIn {
            self.draw(in: bounds, blendMode: CGBlendMode.destinationIn, alpha: 1)
        }

        let tintedImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return tintedImage!
    }
}

public extension UIImage {

    public func renderAtSize(_ size: CGSize) -> UIImage {

        // 确保 size 为整数，防止 mask 里出现白线
        let size = CGSize(width: ceil(size.width), height: ceil(size.height))

        UIGraphicsBeginImageContextWithOptions(size, false, 0) // key

        let context = UIGraphicsGetCurrentContext()

        draw(in: CGRect(origin: CGPoint.zero, size: size))

        let cgImage = context!.makeImage()!

        let image = UIImage(cgImage: cgImage)

        UIGraphicsEndImageContext()

        return image
    }

    public func maskWithImage(_ maskImage: UIImage) -> UIImage {

        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)

        let context = UIGraphicsGetCurrentContext()

        var transform = CGAffineTransform.identity.concatenating(CGAffineTransform(scaleX: 1.0, y: -1.0))
        transform = transform.concatenating(CGAffineTransform(translationX: 0.0, y: self.size.height))
        context!.concatenate(transform)

        let drawRect = CGRect(origin: CGPoint.zero, size: self.size)

        context!.clip(to: drawRect, mask: maskImage.cgImage!)

        context!.draw(self.cgImage!, in: drawRect)

        let roundImage = UIGraphicsGetImageFromCurrentImageContext()

        UIGraphicsEndImageContext()

        return roundImage!
    }

    public struct BubbleMaskImage {

        public static let leftTail: UIImage = {
            let scale = UIScreen.main.scale
            let orientation: UIImageOrientation = .up
            var maskImage = UIImage(cgImage: UIImage(named: "left_tail_image_bubble")!.cgImage!, scale: scale, orientation: orientation)
            maskImage = maskImage.resizableImage(withCapInsets: UIEdgeInsets(top: 25, left: 27, bottom: 20, right: 20), resizingMode: UIImageResizingMode.stretch)
            return maskImage
        }()

        public static let rightTail: UIImage = {
            let scale = UIScreen.main.scale
            let orientation: UIImageOrientation = .up
            var maskImage = UIImage(cgImage: UIImage(named: "right_tail_image_bubble")!.cgImage!, scale: scale, orientation: orientation)
            maskImage = maskImage.resizableImage(withCapInsets: UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 27), resizingMode: UIImageResizingMode.stretch)
            return maskImage
        }()
    }

    public func bubbleImageWithTailDirection(_ tailDirection: MessageImageTailDirection, size: CGSize, forMap: Bool = false) -> UIImage {

        //let orientation: UIImageOrientation = tailDirection == .Left ? .Up : .UpMirrored

        let maskImage: UIImage

        if tailDirection == .left {
            maskImage = BubbleMaskImage.leftTail.renderAtSize(size)
        } else {
            maskImage = BubbleMaskImage.rightTail.renderAtSize(size)
        }

        if forMap {
            let image = cropToAspectRatio(size.width / size.height).resizeToTargetSize(size)

            UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)

            image.draw(at: CGPoint.zero)

            let bottomShadowImage = UIImage(named: "location_bottom_shadow")!
            let bottomShadowHeightRatio: CGFloat = 0.185 // 20 / 108
            bottomShadowImage.draw(in: CGRect(x: 0, y: floor(image.size.height * (1 - bottomShadowHeightRatio)), width: image.size.width, height: ceil(image.size.height * bottomShadowHeightRatio)))

            let finalImage = UIGraphicsGetImageFromCurrentImageContext()

            UIGraphicsEndImageContext()

            let bubbleImage = finalImage!.maskWithImage(maskImage)
            
            return bubbleImage
        }

        // fixRotation 会消耗大量内存，改在发送前做
        let bubbleImage = /*self.fixRotation().*/cropToAspectRatio(size.width / size.height).resizeToTargetSize(size).maskWithImage(maskImage)

        return bubbleImage
    }
}

// MARK: - Decode

public extension UIImage {

    public func decodedImage() -> UIImage {
        return decodedImage(scale: scale)
    }

    public func decodedImage(scale: CGFloat) -> UIImage {
        let imageRef = cgImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context = CGContext(data: nil, width: imageRef!.width, height: imageRef!.height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        if let context = context {
            let rect = CGRect(x: 0, y: 0, width: CGFloat(imageRef!.width), height: CGFloat(imageRef!.height))
            context.draw(imageRef!, in: rect)
            let decompressedImageRef = context.makeImage()!

            return UIImage(cgImage: decompressedImageRef, scale: scale, orientation: imageOrientation)
        }

        return self
    }
}

// MARK: Resize

public extension UIImage {

    public func resizeToSize(_ size: CGSize, withTransform transform: CGAffineTransform, drawTransposed: Bool, interpolationQuality: CGInterpolationQuality) -> UIImage? {

        let newRect = CGRect(origin: CGPoint.zero, size: size).integral
        let transposedRect = CGRect(origin: CGPoint.zero, size: CGSize(width: size.height, height: size.width))

        let bitmapContext = CGContext(data: nil, width: Int(newRect.width), height: Int(newRect.height), bitsPerComponent: cgImage!.bitsPerComponent, bytesPerRow: 0, space: cgImage!.colorSpace!, bitmapInfo: cgImage!.bitmapInfo.rawValue)

        bitmapContext!.concatenate(transform)

        bitmapContext!.interpolationQuality = interpolationQuality

        bitmapContext!.draw(cgImage!, in: drawTransposed ? transposedRect : newRect)

        if let newCGImage = bitmapContext!.makeImage() {
            let newImage = UIImage(cgImage: newCGImage)
            return newImage
        }

        return nil
    }

    public func transformForOrientationWithSize(_ size: CGSize) -> CGAffineTransform {
        var transform = CGAffineTransform.identity

        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat(M_PI))

        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat(M_PI_2))

        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat(-M_PI_2))

        default:
            break
        }

        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)

        default:
            break
        }

        return transform
    }

    public func resizeToSize(_ size: CGSize, withInterpolationQuality interpolationQuality: CGInterpolationQuality) -> UIImage? {

        let drawTransposed: Bool

        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            drawTransposed = true
        default:
            drawTransposed = false
        }

        return resizeToSize(size, withTransform: transformForOrientationWithSize(size), drawTransposed: drawTransposed, interpolationQuality: interpolationQuality)
    }
}

public extension UIImage {

    public var yep_avarageColor: UIColor {

        let rgba = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context: CGContext = CGContext(data: rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: info.rawValue)!

        context.draw(cgImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        let alpha: CGFloat = (rgba[3] > 0) ? (CGFloat(rgba[3]) / 255.0) : 1
        let multiplier = alpha / 255.0

        return UIColor(red: CGFloat(rgba[0]) * multiplier, green: CGFloat(rgba[1]) * multiplier, blue: CGFloat(rgba[2]) * multiplier, alpha: alpha)
    }
}

// MARK: Progressive

public extension UIImage {

    public var yep_progressiveImage: UIImage? {

        guard let cgImage = cgImage else {
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
        ] as [String : Any]

        let properties = [
            kCGImageDestinationLossyCompressionQuality as String: 0.9,
            kCGImagePropertyJFIFDictionary as String: jfifProperties,
        ] as [String : Any]

        CGImageDestinationAddImage(distination, cgImage, properties as CFDictionary?)

        guard CGImageDestinationFinalize(distination) else {
            return nil
        }

        guard data.length > 0 else {
            return nil
        }

        guard let progressiveImage = UIImage(data: data as Data) else {
            return nil
        }

        return progressiveImage
    }
}


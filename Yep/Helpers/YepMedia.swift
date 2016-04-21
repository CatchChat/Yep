//
//  YepMedia.swift
//  Yep
//
//  Created by nixzhu on 15/10/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

func metaDataStringOfImage(image: UIImage, needBlurThumbnail: Bool) -> String? {

    let metaDataInfo: [String: AnyObject]

    let imageWidth = image.size.width
    let imageHeight = image.size.height

    let thumbnailWidth: CGFloat
    let thumbnailHeight: CGFloat

    if imageWidth > imageHeight {
        thumbnailWidth = min(imageWidth, YepConfig.MetaData.thumbnailMaxSize)
        thumbnailHeight = imageHeight * (thumbnailWidth / imageWidth)
    } else {
        thumbnailHeight = min(imageHeight, YepConfig.MetaData.thumbnailMaxSize)
        thumbnailWidth = imageWidth * (thumbnailHeight / imageHeight)
    }

    let thumbnailSize = CGSize(width: thumbnailWidth, height: thumbnailHeight)

    if let thumbnail = image.navi_resizeToSize(thumbnailSize, withInterpolationQuality: CGInterpolationQuality.High) {

        if needBlurThumbnail {

            /*
            let blurredThumbnail = thumbnail.blurredImageWithRadius(5, iterations: 7, tintColor: UIColor.clearColor())

            let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)

            let string = data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

            println("image blurredThumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

            metaDataInfo = [
                YepConfig.MetaData.imageWidth: imageWidth,
                YepConfig.MetaData.imageHeight: imageHeight,
                YepConfig.MetaData.blurredThumbnailString: string,
            ]
            */
            metaDataInfo = [
                YepConfig.MetaData.imageWidth: imageWidth,
                YepConfig.MetaData.imageHeight: imageHeight,
            ]

        } else {

            let data = UIImageJPEGRepresentation(thumbnail, 0.7)

            let string = data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

            println("image thumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

            metaDataInfo = [
                YepConfig.MetaData.imageWidth: imageWidth,
                YepConfig.MetaData.imageHeight: imageHeight,
                YepConfig.MetaData.thumbnailString: string,
            ]
        }

    } else {
        metaDataInfo = [
            YepConfig.MetaData.imageWidth: imageWidth,
            YepConfig.MetaData.imageHeight: imageHeight
        ]
    }

    var metaDataString: String? = nil
    if let metaData = try? NSJSONSerialization.dataWithJSONObject(metaDataInfo, options: []) {
        metaDataString = NSString(data: metaData, encoding: NSUTF8StringEncoding) as? String
    }

    return metaDataString
}


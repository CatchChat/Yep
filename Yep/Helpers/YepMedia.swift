//
//  YepMedia.swift
//  Yep
//
//  Created by nixzhu on 15/10/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

func metaDataStringOfImage(image: UIImage, withThumbnailSize thumbnailSize: CGSize, needBlur: Bool) -> String? {

    let metaDataInfo: [String: AnyObject]

    let imageWidth = image.size.width
    let imageHeight = image.size.height

    if let thumbnail = image.resizeToSize(thumbnailSize, withInterpolationQuality: CGInterpolationQuality.Low) {

        if needBlur {

            let blurredThumbnail = thumbnail.blurredImageWithRadius(5, iterations: 7, tintColor: UIColor.clearColor())

            let data = UIImageJPEGRepresentation(blurredThumbnail, 0.7)

            let string = data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

            println("image blurredThumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

            metaDataInfo = [
                YepConfig.MetaData.imageWidth: imageWidth,
                YepConfig.MetaData.imageHeight: imageHeight,
                YepConfig.MetaData.blurredThumbnailString: string,
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


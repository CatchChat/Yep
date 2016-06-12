//
//  YepMedia.swift
//  Yep
//
//  Created by nixzhu on 15/10/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Navi

public func metaDataStringOfImage(image: UIImage, needBlurThumbnail: Bool) -> String? {

    let metaDataInfo: [String: AnyObject]

    let imageWidth = image.size.width
    let imageHeight = image.size.height

    let thumbnailWidth: CGFloat
    let thumbnailHeight: CGFloat

    if imageWidth > imageHeight {
        thumbnailWidth = min(imageWidth, Config.MetaData.thumbnailMaxSize)
        thumbnailHeight = imageHeight * (thumbnailWidth / imageWidth)
    } else {
        thumbnailHeight = min(imageHeight, Config.MetaData.thumbnailMaxSize)
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
                Config.MetaData.imageWidth: imageWidth,
                Config.MetaData.imageHeight: imageHeight,
            ]

        } else {

            let data = UIImageJPEGRepresentation(thumbnail, 0.7)

            let string = data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))

            println("image thumbnail string length: \(string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))\n")

            metaDataInfo = [
                Config.MetaData.imageWidth: imageWidth,
                Config.MetaData.imageHeight: imageHeight,
                Config.MetaData.thumbnailString: string,
            ]
        }

    } else {
        metaDataInfo = [
            Config.MetaData.imageWidth: imageWidth,
            Config.MetaData.imageHeight: imageHeight
        ]
    }

    var metaDataString: String? = nil
    if let metaData = try? NSJSONSerialization.dataWithJSONObject(metaDataInfo, options: []) {
        metaDataString = NSString(data: metaData, encoding: NSUTF8StringEncoding) as? String
    }

    return metaDataString
}

// 我们来一个 [0, 无穷] 到 [0, 1] 的映射
// 函数 y = 1 - 1 / e^(x/100) 挺合适
func nonlinearLimit(x: Int, toMax max: Int) -> Int {
    let n = 1 - 1 / exp(Double(x) / 100)
    return Int(Double(max) * n)
}
/*
// mini test
for var i = 0; i < 1000; i+=10 {
    let finalNumber = f(i, max:  maxNumber)
    println("i: \(i), finalNumber: \(finalNumber)")
}
*/

public func limitedAudioSamplesCount(x: Int) -> Int {
    return nonlinearLimit(x, toMax: 50)
}

public func averageSamplingFrom(values:[CGFloat], withCount count: Int) -> [CGFloat] {

    let step = Double(values.count) / Double(count)

    var outoutValues = [CGFloat]()

    var x: Double = 0

    for _ in 0..<count {

        let index = Int(x)

        if let value = values[safe: index] {
            let fixedValue = CGFloat(Int(value * 100)) / 100 // 最多两位小数
            outoutValues.append(fixedValue)

        } else {
            break
        }

        x += step
    }

    return outoutValues
}


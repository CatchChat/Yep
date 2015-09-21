//
//  YepAsset.swift
//  Yep
//
//  Created by NIX on 15/4/22.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import AVFoundation

func thumbnailImageOfVideoInVideoURL(videoURL: NSURL) -> UIImage? {
    let asset = AVURLAsset(URL: videoURL, options: [:])
    let imageGenerator = AVAssetImageGenerator(asset: asset)

    imageGenerator.appliesPreferredTrackTransform = true

    var actualTime: CMTime = CMTimeMake(0, 0)

    guard let cgImage = try? imageGenerator.copyCGImageAtTime(CMTimeMakeWithSeconds(0.0, 600), actualTime: &actualTime) else {
        return nil
    }

    let thumbnail = UIImage(CGImage: cgImage)

    return thumbnail
}
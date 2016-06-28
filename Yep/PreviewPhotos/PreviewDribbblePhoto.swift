//
//  PreviewDribbblePhoto.swift
//  Yep
//
//  Created by NIX on 16/6/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import YepPreview
import Kingfisher

class PreviewDribbblePhoto: NSObject, Photo {

    var image: UIImage? {
        didSet {
            self.updatedImage?(image: image)
        }
    }

    var updatedImage: ((image: UIImage?) -> Void)?

    init(imageURL: NSURL) {
        super.init()

        let imageView = UIImageView()

        let optionsInfos: KingfisherOptionsInfo = [
            .PreloadAllGIFData,
            .BackgroundDecode,
        ]

        imageView.kf_setImageWithURL(imageURL, optionsInfo: optionsInfos) { (image, error, cacheType, imageURL) in

            SafeDispatch.async { [weak self] in
                if let image = image {
                    self?.image = image
                }
            }
        }
    }
}


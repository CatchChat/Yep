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
            self.updatedImage?(image)
        }
    }

    var updatedImage: ((_ image: UIImage?) -> Void)?

    init(imageURL: URL) {
        super.init()

        let imageView = UIImageView()

        let optionsInfos: KingfisherOptionsInfo = [
            .preloadAllGIFData,
            .backgroundDecode,
        ]

        imageView.kf_setImage(with: imageURL, options: optionsInfos) { (image, error, cacheType, imageURL) in

            SafeDispatch.async { [weak self] in
                if let image = image {
                    self?.image = image
                }
            }
        }
    }
}


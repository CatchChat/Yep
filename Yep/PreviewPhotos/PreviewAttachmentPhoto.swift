//
//  PreviewAttachmentPhoto.swift
//  Yep
//
//  Created by NIX on 16/6/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import YepPreview

class PreviewAttachmentPhoto: NSObject, Photo {

    var image: UIImage? {
        didSet {
            self.updatedImage?(image)
        }
    }

    var updatedImage: ((_ image: UIImage?) -> Void)?

    init(attachment: DiscoveredAttachment) {
        super.init()

        YepImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: nil) { [weak self] (url, image, cacheType) in
            if let image = image {
                self?.image = image
            }
        }
    }
}


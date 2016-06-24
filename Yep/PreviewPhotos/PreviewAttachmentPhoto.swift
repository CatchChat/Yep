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

    let attachment: DiscoveredAttachment

    var image: UIImage? {
        didSet {
            self.updatedImage?(image: image)
            println("PreviewAttachmentPhoto updatedImageType: \(image)")
        }
    }

    var updatedImage: ((image: UIImage?) -> Void)?

    init(attachment: DiscoveredAttachment) {
        self.attachment = attachment

        super.init()

        ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: nil) { [weak self] (url, image, cacheType) in
            self?.image = image
        }
    }
}


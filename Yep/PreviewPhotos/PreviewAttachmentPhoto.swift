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
            self.updatedImageType?(imageType: imageType)
            println("PreviewAttachmentPhoto updatedImageType: \(image)")
        }
    }

    var imageType: ImageType {

        if let image = image {
            return .image(image)
        } else {
            return .imageURL(NSURL(string: attachment.URLString)!)
        }
    }

    var updatedImageType: ((imageType: ImageType) -> Void)?

    init(attachment: DiscoveredAttachment) {
        self.attachment = attachment

        super.init()

        ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: nil) { [weak self] (url, image, cacheType) in
            self?.image = image
        }
    }
}


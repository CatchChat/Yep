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

    var attachment: DiscoveredAttachment {
        didSet {
            ImageCache.sharedInstance.imageOfAttachment(attachment, withMinSideLength: nil) { (url, image, cacheType) in
                self.image = image
                println("PreviewAttachmentPhoto: \(image)")
            }
        }
    }

    var image: UIImage?

    var imageType: ImageType {

        if let image = image {
            return .image(image)
        } else {
            return .imageURL(NSURL(string: attachment.URLString)!)
        }
    }

    init(attachment: DiscoveredAttachment) {
        self.attachment = attachment
    }
}


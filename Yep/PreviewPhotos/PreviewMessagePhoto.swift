//
//  PreviewMessagePhoto.swift
//  Yep
//
//  Created by NIX on 16/6/22.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import YepPreview

class PreviewMessagePhoto: NSObject, Photo {

    let attachmentURLString: String

    var image: UIImage? {
        didSet {
            self.updatedImageType?(imageType: imageType)
            println("PreviewMessagePhoto updatedImageType: \(image)")
        }
    }

    var imageType: ImageType {

        if let image = image {
            return .image(image)
        } else {
            return .imageURL(NSURL(string: attachmentURLString)!)
        }
    }

    var updatedImageType: ((imageType: ImageType) -> Void)?

    init(message: Message) {
        self.attachmentURLString = message.attachmentURLString

        super.init()

        let localAttachmentName = message.localAttachmentName
        let attachmentURLString = message.attachmentURLString

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] in
            if let
                imageFileURL = NSFileManager.yepMessageImageURLWithName(localAttachmentName),
                image = UIImage(contentsOfFile: imageFileURL.path!) {

                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    self?.image = image
                }

            } else {
                if let url = NSURL(string: attachmentURLString) {
                    ImageCache.sharedInstance.imageOfURL(url, withMinSideLength: 0, completion: { [weak self] (url, image, cacheType) in
                        self?.image = image
                    })
                }
            }
        }
    }
}


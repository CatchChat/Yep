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

    let message: Message

    var image: UIImage?

    var imageType: ImageType {

        if let image = image {
            return .image(image)
        } else {
            return .imageURL(NSURL(string: message.attachmentURLString)!)
        }
    }

    var updatedImageType: ((imageType: ImageType) -> Void)?

    init(message: Message) {
        self.message = message

        super.init()

        if let
            imageFileURL = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName),
            image = UIImage(contentsOfFile: imageFileURL.path!) {
            self.image = image
        }
    }
}


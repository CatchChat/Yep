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

    var image: UIImage? {
        didSet {
            self.updatedImage?(image)
        }
    }

    var updatedImage: ((_ image: UIImage?) -> Void)?

    init(message: Message) {
        super.init()

        let imageFileURL = message.imageFileURL
        let attachmentURLString = message.attachmentURLString

        DispatchQueue.global(qos: .background).async { [weak self] in
            if let
                imageFileURL = imageFileURL,
                let image = UIImage(contentsOfFile: imageFileURL.path)?.decodedImage() {

                _ = delay(0.4) { [weak self] in
                    self?.image = image
                }

            } else {
                if let url = URL(string: attachmentURLString) {
                    YepImageCache.sharedInstance.imageOfURL(url, withMinSideLength: nil, completion: { [weak self] (url, image, cacheType) in
                        if let image = image {
                            self?.image = image
                        }
                    })
                }
            }
        }
    }
}


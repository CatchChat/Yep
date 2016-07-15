//
//  PreviewNewFeedPhoto.swift
//  Yep
//
//  Created by NIX on 16/7/15.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit
import YepPreview

class PreviewNewFeedPhoto: NSObject, Photo {

    var image: UIImage? {
        didSet {
            self.updatedImage?(image: image)
        }
    }

    var updatedImage: ((image: UIImage?) -> Void)?

    init(image: UIImage) {
        super.init()

        self.image = image
    }
}


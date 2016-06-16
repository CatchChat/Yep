//
//  ScalingImageView.swift
//  Yep
//
//  Created by NIX on 16/6/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ScalingImageView: UIScrollView {

    enum ImageType {
        case image(UIImage)
        case imageData(NSData)
        case imageURL(NSURL)
        case imageFileURL(NSURL)
    }

    let imageType: ImageType

    //let imageView: UIImageView

    init(frame: CGRect, imageType: ImageType) {
        self.imageType = imageType
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


}


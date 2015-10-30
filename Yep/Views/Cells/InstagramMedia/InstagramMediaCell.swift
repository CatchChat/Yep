//
//  InstagramMediaCell.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

let MediaOptionsInfos: KingfisherOptionsInfo = [
    .Options([.BackgroundDecode])
]

class InstagramMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.contentMode = .ScaleAspectFill
    }

    func configureWithInstagramMedia(media: InstagramWork.Media) {

        imageView.kf_showIndicatorWhenLoading = true
        imageView.kf_setImageWithURL(NSURL(string: media.images.lowResolution)!, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
    }
}

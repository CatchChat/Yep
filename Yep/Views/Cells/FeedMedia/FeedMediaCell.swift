//
//  FeedMediaCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class FeedMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.minificationFilter = kCAFilterTrilinear
        contentView.backgroundColor = UIColor.clearColor()
    }

    func configureWithImage(image: UIImage) {

        imageView.image = image
        deleteImageView.hidden = false
    }

    func configureWithImageURL(imageURL: NSURL, bigger: Bool) {

        if bigger {
            imageView.kf_setImageWithURL(imageURL, placeholderImage: YepConfig.FeedMedia.biggerPlaceholderImage, optionsInfo: MediaOptionsInfos)
        } else {
            imageView.kf_setImageWithURL(imageURL, placeholderImage: YepConfig.FeedMedia.placeholderImage, optionsInfo: MediaOptionsInfos)
        }

        deleteImageView.hidden = true
    }
}

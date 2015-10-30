//
//  FeedMediaCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import SDWebImage

class FeedMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.layer.minificationFilter = kCAFilterLinear
        contentView.backgroundColor = UIColor.clearColor()
    }

    func configureWithImage(image: UIImage) {

        imageView.image = image
        deleteImageView.hidden = false
    }

    func configureWithImageURL(imageURL: NSURL, bigger: Bool) {

        if bigger {
            imageView.sd_setImageWithURL(imageURL, placeholderImage: YepConfig.FeedMedia.biggerPlaceholderImage)
        } else {
            imageView.sd_setImageWithURL(imageURL, placeholderImage: YepConfig.FeedMedia.placeholderImage)
        }

        deleteImageView.hidden = true
    }
}

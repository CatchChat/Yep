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

        contentView.backgroundColor = UIColor.clearColor()
    }

    func configureWithImage(image: UIImage) {

        imageView.image = image

        deleteImageView.hidden = false
    }

    func configureWithImageURL(imageURL: NSURL) {

        imageView.kf_setImageWithURL(imageURL)

        deleteImageView.hidden = true
    }
}

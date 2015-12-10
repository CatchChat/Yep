//
//  FeedMediaCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteImageView: UIImageView!
    
    @IBOutlet weak var borderImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.backgroundColor = YepConfig.FeedMedia.backgroundColor
        imageView.layer.minificationFilter = kCAFilterLinear

        contentView.backgroundColor = UIColor.clearColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView.image = nil
    }

    func configureWithImage(image: UIImage) {

        imageView.image = image
        deleteImageView.hidden = false
    }

    func configureWithAttachment(attachment: DiscoveredAttachment, bigger: Bool) {

        let size = bigger ? CGSize(width: 160, height: 160) : CGSize(width: 80, height: 80)

        imageView.yep_setImageOfAttachment(attachment, withSize: size)

        deleteImageView.hidden = true
    }
}

//
//  FeedMediaCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FeedMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteImageView: UIImageView!
    var delete: (() -> Void)?
    
//    typealias NewFeedImageTapMediaAction = (transitionView: UIView, image: UIImage?, attachments: [DiscoveredAttachment], index: Int) -> Void
//    
//    var tapMediaAction: NewFeedImageTapMediaAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.backgroundColor = YepConfig.FeedMedia.backgroundColor
        imageView.layer.borderWidth = 1.0 / UIScreen.mainScreen().scale
        imageView.layer.borderColor = UIColor.yepBorderColor().CGColor
        imageView.userInteractionEnabled = true
        contentView.backgroundColor = UIColor.clearColor()
        
        let tapGesture = UITapGestureRecognizer(target: self, action:  #selector(FeedMediaCell.deleteImage));
        deleteImageView.addGestureRecognizer(tapGesture);
        
    }
    
    
    @objc private func deleteImage() {
        delete?()
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

        if attachment.isTemporary {
            imageView.image = attachment.image

        } else {
            let size = bigger ? YepConfig.FeedBiggerImageCell.imageSize : YepConfig.FeedNormalImagesCell.imageSize

            imageView.yep_showActivityIndicatorWhenLoading = true
            imageView.yep_setImageOfAttachment(attachment, withSize: size)
        }

        deleteImageView.hidden = true
    }
}

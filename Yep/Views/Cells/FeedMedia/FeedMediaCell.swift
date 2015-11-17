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
    
    var attachmentURL: NSURL!

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

        attachmentURL = NSURL(string: attachment.URLString)!

        if bigger {
            ImageCache.sharedInstance.imageOfAttachment(attachment, withSize: imageView.frame.size, completion: { [weak self] (url, image) in
                
                if let strongSelf = self {
                    if strongSelf.attachmentURL != url {
                        return
                    }
                }

                self?.imageView.image = image
            })

        } else {
            ImageCache.sharedInstance.imageOfAttachment(attachment, withSize: imageView.frame.size, completion: { [weak self] (url, image) in
                if let strongSelf = self {
                    if strongSelf.attachmentURL != url {
                        return
                    }
                }
                self?.imageView.image = image
            })
        }

        deleteImageView.hidden = true
    }
}

//
//  InstagramMediaCell.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class InstagramMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureWithInstagramMedia(media: InstagramWork.Media) {
        imageView.kf_setImageWithURL(NSURL(string: media.images.lowResolution)!, placeholderImage: nil, optionsInfo: [.TargetCache: KingfisherOptions.CacheMemoryOnly], progressBlock: { receivedSize, totalSize in
            if receivedSize < totalSize {
                self.activityIndicator.startAnimating()
            }
        }, completionHandler: { image, error, cacheType, imageURL in
            self.activityIndicator.stopAnimating()
        })
    }
}

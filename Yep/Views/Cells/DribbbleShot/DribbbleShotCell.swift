//
//  DribbbleShotCell.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class DribbbleShotCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureWithDribbbleShot(shot: DribbbleWork.Shot) {
        imageView.kf_setImageWithURL(NSURL(string: shot.images.normal)!, placeholderImage: nil, optionsInfo: [.TargetCache: KingfisherOptions.CacheMemoryOnly], progressBlock: { receivedSize, totalSize in
            if receivedSize < totalSize {
                self.activityIndicator.startAnimating()
            }
        }, completionHandler: { image, error, cacheType, imageURL in
            self.activityIndicator.stopAnimating()
        })
    }

}

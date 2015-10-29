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
    
    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.contentMode = .ScaleAspectFill
    }

    func configureWithDribbbleShot(shot: DribbbleWork.Shot) {
        
        imageView.kf_showIndicatorWhenLoading = true
        imageView.kf_setImageWithURL(NSURL(string: shot.images.normal)!, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
    }
}

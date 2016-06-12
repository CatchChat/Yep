//
//  DribbbleShotCell.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Kingfisher

final class DribbbleShotCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.contentMode = .ScaleAspectFill
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    func configureWithDribbbleShot(shot: DribbbleWork.Shot) {
        
        imageView.kf_showIndicatorWhenLoading = true
        
        //Kingfisher cost too much memory on HIDPI Dribbble GIF
        
//        if let hidpi = shot.images.hidpi where shot.images.normal.contains("gif") {
//            imageView.kf_setImageWithURL(NSURL(string: hidpi)!, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
//        } else {
            imageView.kf_setImageWithURL(NSURL(string: shot.images.normal)!, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
//        }
        
    }
}

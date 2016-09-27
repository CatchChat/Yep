//
//  InstagramMediaCell.swift
//  Yep
//
//  Created by NIX on 15/5/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Kingfisher

final class InstagramMediaCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        imageView.contentMode = .scaleAspectFill
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    func configureWithInstagramMedia(_ media: InstagramWork.Media) {

        //imageView.kf_showIndicatorWhenLoading = true
        imageView.kf.setImage(with: URL(string: media.images.lowResolution)!, placeholder: nil, options: MediaOptionsInfos)
    }
}

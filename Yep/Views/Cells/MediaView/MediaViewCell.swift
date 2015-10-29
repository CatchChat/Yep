//
//  MediaViewCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/28.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class MediaViewCell: UICollectionViewCell {

    @IBOutlet weak var mediaView: MediaView!

    override func awakeFromNib() {
        super.awakeFromNib()

        mediaView.backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.clearColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        mediaView.imageView.image = nil
    }
}


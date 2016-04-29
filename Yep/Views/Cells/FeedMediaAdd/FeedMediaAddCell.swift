//
//  FeedMediaAddCell.swift
//  Yep
//
//  Created by nixzhu on 15/9/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class FeedMediaAddCell: UICollectionViewCell {

    @IBOutlet weak var mediaAddImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        mediaAddImage.tintColor = UIColor.yepTintColor()
        contentView.backgroundColor = UIColor.yepBackgroundColor()
    }
}

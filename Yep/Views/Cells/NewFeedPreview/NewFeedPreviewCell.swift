//
//  NewFeedPreviewCell.swift
//  Yep
//
//  Created by ChaiYixiao on 4/8/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

class NewFeedPreviewCell: UICollectionViewCell {

    @IBOutlet weak var image: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        image.contentMode = .ScaleAspectFit
        image.center = self.center
    }

}

//
//  PhotoCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/14.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos

class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!

    var imageAsset: PHAsset? {
        didSet {
            self.imageManager?.requestImageForAsset(imageAsset!, targetSize: CGSize(width: 320, height: 320), contentMode: .AspectFill, options: nil) { image, info in
                self.photoImageView.image = image
            }
        }
    }

    var imageManager: PHImageManager?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}

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
    @IBOutlet weak var photoPickedImageView: UIImageView!

    var imageManager: PHImageManager?

    var imageAsset: PHAsset? {
        willSet {
            guard let imageAsset = newValue else {
                return
            }

            self.imageManager?.requestImageForAsset(imageAsset, targetSize: CGSize(width: 80, height: 80), contentMode: .AspectFill, options: nil) { [weak self] image, info in
                self?.photoImageView.image = image
                self?.photoPickedImageView.hidden = !imageAsset.favorite
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}


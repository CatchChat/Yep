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

    static var imageRequestOptions: PHImageRequestOptions = {
        let options = PHImageRequestOptions()
        options.synchronous = true
        return options
        }()

    var imageAsset: PHAsset? {
        willSet {
            guard let imageAsset = newValue else {
                return
            }

            self.imageManager?.requestImageForAsset(imageAsset, targetSize: CGSize(width: 120, height: 120), contentMode: .AspectFill, options: PhotoCell.imageRequestOptions) { [weak self] image, info in
                self?.photoImageView.image = image
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}


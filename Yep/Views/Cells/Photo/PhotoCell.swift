//
//  PhotoCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/14.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Photos
import YepKit
import Ruler

final class PhotoCell: UICollectionViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoPickedImageView: UIImageView!

    var imageManager: PHImageManager?

    var imageAsset: PHAsset? {
        willSet {
            guard let imageAsset = newValue else {
                return
            }

            let options = PHImageRequestOptions.yep_sharedOptions

            let width: CGFloat = Ruler.iPhoneHorizontal(160, 188, 310).value
            let height = width
            let targetSize = CGSize(width: width, height: height)

            DispatchQueue.global(qos: .default).async { [weak self] in
                self?.imageManager?.requestImage(for: imageAsset, targetSize: targetSize, contentMode: .aspectFill, options: options) { [weak self] image, info in

                    SafeDispatch.async { [weak self] in
                        self?.photoImageView.image = image
                    }
                }
            }
        }
    }
}


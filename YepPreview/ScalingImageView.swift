//
//  ScalingImageView.swift
//  Yep
//
//  Created by NIX on 16/6/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ScalingImageView: UIScrollView {

    enum ImageType {

        case image(UIImage)
        case imageData(NSData)
        case imageURL(NSURL)
        case imageFileURL(NSURL)

        var image: UIImage? {
            switch self {
            case .image(let image): return image
            case .imageData(let data): return UIImage(data: data)
            case .imageURL: return nil
            case .imageFileURL: return nil
            }
        }
    }

    let imageType: ImageType

    lazy var imageView = UIImageView()

    init(frame: CGRect, imageType: ImageType) {
        self.imageType = imageType
        super.init(frame: frame)

        setupImageView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupImageView() {

        if let image = imageType.image {
            updateImage(image)
        }

        addSubview(imageView)
    }

    private func updateImage(image: UIImage) {

        imageView.transform = CGAffineTransformIdentity
        imageView.image = image
        imageView.frame = CGRect(origin: CGPointZero, size: image.size)

        contentSize = image.size
    }

}


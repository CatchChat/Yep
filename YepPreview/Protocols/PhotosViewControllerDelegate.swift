//
//  PhotosViewControllerDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

public struct Reference {

    let view: UIView
    let image: UIImage?

    var imageView: UIImageView {
        let imageView = UIImageView(frame: view.bounds)
        imageView.contentMode = .ScaleAspectFill
        imageView.image = image
        return imageView
    }

    public init(view: UIView, image: UIImage?) {
        self.view = view
        self.image = image
    }
}

public protocol PhotosViewControllerDelegate: class {

    func photosViewController(vc: PhotosViewController, referenceForPhoto photo: Photo) -> Reference?
    func photosViewController(vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int)
    func photosViewControllerWillDismiss(vc: PhotosViewController)
    func photosViewControllerDidDismiss(vc: PhotosViewController)
}


//
//  PhotosViewControllerDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

public struct Reference {

    let bounds: CGRect
    let image: UIImage?

    public init(bounds: CGRect, image: UIImage?) {
        self.bounds = bounds
        self.image = image
    }
}

public protocol PhotosViewControllerDelegate: class {

    func photosViewController(vc: PhotosViewController, referenceViewForPhoto photo: Photo) -> UIView?
    func photosViewController(vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int)
    func photosViewControllerWillDismiss(vc: PhotosViewController)
    func photosViewControllerDidDismiss(vc: PhotosViewController)
}


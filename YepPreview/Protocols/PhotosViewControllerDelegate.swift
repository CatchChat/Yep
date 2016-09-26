//
//  PhotosViewControllerDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

public protocol PhotosViewControllerDelegate: class {

    func photosViewController(_ vc: PhotosViewController, referenceForPhoto photo: Photo) -> Reference?
    func photosViewController(_ vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int)
    func photosViewControllerWillDismiss(_ vc: PhotosViewController)
    func photosViewControllerDidDismiss(_ vc: PhotosViewController)
}


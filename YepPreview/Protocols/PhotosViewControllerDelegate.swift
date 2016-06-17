//
//  PhotosViewControllerDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/17.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

protocol PhotosViewControllerDelegate: class {

    func photosViewController(vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int)
    func photosViewControllerWillDismiss(vc: PhotosViewController) -> Bool
    func photosViewControllerDidDismiss(vc: PhotosViewController)
}


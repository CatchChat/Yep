//
//  ConversationViewController+PhotosViewControllerDelegate.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepPreview

extension ConversationViewController: PhotosViewControllerDelegate {

    func photosViewController(vc: PhotosViewController, referenceViewForPhoto photo: Photo) -> UIView? {

        println("photosViewController:referenceViewForPhoto:\(photo)")

        if let previewAttachmentPhoto = photo as? PreviewAttachmentPhoto {
            if let index = previewAttachmentPhotos.indexOf(previewAttachmentPhoto) {
                return previewTransitionViews?[index]
            }

        } else if let previewMessagePhoto = photo as? PreviewMessagePhoto {
            if let index = previewMessagePhotos.indexOf(previewMessagePhoto) {
                return previewTransitionViews?[index]
            }
        }

        return nil
    }

    func photosViewController(vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int) {

        println("photosViewController:didNavigateToPhoto:\(photo):atIndex:\(index)")
    }

    func photosViewControllerWillDismiss(vc: PhotosViewController) {

        println("photosViewControllerWillDismiss")
    }

    func photosViewControllerDidDismiss(vc: PhotosViewController) {

        println("photosViewControllerDidDismiss")

        previewTransitionViews = nil
        previewAttachmentPhotos = []
        previewMessagePhotos = []
    }
}


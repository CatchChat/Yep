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

    func photosViewController(_ vc: PhotosViewController, referenceForPhoto photo: Photo) -> Reference? {

        println("photosViewController:referenceViewForPhoto:\(photo)")

        if let previewAttachmentPhoto = photo as? PreviewAttachmentPhoto {
            if let index = previewAttachmentPhotos.index(of: previewAttachmentPhoto) {
                return previewReferences?[index]
            }

        } else if let previewMessagePhoto = photo as? PreviewMessagePhoto {
            if let index = previewMessagePhotos.index(of: previewMessagePhoto) {
                return previewReferences?[index]
            }
        }

        return nil
    }

    func photosViewController(_ vc: PhotosViewController, didNavigateToPhoto photo: Photo, atIndex index: Int) {

        println("photosViewController:didNavigateToPhoto:\(photo):atIndex:\(index)")
    }

    func photosViewControllerWillDismiss(_ vc: PhotosViewController) {

        println("photosViewControllerWillDismiss")
    }

    func photosViewControllerDidDismiss(_ vc: PhotosViewController) {

        println("photosViewControllerDidDismiss")

        previewReferences = nil
        previewAttachmentPhotos = []
        previewMessagePhotos = []
    }
}


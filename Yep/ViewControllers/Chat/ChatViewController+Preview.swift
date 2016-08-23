//
//  ChatViewController+Preview.swift
//  Yep
//
//  Created by NIX on 16/7/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import YepPreview
import AsyncDisplayKit

extension ChatViewController {

    func tryPreviewMediaOfMessage(message: Message, fromNode node: Previewable) {

        guard let messageIndex = messages.indexOf(message) else {
            return
        }

        if message.mediaType == MessageMediaType.Image.rawValue {

            let predicate = NSPredicate(format: "mediaType = %d", MessageMediaType.Image.rawValue)
            let imageMessagesResult = messages.filter(predicate)
            let imageMessages = imageMessagesResult.map({ $0 })

            guard let index = imageMessagesResult.indexOf(message) else {
                return
            }

            let references: [Reference?] = imageMessages.map({
                if let index = messages.indexOf($0) {
                    if index == messageIndex {
                        return node.transitionReference
                    } else {
                        return nil
                    }
                }

                return nil
            })

            self.previewReferences = references

            let previewMessagePhotos = imageMessages.map({ PreviewMessagePhoto(message: $0) })
            if let
                imageFileURL = message.imageFileURL,
                image = UIImage(contentsOfFile: imageFileURL.path!) {
                previewMessagePhotos[index].image = image
            }
            self.previewMessagePhotos = previewMessagePhotos
            
            let photos: [Photo] = previewMessagePhotos.map({ $0 })
            let initialPhoto = photos[index]
            
            let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
            self.presentViewController(photosViewController, animated: true, completion: nil)
        }
    }
}

extension ChatViewController: PhotosViewControllerDelegate {

    func photosViewController(vc: PhotosViewController, referenceForPhoto photo: Photo) -> Reference? {

        println("photosViewController:referenceViewForPhoto:\(photo)")

        if let previewAttachmentPhoto = photo as? PreviewAttachmentPhoto {
            if let index = previewAttachmentPhotos.indexOf(previewAttachmentPhoto) {
                return previewReferences?[index]
            }

        } else if let previewMessagePhoto = photo as? PreviewMessagePhoto {
            if let index = previewMessagePhotos.indexOf(previewMessagePhoto) {
                return previewReferences?[index]
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

        previewReferences = nil
        previewAttachmentPhotos = []
        previewMessagePhotos = []
    }
}


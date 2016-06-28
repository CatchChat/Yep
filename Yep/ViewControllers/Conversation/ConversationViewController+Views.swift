//
//  ConversationViewController+Views.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import MapKit
import YepPreview

extension ConversationViewController {

    func makeFeedViewWithFeed(feed: ConversationFeed) {

        let feedView = FeedView.instanceFromNib()

        feedView.feed = feed

        feedView.syncPlayAudioAction = { [weak self] in
            self?.syncPlayFeedAudioAction?()
        }

        feedView.tapAvatarAction = { [weak self] in
            self?.performSegueWithIdentifier("showProfileFromFeedView", sender: nil)
        }

        feedView.foldAction = { [weak self] in
            if let strongSelf = self {
                UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.conversationCollectionView.contentInset.top = 64 + FeedView.foldHeight + strongSelf.conversationCollectionViewContentInsetYOffset
                }, completion: { _ in })
            }
        }

        feedView.unfoldAction = { [weak self] feedView in
            if let strongSelf = self {
                UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
                    self?.conversationCollectionView.contentInset.top = 64 + feedView.normalHeight + strongSelf.conversationCollectionViewContentInsetYOffset
                }, completion: { _ in })

                if !strongSelf.messageToolbar.state.isAtBottom {
                    strongSelf.messageToolbar.state = .Default
                }
            }
        }

        feedView.tapImagesAction = { [weak self] transitionViews, attachments, image, index in

            self?.previewTransitionViews = transitionViews

            let previewAttachmentPhotos = attachments.map({ PreviewAttachmentPhoto(attachment: $0) })
            previewAttachmentPhotos[index].image = image

            self?.previewAttachmentPhotos = previewAttachmentPhotos

            let photos: [Photo] = previewAttachmentPhotos.map({ $0 })
            let initialPhoto = photos[index]

            let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
            self?.presentViewController(photosViewController, animated: true, completion: nil)
        }

        feedView.tapGithubRepoAction = { [weak self] URL in
            self?.yep_openURL(URL)
        }

        feedView.tapDribbbleShotAction = { [weak self] URL in
            self?.yep_openURL(URL)
        }

        feedView.tapLocationAction = { locationName, locationCoordinate in

            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
            mapItem.name = locationName

            mapItem.openInMapsWithLaunchOptions(nil)
        }

        feedView.tapURLInfoAction = { [weak self] URL in
            println("tapURLInfoAction URL: \(URL)")
            self?.yep_openURL(URL)
        }

        feedView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(feedView)

        let views: [String: AnyObject] = [
            "feedView": feedView
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[feedView]|", options: [], metrics: nil, views: views)

        let top = NSLayoutConstraint(item: feedView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 64)
        let height = NSLayoutConstraint(item: feedView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: feedView.normalHeight)
        
        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints([top, height])
        
        feedView.heightConstraint = height
        
        self.feedView = feedView
    }
}


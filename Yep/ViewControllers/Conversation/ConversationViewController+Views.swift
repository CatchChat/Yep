//
//  ConversationViewController+Views.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import YepKit
import YepPreview
import RealmSwift
import Proposer

// MARK: - FeedView

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

// MARK: - MentionView

extension ConversationViewController {

    func makeMentionView() -> MentionView {

        let view = MentionView()

        self.view.insertSubview(view, belowSubview: self.messageToolbar)

        view.translatesAutoresizingMaskIntoConstraints = false

        let top = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .GreaterThanOrEqual, toItem: self.topLayoutGuide, attribute: .Bottom, multiplier: 1.0, constant: 0)

        let leading = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Leading, multiplier: 1.0, constant: 0)
        let trailing = NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Trailing, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Top, multiplier: 1.0, constant: MentionView.height)
        let height = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: MentionView.height)

        bottom.priority = UILayoutPriorityDefaultHigh

        NSLayoutConstraint.activateConstraints([top, leading, trailing, bottom, height])
        self.view.layoutIfNeeded()

        view.heightConstraint = height
        view.bottomConstraint = bottom

        view.pickUserAction = { [weak self, weak view] username in
            self?.messageToolbar.replaceMentionedUsername(username)
            view?.hide()
        }
        
        return view
    }
}

// MARK: - WaverView

extension ConversationViewController {

    func makeWaverView() -> YepWaverView {

        let frame = self.view.bounds
        let view = YepWaverView(frame: frame)

        view.waver.waverCallback = { waver in

            guard let audioRecorder = YepAudioService.sharedManager.audioRecorder else {
                return
            }

            if (audioRecorder.recording) {
                //println("Update waver")
                audioRecorder.updateMeters()
                let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0)/40)
                waver.level = CGFloat(normalizedValue)
            }
        }
        
        return view
    }
}

// MARK: - MoreMessageTypesView

extension ConversationViewController {

    func makeMoreMessageTypesView() -> MoreMessageTypesView {

        let view =  MoreMessageTypesView()

        view.alertCanNotAccessCameraRollAction = { [weak self] in
            self?.alertCanNotAccessCameraRoll()
        }

        view.sendImageAction = { [weak self] image in
            self?.sendImage(image)
        }

        view.takePhotoAction = { [weak self] in

            let openCamera: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.Camera) else {
                    self?.alertCanNotOpenCamera()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .Camera
                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Camera, agreed: openCamera, rejected: {
                self?.alertCanNotOpenCamera()
            })
        }

        view.choosePhotoAction = { [weak self] in

            let openCameraRoll: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) else {
                    self?.alertCanNotAccessCameraRoll()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .PhotoLibrary

                    strongSelf.presentViewController(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.Photos, agreed: openCameraRoll, rejected: {
                self?.alertCanNotAccessCameraRoll()
            })
        }

        view.pickLocationAction = { [weak self] in
            self?.performSegueWithIdentifier("presentPickLocation", sender: nil)
        }
        
        return view
    }
}

// MARK: - SubscribeView

extension ConversationViewController {

    func makeSubscribeView() -> SubscribeView {

        let view = SubscribeView()

        self.view.insertSubview(view, belowSubview: self.messageToolbar)

        view.translatesAutoresizingMaskIntoConstraints = false

        let leading = NSLayoutConstraint(item: view, attribute: .Leading, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Leading, multiplier: 1.0, constant: 0)
        let trailing = NSLayoutConstraint(item: view, attribute: .Trailing, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Trailing, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: view, attribute: .Bottom, relatedBy: .Equal, toItem: self.messageToolbar, attribute: .Top, multiplier: 1.0, constant: SubscribeView.height)
        let height = NSLayoutConstraint(item: view, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: SubscribeView.height)

        NSLayoutConstraint.activateConstraints([leading, trailing, bottom, height])
        self.view.layoutIfNeeded()

        view.bottomConstraint = bottom
        
        return view
    }

    func tryShowSubscribeView() {

        guard let group = conversation.withGroup where !group.includeMe else {
            return
        }

        let groupID = group.groupID

        meIsMemberOfGroup(groupID: groupID, failureHandler: nil, completion: { meIsMember in

            println("meIsMember: \(meIsMember)")

            SafeDispatch.async { [weak self] in
                if let strongSelf = self {
                    if !group.invalidated {
                        let _ = try? strongSelf.realm.write {
                            group.includeMe = meIsMember
                        }
                    }
                }
            }

            guard !meIsMember else {
                return
            }

            // 最多显示一次
            guard SubscriptionViewShown.canShow(groupID: groupID) else {
                return
            }

            delay(3) { [weak self] in

                guard !group.invalidated else {
                    return
                }

                guard !group.includeMe else {
                    return
                }

                self?.subscribeView.subscribeAction = { [weak self] in
                    joinGroup(groupID: groupID, failureHandler: nil, completion: {
                        println("subscribe OK")

                        SafeDispatch.async { [weak self] in
                            if let strongSelf = self {
                                if !group.invalidated {
                                    let _ = try? strongSelf.realm.write {
                                        group.includeMe = true
                                        group.conversation?.updatedUnixTime = NSDate().timeIntervalSince1970
                                        strongSelf.moreViewManager.updateForGroupAffair()
                                    }
                                }
                            }
                        }
                    })
                }

                self?.subscribeView.showWithChangeAction = { [weak self] in
                    if let strongSelf = self {

                        let bottom = strongSelf.view.bounds.height - strongSelf.messageToolbar.frame.origin.y + SubscribeView.height

                        let extraPart = strongSelf.conversationCollectionView.contentSize.height - (strongSelf.messageToolbar.frame.origin.y - SubscribeView.height)

                        let newContentOffsetY: CGFloat
                        if extraPart > 0 {
                            newContentOffsetY = strongSelf.conversationCollectionView.contentOffset.y + SubscribeView.height
                        } else {
                            newContentOffsetY = strongSelf.conversationCollectionView.contentOffset.y
                        }

                        //println("extraPart: \(extraPart), newContentOffsetY: \(newContentOffsetY)")

                        self?.tryUpdateConversationCollectionViewWith(newContentInsetBottom: bottom, newContentOffsetY: newContentOffsetY)

                        self?.isSubscribeViewShowing = true
                    }
                }

                self?.subscribeView.hideWithChangeAction = { [weak self] in
                    if let strongSelf = self {

                        let bottom = strongSelf.view.bounds.height - strongSelf.messageToolbar.frame.origin.y

                        let newContentOffsetY = strongSelf.conversationCollectionView.contentSize.height - strongSelf.messageToolbar.frame.origin.y

                        self?.tryUpdateConversationCollectionViewWith(newContentInsetBottom: bottom, newContentOffsetY: newContentOffsetY)

                        self?.isSubscribeViewShowing = false
                    }
                }

                self?.subscribeView.show()

                // 记下已显示过
                do {
                    guard self != nil else {
                        return
                    }
                    guard let realm = try? Realm() else {
                        return
                    }
                    let shown = SubscriptionViewShown(groupID: groupID)
                    let _ = try? realm.write {
                        realm.add(shown, update: true)
                    }
                }
            }
        })
    }
}


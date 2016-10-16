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

    func makeFeedView(for feed: ConversationFeed) -> FeedView {

        let feedView = FeedView.instanceFromNib()

        feedView.feed = feed

        feedView.syncPlayAudioAction = { [weak self] in
            self?.syncPlayFeedAudioAction?()
        }

        feedView.tapAvatarAction = { [weak self] in
            self?.performSegue(withIdentifier: "showProfileFromFeedView", sender: nil)
        }

        feedView.foldAction = { [weak self] in
            if let strongSelf = self {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                    self?.conversationCollectionView.contentInset.top = 64 + FeedView.foldHeight + strongSelf.conversationCollectionViewContentInsetYOffset
                }, completion: { _ in })
            }
        }

        feedView.unfoldAction = { [weak self] feedView in
            if let strongSelf = self {
                UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                    self?.conversationCollectionView.contentInset.top = 64 + feedView.normalHeight + strongSelf.conversationCollectionViewContentInsetYOffset
                }, completion: { _ in })

                if !strongSelf.messageToolbar.state.isAtBottom {
                    strongSelf.messageToolbar.state = .default
                }
            }
        }

        feedView.tapImagesAction = { [weak self] references, attachments, image, index in

            self?.previewReferences = references

            let previewAttachmentPhotos = attachments.map({ PreviewAttachmentPhoto(attachment: $0) })
            previewAttachmentPhotos[index].image = image

            self?.previewAttachmentPhotos = previewAttachmentPhotos

            let photos: [Photo] = previewAttachmentPhotos.map({ $0 })
            let initialPhoto = photos[index]

            let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
            self?.present(photosViewController, animated: true, completion: nil)
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

            mapItem.openInMaps(launchOptions: nil)
        }

        feedView.tapURLInfoAction = { [weak self] URL in
            println("tapURLInfoAction URL: \(URL)")
            self?.yep_openURL(URL)
        }

        feedView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(feedView)

        let views: [String: Any] = [
            "feedView": feedView
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[feedView]|", options: [], metrics: nil, views: views)

        let top = NSLayoutConstraint(item: feedView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 64)
        let height = NSLayoutConstraint(item: feedView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: feedView.normalHeight)
        
        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate([top, height])
        
        feedView.heightConstraint = height
        
        return feedView
    }

    func tryFoldFeedView() {

        guard let feedView = feedView else {
            return
        }

        if feedView.foldProgress != 1.0 {
            feedView.foldProgress = 1.0
        }
    }
}

// MARK: - MentionView

extension ConversationViewController {

    func makeMentionView() -> MentionView {

        let view = MentionView()

        self.view.insertSubview(view, belowSubview: self.messageToolbar)

        view.translatesAutoresizingMaskIntoConstraints = false

        let top = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: self.topLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0)

        let leading = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self.messageToolbar, attribute: .leading, multiplier: 1.0, constant: 0)
        let trailing = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self.messageToolbar, attribute: .trailing, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self.messageToolbar, attribute: .top, multiplier: 1.0, constant: MentionView.height)
        let height = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: MentionView.height)

        bottom.priority = UILayoutPriorityDefaultHigh

        NSLayoutConstraint.activate([top, leading, trailing, bottom, height])
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

        view.takePhotoAction = {

            let openCamera: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                    self?.alertCanNotOpenCamera()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .camera
                    strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.camera, agreed: openCamera, rejected: { [weak self] in
                self?.alertCanNotOpenCamera()
            })
        }

        view.choosePhotoAction = {

            let openCameraRoll: ProposerAction = { [weak self] in

                guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
                    self?.alertCanNotAccessCameraRoll()
                    return
                }

                if let strongSelf = self {
                    strongSelf.imagePicker.sourceType = .photoLibrary

                    strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
                }
            }

            proposeToAccess(.photos, agreed: openCameraRoll, rejected: { [weak self] in
                self?.alertCanNotAccessCameraRoll()
            })
        }

        view.pickLocationAction = { [weak self] in
            self?.performSegue(withIdentifier: "presentPickLocation", sender: nil)
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

        let leading = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self.messageToolbar, attribute: .leading, multiplier: 1.0, constant: 0)
        let trailing = NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self.messageToolbar, attribute: .trailing, multiplier: 1.0, constant: 0)
        let bottom = NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self.messageToolbar, attribute: .top, multiplier: 1.0, constant: SubscribeView.height)
        let height = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: SubscribeView.height)

        NSLayoutConstraint.activate([leading, trailing, bottom, height])
        self.view.layoutIfNeeded()

        view.bottomConstraint = bottom
        
        return view
    }

    func tryShowSubscribeView() {

        guard let group = conversation.withGroup, !group.includeMe else {
            return
        }

        let groupID = group.groupID

        meIsMemberOfGroup(groupID: groupID, failureHandler: nil, completion: { meIsMember in

            println("meIsMember: \(meIsMember)")

            SafeDispatch.async { [weak self] in
                if let strongSelf = self {
                    if !group.isInvalidated {
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

            _ = delay(3) { [weak self] in

                guard !group.isInvalidated else {
                    return
                }

                guard !group.includeMe else {
                    return
                }

                self?.subscribeView.subscribeAction = {
                    joinGroup(groupID: groupID, failureHandler: nil, completion: { [weak self] in
                        println("subscribe OK")

                        self?.updateGroupToIncludeMe()
                    })
                }

                self?.subscribeView.showWithChangeAction = { [weak self] in
                    guard let strongSelf = self else { return }

                    let bottom = strongSelf.view.bounds.height - strongSelf.messageToolbar.frame.origin.y + SubscribeView.height

                    let extraPart = strongSelf.conversationCollectionView.contentSize.height - (strongSelf.messageToolbar.frame.origin.y - SubscribeView.height)

                    let newContentOffsetY: CGFloat
                    if extraPart > 0 {
                        newContentOffsetY = strongSelf.conversationCollectionView.contentOffset.y + SubscribeView.height
                    } else {
                        newContentOffsetY = strongSelf.conversationCollectionView.contentOffset.y
                    }

                    //println("extraPart: \(extraPart), newContentOffsetY: \(newContentOffsetY)")

                    strongSelf.tryUpdateConversationCollectionViewWith(newContentInsetBottom: bottom, newContentOffsetY: newContentOffsetY)

                    strongSelf.isSubscribeViewShowing = true
                }

                self?.subscribeView.hideWithChangeAction = { [weak self] in
                    guard let strongSelf = self else { return }

                    let bottom = strongSelf.view.bounds.height - strongSelf.messageToolbar.frame.origin.y

                    let newContentOffsetY = strongSelf.conversationCollectionView.contentSize.height - strongSelf.messageToolbar.frame.origin.y

                    strongSelf.tryUpdateConversationCollectionViewWith(newContentInsetBottom: bottom, newContentOffsetY: newContentOffsetY)

                    strongSelf.isSubscribeViewShowing = false
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

// MARK: TitleView {

extension ConversationViewController {

    func makeTitleView() -> ConversationTitleView {

        let titleView = ConversationTitleView(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 150, height: 44)))

        if let name = nameOfConversation(conversation), name != "" {
            titleView.nameLabel.text = name
        } else {
            titleView.nameLabel.text = String.trans_titleFeedDiscussion
        }

        self.updateStateInfoOfTitleView(titleView)

        titleView.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(ConversationViewController.showFriendProfile(_:)))

        titleView.addGestureRecognizer(tap)
        
        return titleView
    }

    func updateStateInfoOfTitleView(_ titleView: ConversationTitleView) {

        SafeDispatch.async { [weak self] in
            guard let strongSelf = self else { return }
            guard !strongSelf.conversation.isInvalidated else { return }

            if let timeAgo = lastSignDateOfConversation(strongSelf.conversation)?.timeAgo {
                titleView.stateInfoLabel.text = String.trans_promptLastSeenAt(timeAgo.lowercased())

            } else if let friend = strongSelf.conversation.withFriend {
                titleView.stateInfoLabel.text = String.trans_promptLastSeenAt(friend.lastSignInUnixTime)

            } else {
                titleView.stateInfoLabel.text = String.trans_infoBeginChatJustNow
            }

            titleView.stateInfoLabel.textColor = UIColor.gray
        }
    }

    @objc fileprivate func showFriendProfile(_ sender: UITapGestureRecognizer) {
        if let user = conversation.withFriend {
            performSegue(withIdentifier: "showProfile", sender: user)
        }
    }
}

// MARK: - FriendRequestView

extension ConversationViewController {

   func makeFriendRequestView(for user: User, in state: FriendRequestView.State) {

        let friendRequestView = FriendRequestView(state: state)

        friendRequestView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(friendRequestView)

        let friendRequestViewLeading = NSLayoutConstraint(item: friendRequestView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let friendRequestViewTrailing = NSLayoutConstraint(item: friendRequestView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let friendRequestViewTop = NSLayoutConstraint(item: friendRequestView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 64 - FriendRequestView.height)
        let friendRequestViewHeight = NSLayoutConstraint(item: friendRequestView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: FriendRequestView.height)

        NSLayoutConstraint.activate([friendRequestViewLeading, friendRequestViewTrailing, friendRequestViewTop, friendRequestViewHeight])

        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: { [weak self] in
            self?.conversationCollectionView.contentInset.top += FriendRequestView.height

            friendRequestViewTop.constant += FriendRequestView.height
            self?.view.layoutIfNeeded()
        }, completion: nil)

        friendRequestView.user = user

        let userID = user.userID

        let hideFriendRequestView: () -> Void = {
            SafeDispatch.async {
                UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseInOut, animations: { [weak self] in
                    if let strongSelf = self {
                        strongSelf.conversationCollectionView.contentInset.top = 64 + strongSelf.conversationCollectionViewContentInsetYOffset

                        friendRequestViewTop.constant -= FriendRequestView.height
                        strongSelf.view.layoutIfNeeded()
                    }

                }, completion: { [weak self] _ in
                    friendRequestView.removeFromSuperview()

                    if let strongSelf = self {
                        strongSelf.isTryingShowFriendRequestView = false
                    }
                })
            }
        }

        friendRequestView.addAction = { [weak self] friendRequestView in
            println("try Send Friend Request")

            sendFriendRequestToUser(user, failureHandler: { [weak self] reason, errorMessage in
                YepAlert.alertSorry(message: NSLocalizedString("Send Friend Request failed!", comment: ""), inViewController: self)

            }, completion: { friendRequestState in
                println("friendRequestState: \(friendRequestState.rawValue)")

                SafeDispatch.async {
                    guard let realm = try? Realm() else {
                        return
                    }
                    if let user = userWithUserID(userID, inRealm: realm) {
                        let _ = try? realm.write {
                            user.friendState = UserFriendState.issuedRequest.rawValue
                        }
                    }
                }

                hideFriendRequestView()
            })
        }

        friendRequestView.acceptAction = { [weak self] friendRequestView in
            println("friendRequestView.acceptAction")

            if let friendRequestID = friendRequestView.state.friendRequestID {

                acceptFriendRequestWithID(friendRequestID, failureHandler: { [weak self] reason, errorMessage in
                    YepAlert.alertSorry(message: String.trans_promptAcceptFriendRequestFailed, inViewController: self)

                }, completion: { success in
                    println("acceptFriendRequestWithID: \(friendRequestID), \(success)")

                    SafeDispatch.async {
                        guard let realm = try? Realm() else {
                            return
                        }
                        if let user = userWithUserID(userID, inRealm: realm) {
                            let _ = try? realm.write {
                                user.friendState = UserFriendState.normal.rawValue
                            }
                        }
                    }

                    hideFriendRequestView()
                })

            } else {
                println("NOT friendRequestID for acceptFriendRequestWithID")
            }
        }

        friendRequestView.rejectAction = { [weak self] friendRequestView in
            println("friendRequestView.rejectAction")

            let confirmAction: () -> Void = {

                if let friendRequestID = friendRequestView.state.friendRequestID {

                    rejectFriendRequestWithID(friendRequestID, failureHandler: { [weak self] reason, errorMessage in
                        YepAlert.alertSorry(message: NSLocalizedString("Reject Friend Request failed!", comment: ""), inViewController: self)

                    }, completion: { success in
                        println("rejectFriendRequestWithID: \(friendRequestID), \(success)")

                        hideFriendRequestView()
                    })

                } else {
                    println("NOT friendRequestID for rejectFriendRequestWithID")
                }
            }

            YepAlert.confirmOrCancel(title: String.trans_titleNotice, message: String.trans_promptTryRejectFriendRequest, confirmTitle: NSLocalizedString("Reject", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction:confirmAction, cancelAction: {
            })
        }
    }

    func tryShowFriendRequestView() {

        if let user = conversation.withFriend {

            // 若是陌生人或还未收到回应才显示 FriendRequestView
            if user.friendState != UserFriendState.stranger.rawValue && user.friendState != UserFriendState.issuedRequest.rawValue {
                return
            }

            let userID = user.userID
            let userNickname = user.nickname

            stateOfFriendRequestWithUser(user, failureHandler: nil, completion: { isFriend, receivedFriendRequestState, receivedFriendRequestID, sentFriendRequestState in

                println("isFriend: \(isFriend)")
                println("receivedFriendRequestState: \(receivedFriendRequestState.rawValue)")
                println("receivedFriendRequestID: \(receivedFriendRequestID)")
                println("sentFriendRequestState: \(sentFriendRequestState.rawValue)")

                // 已是好友下面就不用处理了
                if isFriend {
                    return
                }

                SafeDispatch.async { [weak self] in

                    if receivedFriendRequestState == .pending {
                        self?.makeFriendRequestView(for: user, in: .consider(prompt: NSLocalizedString("try add you as friend.", comment: ""), friendRequestID: receivedFriendRequestID))

                    } else if receivedFriendRequestState == .blocked {
                        YepAlert.confirmOrCancel(title: String.trans_titleNotice, message: String(format: NSLocalizedString("You have blocked %@! Do you want to unblock him or her?", comment: ""), "\(userNickname)"), confirmTitle: NSLocalizedString("Unblock", comment: ""), cancelTitle: String.trans_titleNotNow, inViewController: self, withConfirmAction: {

                            unblockUserWithUserID(userID, failureHandler: nil, completion: { success in
                                println("unblockUserWithUserID \(success)")

                                self?.updateBlocked(false, forUserWithUserID: userID, needUpdateUI: false)
                            })

                        }, cancelAction: {
                        })

                    } else {
                        if sentFriendRequestState == .none {
                            if receivedFriendRequestState != .rejected && receivedFriendRequestState != .blocked {
                                self?.makeFriendRequestView(for: user, in: .add(prompt: NSLocalizedString("is not your friend.", comment: "")))
                            }

                        } else if sentFriendRequestState == .rejected {
                            self?.makeFriendRequestView(for: user, in: .add(prompt: NSLocalizedString("reject your last friend request.", comment: "")))

                        } else if sentFriendRequestState == .blocked {
                            YepAlert.alertSorry(message: String(format: NSLocalizedString("You have been blocked by %@!", comment: ""), "\(userNickname)"), inViewController: self)
                        }
                    }
                }
            })
        }
    }
}


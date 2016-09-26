//
//  ConversationViewController+CollectionView.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit
import YepKit
import YepNetworking
import YepPreview
import OpenGraph
import RealmSwift

extension ConversationViewController {

    fileprivate func tryShowConversation(for feed: DiscoveredFeed?) {

        if let feed = feed {
            performSegue(withIdentifier: "showConversationWithFeed", sender: Box<DiscoveredFeed>(feed))

        } else {
            YepAlert.alertSorry(message: String.trans_promptFeedNotFound, inViewController: self)
        }
    }
}

extension ConversationViewController {

    func prepareConversationCollectionView() {

        conversationCollectionView.keyboardDismissMode = .onDrag
        conversationCollectionView.alwaysBounceVertical = true
        conversationCollectionView.bounces = true

        conversationCollectionView.registerNibOf(LoadMoreCollectionViewCell.self)
        conversationCollectionView.registerNibOf(ChatSectionDateCell.self)

        conversationCollectionView.registerClassOf(ChatTextIndicatorCell.self)

        conversationCollectionView.registerClassOf(ChatLeftTextCell.self)
        conversationCollectionView.registerClassOf(ChatLeftTextURLCell.self)
        conversationCollectionView.registerClassOf(ChatLeftImageCell.self)
        conversationCollectionView.registerClassOf(ChatLeftAudioCell.self)
        conversationCollectionView.registerClassOf(ChatLeftVideoCell.self)
        conversationCollectionView.registerClassOf(ChatLeftLocationCell.self)
        conversationCollectionView.registerNibOf(ChatLeftSocialWorkCell.self)

        conversationCollectionView.registerClassOf(ChatRightTextCell.self)
        conversationCollectionView.registerClassOf(ChatRightTextURLCell.self)
        conversationCollectionView.registerClassOf(ChatRightImageCell.self)
        conversationCollectionView.registerClassOf(ChatRightAudioCell.self)
        conversationCollectionView.registerClassOf(ChatRightVideoCell.self)
        conversationCollectionView.registerClassOf(ChatRightLocationCell.self)
    }
}

extension ConversationViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    @objc func didRecieveMenuWillHideNotification(_ notification: Notification) {

        println("Menu Will hide")

        selectedIndexPathForMenu = nil
    }

    @objc func didRecieveMenuWillShowNotification(_ notification: Notification) {

        println("Menu Will show")

        guard let menu = notification.object as? UIMenuController, let selectedIndexPathForMenu = selectedIndexPathForMenu, let cell = conversationCollectionView.cellForItem(at: selectedIndexPathForMenu as IndexPath) as? ChatBaseCell else {
            return
        }

        var bubbleFrame = CGRect.zero

        if let cell = cell as? ChatLeftTextCell {
            bubbleFrame = cell.convert(cell.textContentTextView.frame, to: view)

        } else if let cell = cell as? ChatRightTextCell {
            bubbleFrame = cell.convert(cell.textContainerView.frame, to: view)

        } else if let cell = cell as? ChatLeftTextURLCell {
            bubbleFrame = cell.convert(cell.textContentTextView.frame, to: view)

        } else if let cell = cell as? ChatRightTextURLCell {
            bubbleFrame = cell.convert(cell.textContainerView.frame, to: view)

        } else if let cell = cell as? ChatLeftImageCell {
            bubbleFrame = cell.convert(cell.messageImageView.frame, to: view)

        } else if let cell = cell as? ChatRightImageCell {
            bubbleFrame = cell.convert(cell.messageImageView.frame, to: view)

        } else if let cell = cell as? ChatLeftAudioCell {
            bubbleFrame = cell.convert(cell.audioContainerView.frame, to: view)

        } else if let cell = cell as? ChatRightAudioCell {
            bubbleFrame = cell.convert(cell.audioContainerView.frame, to: view)

        } else if let cell = cell as? ChatLeftVideoCell {
            bubbleFrame = cell.convert(cell.thumbnailImageView.frame, to: view)

        } else if let cell = cell as? ChatRightVideoCell {
            bubbleFrame = cell.convert(cell.thumbnailImageView.frame, to: view)

        } else if let cell = cell as? ChatLeftLocationCell {
            bubbleFrame = cell.convert(cell.mapImageView.frame, to: view)

        } else if let cell = cell as? ChatRightLocationCell {
            bubbleFrame = cell.convert(cell.mapImageView.frame, to: view)

        } else {
            return
        }

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)

        menu.setTargetRect(bubbleFrame, in: view)
        menu.setMenuVisible(true, animated: true)

        NotificationCenter.default.addObserver(self, selector: #selector(ConversationViewController.didRecieveMenuWillShowNotification(_:)), name: NSNotification.Name.UIMenuControllerWillShowMenu, object: nil)
    }

    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {

        selectedIndexPathForMenu = indexPath

        if let _ = conversationCollectionView.cellForItem(at: indexPath) as? ChatBaseCell {

            // must configure it before show

            var canReport = false

            let title: String
            if let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] {
                let isMyMessage = message.fromFriend?.isMe ?? false
                if isMyMessage {
                    title = NSLocalizedString("Recall", comment: "")
                } else {
                    title = String.trans_titleHide
                    canReport = true
                }
            } else {
                title = String.trans_titleDelete
            }

            var menuItems = [
                UIMenuItem(title: title, action: #selector(ChatBaseCell.deleteMessage(_:))),
            ]

            if canReport {
                let reportItem = UIMenuItem(title: NSLocalizedString("Report", comment: ""), action: #selector(ChatBaseCell.reportMessage(_:)))
                menuItems.append(reportItem)
            }

            UIMenuController.shared.menuItems = menuItems

            return true

        } else {
            selectedIndexPathForMenu = nil
        }

        return false
    }

    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {

        if action == #selector(NSObject.copy) {
            if conversationCollectionView.cellForItem(at: indexPath) is Copyable {
                return true
            }
        }

        if action == #selector(ChatBaseCell.deleteMessage(_:)) {
            return true
        }

        if action == #selector(ChatBaseCell.reportMessage(_:)) {
            return true
        }

        return false
    }

    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {

        if action == #selector(NSObject.copy) {
            if let copyableCell = conversationCollectionView.cellForItem(at: indexPath) as? Copyable {
                UIPasteboard.general.string = copyableCell.text
            }
        }
    }

    fileprivate func deleteMessageAtIndexPath(_ message: Message, indexPath: IndexPath) {
        SafeDispatch.async { [weak self] in

            guard let strongSelf = self, let realm = message.realm else {
                return
            }

            defer {
                realm.refresh()
            }

            let isMyMessage = message.fromFriend?.isMe ?? false

            var sectionDateMessage: Message?

            if let currentMessageIndex = strongSelf.messages.index(of: message) {

                let previousMessageIndex = currentMessageIndex - 1

                if let previousMessage = strongSelf.messages[safe: previousMessageIndex] {

                    if previousMessage.mediaType == MessageMediaType.sectionDate.rawValue {
                        sectionDateMessage = previousMessage
                    }
                }
            }

            let currentIndexPath: IndexPath
            if let index = strongSelf.messages.index(of: message) {
                currentIndexPath = IndexPath(item: index - strongSelf.displayedMessagesRange.location, section: indexPath.section)
            } else {
                currentIndexPath = indexPath
            }

            if let sectionDateMessage = sectionDateMessage {

                var canDeleteTwoMessages = false // 考虑刚好的边界情况，例如消息为本束的最后一条，而 sectionDate 在上一束中
                if strongSelf.displayedMessagesRange.length >= 2 {
                    strongSelf.displayedMessagesRange.length -= 2
                    canDeleteTwoMessages = true

                } else {
                    if strongSelf.displayedMessagesRange.location >= 1 {
                        strongSelf.displayedMessagesRange.location -= 1
                    }
                    strongSelf.displayedMessagesRange.length -= 1
                }

                let _ = try? realm.write {
                    message.deleteAttachmentInRealm(realm)

                    realm.delete(sectionDateMessage)

                    if isMyMessage {

                        let messageID = message.messageID

                        realm.delete(message)

                        deleteMessageFromServer(messageID: messageID, failureHandler: nil, completion: {
                            println("deleteMessageFromServer: \(messageID)")
                        })

                    } else {
                        message.hidden = true
                    }
                }

                if canDeleteTwoMessages {
                    let previousIndexPath = IndexPath(item: currentIndexPath.item - 1, section: currentIndexPath.section)
                    strongSelf.conversationCollectionView.deleteItems(at: [previousIndexPath, currentIndexPath])
                } else {
                    strongSelf.conversationCollectionView.deleteItems(at: [currentIndexPath])
                }

            } else {
                strongSelf.displayedMessagesRange.length -= 1

                let _ = try? realm.write {
                    message.deleteAttachmentInRealm(realm)

                    if isMyMessage {

                        let messageID = message.messageID

                        realm.delete(message)

                        deleteMessageFromServer(messageID: messageID, failureHandler: nil, completion: {
                            println("deleteMessageFromServer: \(messageID)")
                        })

                    } else {
                        message.hidden = true
                    }
                }

                strongSelf.conversationCollectionView.deleteItems(at: [currentIndexPath])
            }

            // 必须更新，插入时需要
            strongSelf.lastTimeMessagesCount = strongSelf.messages.count
        }
    }

    enum Section: Int {
        case loadPrevious
        case message
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {

        case .loadPrevious:
            return 1

        case .message:
            return displayedMessagesRange.length
        }
    }

    fileprivate func tryShowMessageMediaFromMessage(_ message: Message) {

        if let messageIndex = messages.index(of: message) {

            let indexPath = IndexPath(item: messageIndex - displayedMessagesRange.location, section: Section.message.rawValue)

            if let cell = conversationCollectionView.cellForItem(at: indexPath) {

                var frame = CGRect.zero
                var image: UIImage?
                var transitionView: UIView?

                if let sender = message.fromFriend {
                    if sender.friendState != UserFriendState.me.rawValue {
                        switch message.mediaType {

                        case MessageMediaType.image.rawValue:
                            let cell = cell as! ChatLeftImageCell
                            image = cell.messageImageView.image
                            transitionView = cell.messageImageView
                            frame = cell.convert(cell.messageImageView.frame, to: view)

                        case MessageMediaType.video.rawValue:
                            let cell = cell as! ChatLeftVideoCell
                            image = cell.thumbnailImageView.image
                            transitionView = cell.thumbnailImageView
                            frame = cell.convert(cell.thumbnailImageView.frame, to: view)

                        default:
                            break
                        }

                    } else {
                        switch message.mediaType {

                        case MessageMediaType.image.rawValue:
                            let cell = cell as! ChatRightImageCell
                            image = cell.messageImageView.image
                            transitionView = cell.messageImageView
                            frame = cell.convert(cell.messageImageView.frame, to: view)

                        case MessageMediaType.video.rawValue:
                            let cell = cell as! ChatRightVideoCell
                            image = cell.thumbnailImageView.image
                            transitionView = cell.thumbnailImageView
                            frame = cell.convert(cell.thumbnailImageView.frame, to: view)

                        default:
                            break
                        }
                    }
                }

                guard image != nil else {
                    return
                }

                if message.mediaType == MessageMediaType.video.rawValue {

                    let vc = UIStoryboard.Scene.mediaPreview

                    vc.previewMedias = [PreviewMedia.messageType(message: message)]
                    vc.startIndex = 0

                    vc.previewImageViewInitalFrame = frame
                    vc.topPreviewImage = message.thumbnailImage
                    vc.bottomPreviewImage = image

                    vc.transitionView = transitionView

                    doInNextRunLoop { // 避免太快消失产生闪烁
                        transitionView?.alpha = 0
                    }

                    vc.afterDismissAction = { [weak self] in
                        transitionView?.alpha = 1
                        self?.view.window?.makeKeyAndVisible()
                    }

                    mediaPreviewWindow.rootViewController = vc
                    mediaPreviewWindow.windowLevel = UIWindowLevelAlert - 1
                    mediaPreviewWindow.makeKeyAndVisible()

                } else if message.mediaType == MessageMediaType.image.rawValue {

                    let predicate = NSPredicate(format: "mediaType = %d", MessageMediaType.image.rawValue)
                    let mediaMessagesResult = messages.filter(predicate)
                    let mediaMessages = mediaMessagesResult.map({ $0 })

                    guard let index = mediaMessagesResult.index(of: message) else {
                        return
                    }

                    let references: [Reference?] = mediaMessages.map({
                        if let index = messages.index(of: $0) {
                            if index == messageIndex {
                                let cellIndex = index - displayedMessagesRange.location
                                let cellIndexPath = IndexPath(item: cellIndex, section: Section.message.rawValue)
                                let cell = conversationCollectionView.cellForItem(at: cellIndexPath)
                                if let previewableCell = cell as? Previewable {
                                    return previewableCell.transitionReference
                                }

                            } else {
                                return nil
                            }
                        }
                        
                        return nil
                    })

                    self.previewReferences = references

                    let previewMessagePhotos: [PreviewMessagePhoto] = mediaMessages.map({ PreviewMessagePhoto(message: $0) })
                    if let
                        imageFileURL = message.imageFileURL,
                        let image = UIImage(contentsOfFile: imageFileURL.path) {
                        previewMessagePhotos[index].image = image
                    }
                    self.previewMessagePhotos = previewMessagePhotos

                    let photos: [Photo] = previewMessagePhotos.map({ $0 })
                    let initialPhoto = photos[index]

                    let photosViewController = PhotosViewController(photos: photos, initialPhoto: initialPhoto, delegate: self)
                    self.present(photosViewController, animated: true, completion: nil)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .loadPrevious:

            let cell: LoadMoreCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        case .message:

            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                println("🐌 Conversation: message NOT found!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌"

                return cell
            }

            if message.mediaType == MessageMediaType.sectionDate.rawValue {

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.configureWithMessage(message)

                return cell
            }

            let tapUsernameAction: (_ username: String) -> Void = { [weak self] username in
                self?.tryShowProfileWithUsername(username)
            }

            guard let sender = message.fromFriend else {

                if message.blockedByRecipient {
                    let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    cell.configureWithMessage(message, indicateType: .blockedByRecipient)

                    return cell
                }

                println("🐌🐌 Conversation: message has NOT fromFriend!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌🐌"

                return cell
            }

            func prepareCell(_ cell: ChatBaseCell) {

                if let _ = self.conversation.withGroup {
                    cell.inGroup = true
                } else {
                    cell.inGroup = false
                }

                cell.tapAvatarAction = { [weak self] user in
                    self?.performSegue(withIdentifier: "showProfile", sender: user)
                }

                cell.deleteMessageAction = { [weak self] in
                    self?.deleteMessageAtIndexPath(message, indexPath: indexPath)
                }

                cell.reportMessageAction = { [weak self] in
                    self?.report(.message(messageID: message.messageID))
                }
            }

            if sender.friendState != UserFriendState.me.rawValue { // from Friend

                switch message.mediaType {

                case MessageMediaType.image.rawValue:

                    let cell: ChatLeftImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.downloadState == MessageDownloadState.downloaded.rawValue {

                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder {
                                    self?.messageToolbar.state = .default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)

                        } else {
                            //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the image is not ready!", comment: ""), inViewController: self)
                        }
                    })

                    return cell

                case MessageMediaType.audio.rawValue:

                    let cell: ChatLeftAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)
                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                        if message.downloadState == MessageDownloadState.downloaded.rawValue {
                            self?.playAudio(of: message)

                        } else {
                            //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the audio is not ready!", comment: ""), inViewController: self)
                        }
                    })

                    return cell

                case MessageMediaType.video.rawValue:

                    let cell: ChatLeftVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.downloadState == MessageDownloadState.downloaded.rawValue {

                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder {
                                    self?.messageToolbar.state = .default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)

                        } else {
                            //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the video is not ready!", comment: ""), inViewController: self)
                        }

                    })

                    return cell

                case MessageMediaType.location.rawValue:

                    let cell: ChatLeftLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: {
                        if let coordinate = message.coordinate {
                            let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                            mapItem.name = message.textContent
                            /*
                             let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                             mapItem.openInMapsWithLaunchOptions(launchOptions)
                             */
                            mapItem.openInMaps(launchOptions: nil)
                        }
                    })

                    return cell

                case MessageMediaType.socialWork.rawValue:

                    let cell: ChatLeftSocialWorkCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    cell.configureWithMessage(message)
                    cell.createFeedAction = { [weak self] socialWork in
                        self?.performSegue(withIdentifier: "presentNewFeed", sender: socialWork)
                    }

                    return cell

                default:

                    if message.deletedByCreator {
                        let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        cell.configureWithMessage(message, indicateType: .recalledMessage)
                        return cell

                    } else {
                        if message.openGraphInfo != nil {
                            let cell: ChatLeftTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                            prepareCell(cell)

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversation(for: feed)
                            }

                            cell.tapOpenGraphURLAction = { [weak self] URL in
                                if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversation(for: feed) }) {
                                    self?.yep_openURL(URL)
                                }
                            }
                            
                            return cell

                        } else {
                            let cell: ChatLeftTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                            prepareCell(cell)

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversation(for: feed)
                            }

                            return cell
                        }
                    }
                }

            } else { // from Me

                switch message.mediaType {

                case MessageMediaType.image.rawValue:

                    let cell: ChatRightImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)

                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.sendState == MessageSendState.failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend image?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason, errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: String.trans_promptResendImageFailed
                                    )

                                }, completion: { success in
                                    println("resendImage: \(success)")
                                })

                            }, cancelAction: {
                            })

                        } else {
                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder {
                                    self?.messageToolbar.state = .default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)
                        }
                    })

                    return cell

                case MessageMediaType.audio.rawValue:

                    let cell: ChatRightAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)

                    let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                    cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                        if message.sendState == MessageSendState.failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend audio?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason, errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: String.trans_promptResendAudioFailed
                                    )

                                }, completion: { success in
                                    println("resendAudio: \(success)")
                                })

                                }, cancelAction: {
                            })

                            return
                        }
                        
                        self?.playAudio(of: message)
                    })

                    return cell

                case MessageMediaType.video.rawValue:

                    let cell: ChatRightVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.sendState == MessageSendState.failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason, errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: String.trans_promptResendVideoFailed
                                    )

                                }, completion: { success in
                                    println("resendVideo: \(success)")
                                })

                            }, cancelAction: {
                            })

                        } else {
                            if let messageTextView = self?.messageToolbar.messageTextView {
                                if messageTextView.isFirstResponder {
                                    self?.messageToolbar.state = .default
                                    return
                                }
                            }

                            self?.tryShowMessageMediaFromMessage(message)
                        }
                    })

                    return cell

                case MessageMediaType.location.rawValue:

                    let cell: ChatRightLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                    prepareCell(cell)
                    cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                        if message.sendState == MessageSendState.failed.rawValue {

                            YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend location?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                    defaultFailureHandler(reason, errorMessage)

                                    self?.promptSendMessageFailed(
                                        reason: reason,
                                        errorMessage: errorMessage,
                                        reserveErrorMessage: String.trans_promptResendLocationFailed
                                    )

                                }, completion: { success in
                                    println("resendLocation: \(success)")
                                })

                                }, cancelAction: {
                            })

                        } else {
                            if let coordinate = message.coordinate {
                                let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                mapItem.name = message.textContent
                                /*
                                 let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                 mapItem.openInMapsWithLaunchOptions(launchOptions)
                                 */
                                mapItem.openInMaps(launchOptions: nil)
                            }
                        }
                    })

                    return cell

                default:

                    let mediaTapAction: () -> Void = { [weak self] in

                        guard message.sendState == MessageSendState.failed.rawValue else {
                            return
                        }

                        YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                            resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                defaultFailureHandler(reason, errorMessage)

                                self?.promptSendMessageFailed(
                                    reason: reason,
                                    errorMessage: errorMessage,
                                    reserveErrorMessage: String.trans_promptResendTextFailed
                                )

                            }, completion: { success in
                                println("resendText: \(success)")
                            })
                            
                        }, cancelAction: {
                        })
                    }

                    if message.openGraphInfo != nil {
                        let cell: ChatRightTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                        prepareCell(cell)

                        let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                        cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                        cell.tapUsernameAction = tapUsernameAction

                        cell.tapFeedAction = { [weak self] feed in
                            self?.tryShowConversation(for: feed)
                        }

                        cell.tapOpenGraphURLAction = { [weak self] URL in
                            if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversation(for: feed) }) {
                                self?.yep_openURL(URL)
                            }
                        }

                        return cell
                        
                    } else {
                        let cell: ChatRightTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)

                        prepareCell(cell)

                        let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                        cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                        cell.tapUsernameAction = tapUsernameAction

                        cell.tapFeedAction = { [weak self] feed in
                            self?.tryShowConversation(for: feed)
                        }

                        return cell
                    }
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .loadPrevious:
            break

        case .message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return
            }

            if message.mediaType == MessageMediaType.text.rawValue {
                tryDetectOpenGraphForMessage(message)
            }
        }
    }

    /*
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            let cell: LoadMoreCollectionViewCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
            return cell

        case .Message:

            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                println("🐌 Conversation: message NOT found!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌"

                return cell
            }

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                return cell
            }

            guard let sender = message.fromFriend else {

                if message.blockedByRecipient {
                    let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
                }

                println("🐌🐌 Conversation: message has NOT fromFriend!")

                let cell: ChatSectionDateCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                cell.sectionDateLabel.text = "🐌🐌"

                return cell
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    let cell: ChatLeftImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Audio.rawValue:

                    let cell: ChatLeftAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Video.rawValue:

                    let cell: ChatLeftVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Location.rawValue:

                    let cell: ChatLeftLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.SocialWork.rawValue:

                    let cell: ChatLeftSocialWorkCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell
                    
//                case MessageMediaType.ShareFeed.rawValue:
//                    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(chatLeftShareFeedCellIdentifier, forIndexPath: indexPath) as! LeftShareFeedCell
//                    return cell
                    
                default:

                    if message.deletedByCreator {
                        let cell: ChatTextIndicatorCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        return cell

                    } else {
                        if message.openGraphInfo != nil {
                            let cell: ChatLeftTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                            return cell

                        } else {
                            let cell: ChatLeftTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                            return cell
                        }
                    }
                }

            } else { // from Me

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    let cell: ChatRightImageCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Audio.rawValue:

                    let cell: ChatRightAudioCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Video.rawValue:

                    let cell: ChatRightVideoCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                case MessageMediaType.Location.rawValue:

                    let cell: ChatRightLocationCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                    return cell

                default:

                    if message.openGraphInfo != nil {
                        let cell: ChatRightTextURLCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        return cell

                    } else {
                        let cell: ChatRightTextCell = collectionView.dequeueReusableCell(forIndexPath: indexPath)
                        return cell
                    }
                }
            }
        }
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            break

        case .Message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return
            }

            if message.mediaType == MessageMediaType.SectionDate.rawValue {

                if let cell = cell as? ChatSectionDateCell {
                    cell.configureWithMessage(message)
                }

                return
            }

            guard let sender = message.fromFriend else {

                if message.blockedByRecipient {
                    if let cell = cell as? ChatTextIndicatorCell {
                        cell.configureWithMessage(message, indicateType: .BlockedByRecipient)
                    }
                }

                return
            }

            if let cell = cell as? ChatBaseCell {

                if let _ = self.conversation.withGroup {
                    cell.inGroup = true
                } else {
                    cell.inGroup = false
                }

                cell.tapAvatarAction = { [weak self] user in
                    self?.performSegueWithIdentifier("showProfile", sender: user)
                }

                cell.deleteMessageAction = { [weak self] in
                    self?.deleteMessageAtIndexPath(message, indexPath: indexPath)
                }

                cell.reportMessageAction = { [weak self] in
                    self?.report(.Message(messageID: message.messageID))
                }
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    if let cell = cell as? ChatLeftImageCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)

                            } else {
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the image is not ready!", comment: ""), inViewController: self)
                            }
                        })
                    }

                case MessageMediaType.Audio.rawValue:

                    if let cell = cell as? ChatLeftAudioCell {

                        let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                        cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {
                                self?.playMessageAudioWithMessage(message)

                            } else {
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the audio is not ready!", comment: ""), inViewController: self)
                            }
                        })
                    }

                case MessageMediaType.Video.rawValue:

                    if let cell = cell as? ChatLeftVideoCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.downloadState == MessageDownloadState.Downloaded.rawValue {

                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)

                            } else {
                                //YepAlert.alertSorry(message: NSLocalizedString("Please wait while the video is not ready!", comment: ""), inViewController: self)
                            }
                        })
                    }

                case MessageMediaType.Location.rawValue:

                    if let cell = cell as? ChatLeftLocationCell {

                        cell.configureWithMessage(message, mediaTapAction: {
                            if let coordinate = message.coordinate {
                                let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                mapItem.name = message.textContent
                                /*
                                let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                mapItem.openInMapsWithLaunchOptions(launchOptions)
                                */
                                mapItem.openInMapsWithLaunchOptions(nil)
                            }
                        })
                    }

                case MessageMediaType.SocialWork.rawValue:

                    if let cell = cell as? ChatLeftSocialWorkCell {
                        cell.configureWithMessage(message)

                        cell.createFeedAction = { [weak self] socialWork in

                            self?.performSegueWithIdentifier("presentNewFeed", sender: socialWork)
                        }
                    }

                default:

                    if message.deletedByCreator {
                        if let cell = cell as? ChatTextIndicatorCell {
                            cell.configureWithMessage(message, indicateType: .RecalledMessage)
                        }

                    } else {
                        if message.openGraphInfo != nil {

                            if let cell = cell as? ChatLeftTextURLCell {

                                let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                                cell.configureWithMessage(message, layoutCache: layoutCache)

                                cell.tapUsernameAction = tapUsernameAction

                                cell.tapFeedAction = { [weak self] feed in
                                    self?.tryShowConversationWithFeed(feed)
                                }

                                cell.tapOpenGraphURLAction = { [weak self] URL in
                                    if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversationWithFeed(feed) }) {
                                        self?.yep_openURL(URL)
                                    }
                                }
                            }

                        } else {

                            if let cell = cell as? ChatLeftTextCell {

                                let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                                cell.configureWithMessage(message, layoutCache: layoutCache)

                                cell.tapUsernameAction = tapUsernameAction

                                cell.tapFeedAction = { [weak self] feed in
                                    self?.tryShowConversationWithFeed(feed)
                                }
                            }
                        }

                        tryDetectOpenGraphForMessage(message)
                    }
                }

            } else { // from Me

                switch message.mediaType {

                case MessageMediaType.Image.rawValue:

                    if let cell = cell as? ChatRightImageCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend image?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: String.trans_promptResendImageFailed
                                        )

                                    }, completion: { success in
                                        println("resendImage: \(success)")
                                    })

                                }, cancelAction: {
                                })

                            } else {
                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)
                            }
                        })
                    }

                case MessageMediaType.Audio.rawValue:

                    if let cell = cell as? ChatRightAudioCell {

                        let audioPlayedDuration = audioPlayedDurationOfMessage(message)

                        cell.configureWithMessage(message, audioPlayedDuration: audioPlayedDuration, audioBubbleTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend audio?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: String.trans_promptResendAudioFailed
                                        )

                                    }, completion: { success in
                                        println("resendAudio: \(success)")
                                    })

                                }, cancelAction: {
                                })

                                return
                            }

                            self?.playMessageAudioWithMessage(message)
                        })
                    }

                case MessageMediaType.Video.rawValue:

                    if let cell = cell as? ChatRightVideoCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend video?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: String.trans_promptResendVideoFailed
                                        )

                                    }, completion: { success in
                                        println("resendVideo: \(success)")
                                    })

                                }, cancelAction: {
                                })

                            } else {
                                if let messageTextView = self?.messageToolbar.messageTextView {
                                    if messageTextView.isFirstResponder() {
                                        self?.messageToolbar.state = .Default
                                        return
                                    }
                                }

                                self?.tryShowMessageMediaFromMessage(message)
                            }
                        })
                    }

                case MessageMediaType.Location.rawValue:

                    if let cell = cell as? ChatRightLocationCell {

                        cell.configureWithMessage(message, mediaTapAction: { [weak self] in

                            if message.sendState == MessageSendState.Failed.rawValue {

                                YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend location?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                                    resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                        defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                        self?.promptSendMessageFailed(
                                            reason: reason,
                                            errorMessage: errorMessage,
                                            reserveErrorMessage: String.trans_promptResendLocationFailed
                                        )

                                    }, completion: { success in
                                        println("resendLocation: \(success)")
                                    })

                                }, cancelAction: {
                                })

                            } else {
                                if let coordinate = message.coordinate {
                                    let locationCoordinate = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
                                    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: locationCoordinate, addressDictionary: nil))
                                    mapItem.name = message.textContent
                                    /*
                                    let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                                    mapItem.openInMapsWithLaunchOptions(launchOptions)
                                    */
                                    mapItem.openInMapsWithLaunchOptions(nil)
                                }
                            }
                        })
                    }

                default:

                    let mediaTapAction: () -> Void = { [weak self] in

                        guard message.sendState == MessageSendState.Failed.rawValue else {
                            return
                        }

                        YepAlert.confirmOrCancel(title: NSLocalizedString("title.action", comment: ""), message: NSLocalizedString("Resend text?", comment: ""), confirmTitle: NSLocalizedString("Resend", comment: ""), cancelTitle: String.trans_cancel, inViewController: self, withConfirmAction: {

                            resendMessage(message, failureHandler: { [weak self] reason, errorMessage in
                                defaultFailureHandler(reason: reason, errorMessage: errorMessage)

                                self?.promptSendMessageFailed(
                                    reason: reason,
                                    errorMessage: errorMessage,
                                    reserveErrorMessage: String.trans_promptResendTextFailed
                                )

                            }, completion: { success in
                                println("resendText: \(success)")
                            })

                        }, cancelAction: {
                        })
                    }

                    if message.openGraphInfo != nil {

                        if let cell = cell as? ChatRightTextURLCell {

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversationWithFeed(feed)
                            }

                            cell.tapOpenGraphURLAction = { [weak self] URL in
                                if !URL.yep_matchSharedFeed({ [weak self] feed in self?.tryShowConversationWithFeed(feed) }) {
                                    self?.yep_openURL(URL)
                                }
                            }
                        }

                    } else {

                        if let cell = cell as? ChatRightTextCell {

                            let layoutCache = chatTextCellLayoutCacheOfMessage(message)

                            cell.configureWithMessage(message, layoutCache: layoutCache, mediaTapAction: mediaTapAction)

                            cell.tapUsernameAction = tapUsernameAction

                            cell.tapFeedAction = { [weak self] feed in
                                self?.tryShowConversationWithFeed(feed)
                            }
                        }
                    }

                    tryDetectOpenGraphForMessage(message)
                }
            }
        }
    }
     */

    fileprivate func tryDetectOpenGraphForMessage(_ message: Message) {

        guard !message.openGraphDetected else {
            return
        }

        func markMessageOpenGraphDetected() {
            guard !message.isInvalidated else {
                return
            }

            let _ = try? realm.write {
                message.openGraphDetected = true
            }
        }

        let text = message.textContent
        guard let fisrtURL = text.yep_embeddedURLs.first else {
            markMessageOpenGraphDetected()
            return
        }

        let oldMessagesUpdatedVersion = self.messagesUpdatedVersion

        openGraphWithURL(fisrtURL, failureHandler: { reason, errorMessage in
            defaultFailureHandler(reason, errorMessage)

            SafeDispatch.async {
                markMessageOpenGraphDetected()
            }

        }, completion: { _openGraph in
            println("message_openGraph: \(_openGraph)")

            guard _openGraph.isValid else {
                return
            }

            SafeDispatch.async { [weak self] in

                guard let strongSelf = self else {
                    return
                }

                let openGraphInfo = OpenGraphInfo(URLString: _openGraph.URL.absoluteString, siteName: _openGraph.siteName ?? "", title: _openGraph.title ?? "", infoDescription: _openGraph.description ?? "", thumbnailImageURLString: _openGraph.previewImageURLString ?? "")

                let _ = try? strongSelf.realm.write {
                    strongSelf.realm.add(openGraphInfo, update: true)
                    message.openGraphInfo = openGraphInfo
                }

                markMessageOpenGraphDetected()

                // update UI
                strongSelf.clearHeightOfMessageWithKey(message.messageID)

                guard strongSelf.messagesUpdatedVersion == oldMessagesUpdatedVersion else {
                    doInNextRunLoop { [weak self] in
                        self?.reloadConversationCollectionView()
                    }
                    return
                }

                if let index = strongSelf.messages.index(of: message) {
                    let realIndex = index - strongSelf.displayedMessagesRange.location
                    let indexPath = IndexPath(item: realIndex, section: Section.message.rawValue)

                    doInNextRunLoop { [weak self] in
                        if self?.conversationCollectionView.cellForItem(at: indexPath) != nil {
                            self?.conversationCollectionView.reloadItems(at: [indexPath])
                        } else {
                            self?.reloadConversationCollectionView()
                        }
                    }

                    // only for latest one need to scroll
                    if index == (strongSelf.displayedMessagesRange.location + strongSelf.displayedMessagesRange.length - 1) {
                        strongSelf.conversationCollectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
                    }
                }
            }
        })
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {

        guard let section = Section(rawValue: (indexPath as NSIndexPath).section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .loadPrevious:
            guard let cell = cell as? LoadMoreCollectionViewCell else {
                break
            }

            cell.loadingActivityIndicator.stopAnimating()
            
        case .message:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: IndexPath!) -> CGSize {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .loadPrevious:
            return CGSize(width: collectionViewWidth, height: 20)

        case .message:
            guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
                return CGSize(width: collectionViewWidth, height: 0)
            }

            let height = heightOfMessage(message)

            return CGSize(width: collectionViewWidth, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        guard let section = Section(rawValue: section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .loadPrevious:
            return UIEdgeInsets.zero

        case .message:
            return UIEdgeInsets(top: 5, left: 0, bottom: sectionInsetBottom, right: 0)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        switch messageToolbar.state {

        case .beginTextInput, .textInputing:
            messageToolbar.state = .default

        default:
            break
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

        let location = scrollView.panGestureRecognizer.location(in: view)
        dragBeginLocation = location
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        //println("contentInset: \(scrollView.contentInset)")
        //println("contentOffset: \(scrollView.contentOffset)")

        if let dragBeginLocation = dragBeginLocation {
            let location = scrollView.panGestureRecognizer.location(in: view)
            let deltaY = location.y - dragBeginLocation.y

            if deltaY < -30 {
                tryFoldFeedView()
            }
        }

        func tryTriggerLoadPrevious() {

            guard !noMorePreviousMessages else {
                return
            }

            guard scrollView.yep_isAtTop && (scrollView.isDragging || scrollView.isDecelerating) else {
                return
            }

            let indexPath = IndexPath(item: 0, section: Section.loadPrevious.rawValue)
            guard conversationCollectionViewHasBeenMovedToBottomOnce, let cell = conversationCollectionView.cellForItem(at: indexPath) as? LoadMoreCollectionViewCell else {
                return
            }

            guard !isLoadingPreviousMessages else {
                cell.loadingActivityIndicator.stopAnimating()
                return
            }

            cell.loadingActivityIndicator.startAnimating()

            _ = delay(0.5) { [weak self] in
                self?.tryLoadPreviousMessages { [weak cell] in
                    cell?.loadingActivityIndicator.stopAnimating()
                }
            }
        }

        tryTriggerLoadPrevious()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        dragBeginLocation = nil
    }
}


//
//  ChatLeftVideoCell.swift
//  Yep
//
//  Created by NIX on 15/4/23.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftVideoCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var thumbnailImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var playImageView: UIImageView!
    
    @IBOutlet weak var loadingProgressView: MessageLoadingProgressView!
    
    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageViewWidthConstraint.constant = YepConfig.chatCellAvatarSize()
        
        thumbnailImageView.tintColor = UIColor.leftBubbleTintColor()

        thumbnailImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        thumbnailImageView.addGestureRecognizer(tap)
    }

    func tapMediaView() {
        mediaTapAction?()
    }

    func loadingWithProgress(progress: Double) {

        println("loadingWithProgress \(progress)")

        if progress == 1.0 {
            loadingProgressView.hidden = true
            playImageView.hidden = false

        } else {
            loadingProgressView.progress = progress
            loadingProgressView.hidden = false
            playImageView.hidden = true
        }
    }

    func configureWithMessage(message: Message, messageImagePreferredWidth: CGFloat, messageImagePreferredHeight: CGFloat, messageImagePreferredAspectRatio: CGFloat, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.mediaTapAction = mediaTapAction

        playImageView.hidden = message.downloadState != MessageDownloadState.Downloaded.rawValue

        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { [unowned self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                            self.avatarImageView.image = roundImage
                        }
                    }
                }
            }
        }

        thumbnailImageView.alpha = 0.0

        if message.metaData.isEmpty {
            thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

            ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / messageImagePreferredAspectRatio)), tailDirection: .Left, loadingProgress: { [unowned self] progress in

                self.loadingWithProgress(progress)

            }, completion: { [unowned self] image in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self.thumbnailImageView.image = image

                        UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                            self.thumbnailImageView.alpha = 1.0
                        }, completion: { (finished) -> Void in
                        })
                    }
                }
            })

        } else {
            if let data = message.metaData.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                if let metaDataDict = decodeJSON(data) {
                    if
                        let imageWidth = metaDataDict["video_width"] as? CGFloat,
                        let imageHeight = metaDataDict["video_height"] as? CGFloat {

                            let aspectRatio = imageWidth / imageHeight

                            let messageImagePreferredWidth = max(messageImagePreferredWidth, ceil(YepConfig.ChatCell.mediaMinHeight * aspectRatio))
                            let messageImagePreferredHeight = max(messageImagePreferredHeight, ceil(YepConfig.ChatCell.mediaMinWidth / aspectRatio))
                            
                            if aspectRatio >= 1 {
                                thumbnailImageViewWidthConstraint.constant = messageImagePreferredWidth

                                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredWidth, height: ceil(messageImagePreferredWidth / aspectRatio)), tailDirection: .Left, loadingProgress: { [unowned self] progress in

                                    self.loadingWithProgress(progress)

                                }, completion: { [unowned self] image in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                                            self.thumbnailImageView.image = image

                                            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                                self.thumbnailImageView.alpha = 1.0
                                            }, completion: { (finished) -> Void in
                                            })
                                        }
                                    }
                                })

                            } else {
                                thumbnailImageViewWidthConstraint.constant = messageImagePreferredHeight * aspectRatio

                                ImageCache.sharedInstance.imageOfMessage(message, withSize: CGSize(width: messageImagePreferredHeight * aspectRatio, height: messageImagePreferredHeight), tailDirection: .Left, loadingProgress: { [unowned self] progress in

                                    self.loadingWithProgress(progress)
                                    
                                }, completion: { [unowned self] image in
                                    dispatch_async(dispatch_get_main_queue()) {
                                        if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                                            self.thumbnailImageView.image = image

                                            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                                self.thumbnailImageView.alpha = 1.0
                                            }, completion: { (finished) -> Void in
                                            })
                                        }
                                    }
                                })
                            }
                    }
                }
            }
        }
    }

}

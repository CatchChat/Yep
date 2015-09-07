//
//  ChatRightLocationCell.swift
//  Yep
//
//  Created by NIX on 15/5/5.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import MapKit

class ChatRightLocationCell: ChatRightBaseCell {

    @IBOutlet weak var mapImageView: UIImageView!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)

        mapImageView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - 5 - 192, y: 0, width: 192, height: 108)

        dotImageView.center = CGPoint(x: CGRectGetMinX(mapImageView.frame) - 5, y: CGRectGetMidY(mapImageView.frame))
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        makeUI()

        mapImageView.tintColor = UIColor.rightBubbleTintColor()

        mapImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        mapImageView.addGestureRecognizer(tap)
    }

    func tapMediaView() {
        mediaTapAction?()
    }

    func configureWithMessage(message: Message, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction

        if let sender = message.fromFriend {
            AvatarCache.sharedInstance.roundAvatarOfUser(sender, withRadius: YepConfig.chatCellAvatarSize() * 0.5) { [weak self] roundImage in
                dispatch_async(dispatch_get_main_queue()) {
                    if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                        self?.avatarImageView.image = roundImage
                    }
                }
            }
        }

        ImageCache.sharedInstance.mapImageOfMessage(message, withSize: CGSize(width: 192, height: 108), tailDirection: .Right) { mapImage in
            dispatch_async(dispatch_get_main_queue()) {
                if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                    self.mapImageView.image = mapImage
                }
            }
        }
    }
}


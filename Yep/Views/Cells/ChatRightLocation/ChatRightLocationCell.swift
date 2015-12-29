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
    @IBOutlet weak var locationNameLabel: UILabel!
    @IBOutlet weak var borderImageView: UIImageView!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: fullWidth - halfAvatarSize - YepConfig.chatCellGapBetweenWallAndAvatar(), y: halfAvatarSize)

        mapImageView.frame = CGRect(x: CGRectGetMinX(avatarImageView.frame) - YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble - 192, y: 0, width: 192, height: 108)

        borderImageView.frame = mapImageView.frame

        dotImageView.center = CGPoint(x: CGRectGetMinX(mapImageView.frame) - YepConfig.ChatCell.gapBetweenDotImageViewAndBubble, y: CGRectGetMidY(mapImageView.frame))

        let locationNameLabelHeight = YepConfig.ChatCell.locationNameLabelHeight
        locationNameLabel.frame = CGRect(x: CGRectGetMinX(mapImageView.frame) + 20, y: CGRectGetMaxY(mapImageView.frame) - locationNameLabelHeight, width: 192 - 20 * 2 - 7, height: locationNameLabelHeight)
        //locationNameLabel.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.1)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        mapImageView.tintColor = UIColor.rightBubbleTintColor()
        locationNameLabel.textColor = UIColor.whiteColor()

        mapImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        mapImageView.addGestureRecognizer(tap)
        
        prepareForMenuAction = { otherGesturesEnabled in
            tap.enabled = otherGesturesEnabled
        }
    }

    func tapMediaView() {
        mediaTapAction?()
    }

    func configureWithMessage(message: Message, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.message = message
        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        let locationName = message.textContent
        
        locationNameLabel.text = locationName

        ImageCache.sharedInstance.mapImageOfMessage(message, withSize: CGSize(width: 192, height: 108), tailDirection: .Right, bottomShadowEnabled: !locationName.isEmpty) { mapImage in
            dispatch_async(dispatch_get_main_queue()) {
                if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                    self.mapImageView.image = mapImage
                }
            }
        }
    }
}


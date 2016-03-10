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

    lazy var mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.rightBubbleTintColor()
        return imageView
    }()

    lazy var locationNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.systemFontOfSize(12)
        label.textAlignment = .Center
        return label
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "right_tail_image_bubble_border"))
        return imageView
    }()

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
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(mapImageView)
        contentView.addSubview(locationNameLabel)
        contentView.addSubview(borderImageView)

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        mapImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        mapImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.enabled = otherGesturesEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
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


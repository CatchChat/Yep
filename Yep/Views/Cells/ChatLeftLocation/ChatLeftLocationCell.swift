//
//  ChatLeftLocationCell.swift
//  Yep
//
//  Created by NIX on 15/5/5.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatLeftLocationCell: ChatBaseCell {

    @IBOutlet weak var mapImageView: UIImageView!
    @IBOutlet weak var locationNameLabel: UILabel!

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        //let fullWidth = UIScreen.mainScreen().bounds.width

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize)

        mapImageView.frame = CGRect(x: CGRectGetMaxX(avatarImageView.frame) + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: 0, width: 192, height: 108)

        let locationNameLabelHeight = YepConfig.ChatCell.locationNameLabelHeight
        locationNameLabel.frame = CGRect(x: CGRectGetMinX(mapImageView.frame) + 20 + 7, y: CGRectGetMaxY(mapImageView.frame) - locationNameLabelHeight, width: 192 - 20 * 2 - 7, height: locationNameLabelHeight)
        //locationNameLabel.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.1)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.makeUI()
        }

        mapImageView.tintColor = UIColor.leftBubbleTintColor()
        locationNameLabel.textColor = UIColor.whiteColor()

        mapImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapMediaView")
        mapImageView.addGestureRecognizer(tap)
    }

    func tapMediaView() {
        mediaTapAction?()
    }
    
    func configureWithMessage(message: Message, mediaTapAction: MediaTapAction?, collectionView: UICollectionView, indexPath: NSIndexPath) {

        self.user = message.fromFriend

        self.mediaTapAction = mediaTapAction

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar)
        }

        let locationName = message.textContent

        locationNameLabel.text = locationName

        ImageCache.sharedInstance.mapImageOfMessage(message, withSize: CGSize(width: 192, height: 108), tailDirection: .Left, bottomShadowEnabled: !locationName.isEmpty) { mapImage in
            dispatch_async(dispatch_get_main_queue()) {
                if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                    self.mapImageView.image = mapImage
                }
            }
        }
    }
}


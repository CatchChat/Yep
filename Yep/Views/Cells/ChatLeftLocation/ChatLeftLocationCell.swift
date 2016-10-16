//
//  ChatLeftLocationCell.swift
//  Yep
//
//  Created by NIX on 15/5/5.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ChatLeftLocationCell: ChatBaseCell {

    static fileprivate let mapSize = CGSize(width: 192, height: 108)

    lazy var mapImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = UIColor.leftBubbleTintColor()
        return imageView
    }()

    lazy var locationNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        return label
    }()

    lazy var borderImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.yep_leftTailImageBubbleBorder)
        return imageView
    }()

    typealias MediaTapAction = () -> Void
    var mediaTapAction: MediaTapAction?

    func makeUI() {

        let halfAvatarSize = YepConfig.chatCellAvatarSize() / 2
        
        var topOffset: CGFloat = 0
        
        if inGroup {
            topOffset = YepConfig.ChatCell.marginTopForGroup
        } else {
            topOffset = 0
        }

        avatarImageView.center = CGPoint(x: YepConfig.chatCellGapBetweenWallAndAvatar() + halfAvatarSize, y: halfAvatarSize + topOffset)
        
        mapImageView.frame = CGRect(x: avatarImageView.frame.maxX + YepConfig.ChatCell.gapBetweenAvatarImageViewAndBubble, y: topOffset, width: 192, height: 108)

        borderImageView.frame = mapImageView.frame

        let locationNameLabelHeight = YepConfig.ChatCell.locationNameLabelHeight
        
        locationNameLabel.frame = CGRect(x: mapImageView.frame.minX + 20 + 7, y: mapImageView.frame.maxY - locationNameLabelHeight, width: 192 - 20 * 2 - 7, height: locationNameLabelHeight)

        configureNameLabel()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(mapImageView)
        contentView.addSubview(locationNameLabel)
        contentView.addSubview(borderImageView)

        UIView.performWithoutAnimation { [weak self] in
            self?.makeUI()
        }

        mapImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(ChatLeftLocationCell.tapMediaView))
        mapImageView.addGestureRecognizer(tap)

        prepareForMenuAction = { otherGesturesEnabled in
            tap.isEnabled = otherGesturesEnabled
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tapMediaView() {
        mediaTapAction?()
    }
    
    func configureWithMessage(_ message: Message, mediaTapAction: MediaTapAction?) {

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

        mapImageView.yep_setMapImageOfMessage(message, withSize: ChatLeftLocationCell.mapSize, tailDirection: .left)
    }
    
    fileprivate func configureNameLabel() {

        if inGroup {
            nameLabel.text = user?.compositedName

            let height = YepConfig.ChatCell.nameLabelHeightForGroup
            let x = avatarImageView.frame.maxX + YepConfig.chatCellGapBetweenTextContentLabelAndAvatar()
            let y = mapImageView.frame.origin.y - height
            let width = contentView.bounds.width - x - 10
            nameLabel.frame = CGRect(x: x, y: y, width: width, height: height)
        }
    }
}


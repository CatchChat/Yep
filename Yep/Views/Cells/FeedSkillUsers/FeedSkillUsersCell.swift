//
//  FeedSkillUsersCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FeedSkillUsersCell: UITableViewCell {

    @IBOutlet weak var promptLabel: UILabel!

    @IBOutlet weak var avatarImageView1: UIImageView!
    @IBOutlet weak var avatarImageView2: UIImageView!
    @IBOutlet weak var avatarImageView3: UIImageView!

    @IBOutlet weak var accessoryImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        promptLabel.text = NSLocalizedString("People with this skill", comment: "")

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }

    func configureWithFeeds(feeds: [DiscoveredFeed]) {

        let feedCreators = Array(Set(feeds.map({ $0.creator }))).sort { $0.lastSignInUnixTime > $1.lastSignInUnixTime }

        if let creator = feedCreators[safe: 0] {
            let plainAvatar = PlainAvatar(avatarURLString: creator.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView1.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        } else {
            avatarImageView1.image = nil
        }

        if let creator = feedCreators[safe: 1] {
            let plainAvatar = PlainAvatar(avatarURLString: creator.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView2.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        } else {
            avatarImageView2.image = nil
        }

        if let creator = feedCreators[safe: 2] {
            let plainAvatar = PlainAvatar(avatarURLString: creator.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView3.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        } else {
            avatarImageView3.image = nil
        }
    }
}


//
//  ContactsCell.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ContactsCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var joinedDateLabel: UILabel!
    @IBOutlet weak var lastTimeSeenLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser, tableView: UITableView, indexPath: NSIndexPath) {

//        let radius = min(CGRectGetWidth(avatarImageView.bounds), CGRectGetHeight(avatarImageView.bounds)) * 0.5
//
//        let avatarURLString = discoveredUser.avatarURLString
//        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { [weak self] roundImage in
//            dispatch_async(dispatch_get_main_queue()) {
//                if let _ = tableView.cellForRowAtIndexPath(indexPath) {
//                    self?.avatarImageView.image = roundImage
//                }
//            }
//        }
        let userAvatar = UserAvatar(userID: discoveredUser.id, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar)

        joinedDateLabel.text = discoveredUser.introduction

        if let distance = discoveredUser.distance?.format(".1") {
            lastTimeSeenLabel.text = "\(distance)km | \(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"
        } else {
            lastTimeSeenLabel.text = "\(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"
        }

        nameLabel.text = discoveredUser.nickname

        if let badgeName = discoveredUser.badge, badge = BadgeView.Badge(rawValue: badgeName) {
            badgeImageView.image = badge.image
            badgeImageView.tintColor = badge.color
        } else {
            badgeImageView.image = nil
        }
    }
}

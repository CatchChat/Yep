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

        separatorInset = YepConfig.ContactsCell.separatorInset
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
    }

    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser, tableView: UITableView, indexPath: NSIndexPath) {

        let plainAvatar = PlainAvatar(avatarURLString: discoveredUser.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

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

//
//  ContactsCell.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ContactsCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var badgeImageView: UIImageView!
    @IBOutlet weak var joinedDateLabel: UILabel!
    @IBOutlet weak var lastTimeSeenLabel: UILabel!

    var showProfileAction: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = YepConfig.ContactsCell.separatorInset
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
    }

    func configureWithUser(user: User) {

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ContactsCell.tapAvatar))
        avatarImageView.addGestureRecognizer(tap)
        avatarImageView.userInteractionEnabled = true
            
        nameLabel.text = user.nickname

        if let badge = BadgeView.Badge(rawValue: user.badge) {
            badgeImageView.image = badge.image
            badgeImageView.tintColor = badge.color
        } else {
            badgeImageView.image = nil
        }

        joinedDateLabel.text = user.introduction
        lastTimeSeenLabel.text = String(format:NSLocalizedString("Last seen %@", comment: ""), NSDate(timeIntervalSince1970: user.lastSignInUnixTime).timeAgo.lowercaseString)
    }
    
    @objc private func tapAvatar() {
        showProfileAction?()
    }

    func configureForSearchWithUser(user: User) {

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nameLabel.text = user.compositedName

        if let badge = BadgeView.Badge(rawValue: user.badge) {
            badgeImageView.image = badge.image
            badgeImageView.tintColor = badge.color
        } else {
            badgeImageView.image = nil
        }

        joinedDateLabel.text = user.introduction
        lastTimeSeenLabel.text = String(format: NSLocalizedString("Last seen %@", comment: ""), NSDate(timeIntervalSince1970: user.lastSignInUnixTime).timeAgo.lowercaseString)
    }

    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser) {

        let plainAvatar = PlainAvatar(avatarURLString: discoveredUser.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        joinedDateLabel.text = discoveredUser.introduction

        if let distance = discoveredUser.distance?.yep_format(".1") {
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

    func configureForSearchWithDiscoveredUser(discoveredUser: DiscoveredUser) {

        let plainAvatar = PlainAvatar(avatarURLString: discoveredUser.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        joinedDateLabel.text = discoveredUser.introduction

        if let distance = discoveredUser.distance?.yep_format(".1") {
            lastTimeSeenLabel.text = "\(distance)km | \(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"
        } else {
            lastTimeSeenLabel.text = "\(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"
        }

        nameLabel.text = discoveredUser.compositedName

        if let badgeName = discoveredUser.badge, badge = BadgeView.Badge(rawValue: badgeName) {
            badgeImageView.image = badge.image
            badgeImageView.tintColor = badge.color
        } else {
            badgeImageView.image = nil
        }
    }
}


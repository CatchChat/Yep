//
//  DiscoverNormalUserCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class DiscoverNormalUserCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var joinedDateLabel: UILabel!
    
    @IBOutlet weak var lastTimeSeenLabel: UILabel!
    
    @IBOutlet weak var badgeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
    }
    
    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser, collectionView: UICollectionView, indexPath: NSIndexPath) {
 
        let plainAvatar = PlainAvatar(avatarURLString: discoveredUser.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: bigAvatarFadeTransitionDuration)
        
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
}

//
//  DiscoverNormalUserCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverNormalUserCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var joinedDateLabel: UILabel!
    
    @IBOutlet weak var lastTimeSeenLabel: UILabel!
    
    @IBOutlet weak var badgeImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser, collectionView: UICollectionView, indexPath: NSIndexPath) {
        
        let radius = min(CGRectGetWidth(avatarImageView.bounds), CGRectGetHeight(avatarImageView.bounds)) * 0.5
        
        let avatarURLString = discoveredUser.avatarURLString
        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: radius) { [weak self] roundImage in
            dispatch_async(dispatch_get_main_queue()) {
                if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                    self?.avatarImageView.image = roundImage
                }
            }
        }
        
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

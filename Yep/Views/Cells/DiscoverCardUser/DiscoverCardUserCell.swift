//
//  DiscoverCardUserCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverCardUserCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var userIntroductionLbael: UILabel!
    
    @IBOutlet weak var userSkillsCollectionView: UICollectionView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userSkillsCollectionView.backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.whiteColor()
        contentView.layer.cornerRadius  = 6
        contentView.layer.masksToBounds = true
        avatarImageView.contentMode = UIViewContentMode.ScaleAspectFill
        avatarImageView.clipsToBounds = true
    }
    
    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser, collectionView: UICollectionView, indexPath: NSIndexPath) {
        
//        let radius = min(CGRectGetWidth(avatarImageView.bounds), CGRectGetHeight(avatarImageView.bounds)) * 0.5
        
        let avatarURLString = discoveredUser.avatarURLString
        
        AvatarCache.sharedInstance.avatarFromURL(NSURL(string: avatarURLString)!) {[weak self] (isFinish, image) -> () in
            dispatch_async(dispatch_get_main_queue()) {
                if let _ = collectionView.cellForItemAtIndexPath(indexPath) {
                    self?.avatarImageView.image = image
                }
            }
        }
        
        
        userIntroductionLbael.text = discoveredUser.introduction
//        if let distance = discoveredUser.distance?.format(".1") {
//            lastTimeSeenLabel.text = "\(distance)km | \(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"
//        } else {
//            lastTimeSeenLabel.text = "\(NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo)"
//        }
        
        usernameLabel.text = discoveredUser.nickname
        
    }

}

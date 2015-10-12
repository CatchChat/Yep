//
//  DiscoverCardUserCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverCardUserCell: UICollectionViewCell {
    
    let skillCellIdentifier = "SkillCell"

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var userIntroductionLbael: UILabel!
    
    @IBOutlet weak var userSkillsCollectionView: UICollectionView!
    
    var discoveredUser: DiscoveredUser?
    
    let skillTextAttributes = [NSFontAttributeName: UIFont.skillTextFont()]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        userSkillsCollectionView.backgroundColor = UIColor.clearColor()
        contentView.backgroundColor = UIColor.whiteColor()
        contentView.layer.cornerRadius  = 6
        contentView.layer.masksToBounds = true
        
        contentView.layer.borderColor = UIColor.yepCellSeparatorColor().CGColor
        contentView.layer.borderWidth = 1.0
        
        avatarImageView.contentMode = UIViewContentMode.ScaleAspectFill
        avatarImageView.clipsToBounds = true
        
        userSkillsCollectionView.delegate = self
        userSkillsCollectionView.dataSource = self
        
        userSkillsCollectionView.registerNib(UINib(nibName: skillCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCellIdentifier)
    }
    
    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser, collectionView: UICollectionView, indexPath: NSIndexPath) {
        
//        let radius = min(CGRectGetWidth(avatarImageView.bounds), CGRectGetHeight(avatarImageView.bounds)) * 0.5
        self.discoveredUser = discoveredUser
        
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
        
        userSkillsCollectionView.reloadData()
        
    }

}

extension DiscoverCardUserCell:  UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let discoveredUser = discoveredUser {
            return discoveredUser.masterSkills.count
        } else {
            return 0
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if let discoveredUser = discoveredUser {
            
            let skillLocalName = discoveredUser.masterSkills[indexPath.row].localName ?? ""
            
            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)
            
            return CGSize(width: rect.width + 24, height: SkillCell.height)
        } else {
            return CGSizeZero
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        if let discoveredUser = discoveredUser {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! SkillCell
            
            cell.skillLabel.text = discoveredUser.masterSkills[indexPath.row].localName ?? ""
            
            return cell
        } else {
            return UICollectionViewCell()
        }

    }
}

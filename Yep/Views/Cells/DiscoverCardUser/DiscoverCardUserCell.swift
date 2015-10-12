//
//  DiscoverCardUserCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/10.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverCardUserCell: UICollectionViewCell {
    
    @IBOutlet weak var serviceImageView: UIImageView!
    
    let skillCellIdentifier = "DiscoverSkillCell"

    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var userIntroductionLbael: UILabel!
    
    @IBOutlet weak var userSkillsCollectionView: UICollectionView!
    
    var discoveredUser: DiscoveredUser?
    
    let skillTextAttributes = [NSFontAttributeName: UIFont.skillDiscoverTextFont()]
    
    let discoverCellHeight: CGFloat = 16
    
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
        userSkillsCollectionView.setCollectionViewLayout(MiniCardSkillLayout(), animated: false)
        
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
        
        if let accountName = discoveredUser.recently_updated_provider, account = SocialAccount(rawValue: accountName) {
            serviceImageView.image = UIImage(named: account.iconName)
            serviceImageView.tintColor = account.tintColor
        } else {
            serviceImageView.image = nil
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
            if discoveredUser.masterSkills.count > 4 {
                return 4
            } else {
                return discoveredUser.masterSkills.count
            }
        } else {
            return 0
        }
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        if let discoveredUser = discoveredUser {
            
            let skillLocalName = discoveredUser.masterSkills[indexPath.row].localName ?? ""
            
            let rect = skillLocalName.boundingRectWithSize(CGSize(width: CGFloat(FLT_MAX), height: SkillCell.height), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: skillTextAttributes, context: nil)
            
            return CGSize(width: rect.width + 12, height: discoverCellHeight)
        } else {
            return CGSizeZero
        }
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        if let discoveredUser = discoveredUser {
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCellIdentifier, forIndexPath: indexPath) as! DiscoverSkillCell
            
//            cell.skillLabel.font = UIFont.skillDiscoverTextFont()
            cell.skillLabel.text = discoveredUser.masterSkills[indexPath.row].localName ?? ""
//            cell.backgroundImageView.image = UIImage(named: "minicard_bubble")
//            cell.backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
            
            return cell
        } else {
            return UICollectionViewCell()
        }

    }
}

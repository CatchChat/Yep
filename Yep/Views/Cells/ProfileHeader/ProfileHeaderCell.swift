//
//  ProfileHeaderCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileHeaderCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var joinedDateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.hidden = true
        joinedDateLabel.hidden = true

        YepUserDefaults.avatarURLString.bindAndFireListener("ProfileHeaderCell.Avatar") { _ in
            self.updateAvatar()
        }
        
        YepLocationService.sharedManager
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateAddress", name: "YepLocationUpdated", object: nil)
    }

    func updateAvatar() {
        avatarImageView.alpha = 0
        if let avatarURLString = YepUserDefaults.avatarURLString.value {
            AvatarCache.sharedInstance.avatarFromURL(NSURL(string: avatarURLString)!) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = image
                    UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                        self.avatarImageView.alpha = 1
                    }, completion: { (finished) -> Void in
                    })
                }
            }
        }
    }
    
    func updateAddress() {
        
        println("Location YepLocationUpdated")
        
        self.locationLabel.text = YepLocationService.sharedManager.address
    }
    
}

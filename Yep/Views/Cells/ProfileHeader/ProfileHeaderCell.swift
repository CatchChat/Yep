//
//  ProfileHeaderCell.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileHeaderCell: UICollectionViewCell {

    var changeAvatarAction: (() -> Void)?


    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var joinedDateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.alpha = 1
        
        let tap = UITapGestureRecognizer(target: self, action: "tryChangeAvatar")
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tap)

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let avatarURLString = YepUserDefaults.avatarURLString() {
                if let url = NSURL(string: avatarURLString) {
                    if let data = NSData(contentsOfURL: url) {
                        let image = UIImage(data: data)

                        dispatch_async(dispatch_get_main_queue()) {
                            self.avatarImageView.image = image

                            UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                                self.avatarImageView.alpha = 1
                            }, completion: { (finished) -> Void in
                            })
                        }
                    }
                }
            }
        }
    }
    
    func tryChangeAvatar() {
        if let changeAvatarAction = changeAvatarAction {
            changeAvatarAction()
        }
    }
}

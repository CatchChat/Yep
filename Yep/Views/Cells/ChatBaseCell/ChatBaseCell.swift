//
//  ChatBaseCell.swift
//  Yep
//
//  Created by nixzhu on 15/8/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ChatBaseCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!

    var user: User?

    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tapAvatar")
        avatarImageView.addGestureRecognizer(tap)
    }

    func tapAvatar() {
        println("tapAvatar")
    }
}
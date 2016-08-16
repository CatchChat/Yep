//
//  AddFriendMoreCell.swift
//  Yep
//
//  Created by NIX on 15/5/19.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class AddFriendMoreCell: UITableViewCell {

    @IBOutlet weak var annotationLabel: UILabel!
    @IBOutlet weak var accessoryImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }
}


//
//  EditProfileColoredTitleCell.swift
//  Yep
//
//  Created by NIX on 15/4/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class EditProfileColoredTitleCell: UITableViewCell {

    @IBOutlet weak var coloredTitleLabel: UILabel!

    var coloredTitleColor: UIColor = UIColor.redColor() {
        willSet {
            coloredTitleLabel.textColor = newValue
        }
    }
}


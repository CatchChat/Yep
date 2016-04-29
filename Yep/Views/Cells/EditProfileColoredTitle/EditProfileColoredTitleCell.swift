//
//  EditProfileColoredTitleCell.swift
//  Yep
//
//  Created by NIX on 15/4/27.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class EditProfileColoredTitleCell: UITableViewCell {

    var coloredTitleColor: UIColor = UIColor.redColor() {
        willSet {
            coloredTitleLabel.textColor = newValue
        }
    }

    @IBOutlet weak var coloredTitleLabel: UILabel!


    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

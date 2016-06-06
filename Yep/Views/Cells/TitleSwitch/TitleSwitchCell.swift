//
//  TitleSwitchCell.swift
//  Yep
//
//  Created by NIX on 16/6/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class TitleSwitchCell: UITableViewCell {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
        return label
    }()

    lazy var toggleSwitch: UISwitch = {
        let s = UISwitch()
        return s
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

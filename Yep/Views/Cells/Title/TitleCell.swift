//
//  TitleCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class TitleCell: UITableViewCell {

    @IBOutlet weak var singleTitleLabel: UILabel!

    var boldEnabled = false {
        didSet {
            singleTitleLabel.font = boldEnabled ? UIFont.boldSystemFontOfSize(17) : UIFont.systemFontOfSize(17)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}


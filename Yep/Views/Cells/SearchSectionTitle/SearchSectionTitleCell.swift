//
//  SearchSectionTitleCell.swift
//  Yep
//
//  Created by NIX on 16/4/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchSectionTitleCell: UITableViewCell {

    @IBOutlet weak var sectionTitleLabel: UILabel! {
        didSet {
            sectionTitleLabel.textColor = UIColor(white: 0.4, alpha: 1.0)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .None
        separatorInset = YepConfig.SearchedItemCell.separatorInset
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

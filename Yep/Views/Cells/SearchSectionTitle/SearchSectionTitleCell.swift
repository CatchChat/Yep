//
//  SearchSectionTitleCell.swift
//  Yep
//
//  Created by NIX on 16/4/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepConfig

final class SearchSectionTitleCell: UITableViewCell {

    @IBOutlet weak var sectionTitleLabel: UILabel! {
        didSet {
            sectionTitleLabel.textColor = UIColor(red: 142/255.0, green: 142/255.0, blue: 147/255.0, alpha: 1)
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

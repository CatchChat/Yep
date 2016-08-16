//
//  SearchMoreResultsCell.swift
//  Yep
//
//  Created by NIX on 16/4/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class SearchMoreResultsCell: UITableViewCell {

    var fold: Bool = true {
        didSet {
            if fold {
                showMoreLabel.text = NSLocalizedString("Show More", comment: "")
                arrowImageView.image = UIImage.yep_iconArrowDown
            } else {
                showMoreLabel.text = NSLocalizedString("Hide", comment: "")
                arrowImageView.image = UIImage.yep_iconArrowUp
            }
        }
    }

    @IBOutlet weak var showMoreLabel: UILabel! {
        didSet {
            showMoreLabel.textColor = UIColor.yep_mangmorGrayColor()
        }
    }
    @IBOutlet weak var arrowImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .None
        separatorInset = YepConfig.SearchedItemCell.separatorInset
    }
}
    

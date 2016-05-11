//
//  FeedFilterCell.swift
//  Yep
//
//  Created by NIX on 16/5/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class FeedFilterCell: UITableViewCell {

    @IBOutlet weak var segmentedControl: UISegmentedControl! {
        didSet {
            segmentedControl.setTitle(NSLocalizedString("Recommendation", comment: ""), forSegmentAtIndex: 0)
            segmentedControl.setTitle(NSLocalizedString("Lately", comment: ""), forSegmentAtIndex: 1)
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

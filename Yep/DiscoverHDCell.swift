//
//  DiscoverHDCell.swift
//  Yep
//
//  Created by ROC Zhang on 16/2/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

struct DiscoverHDCellItemsGrounp {
    let ItemIcon : String
    let ItemLabel : String
}

class DiscoverHDCell: UITableViewCell {

    @IBOutlet weak var ItemIcon: UIImageView!
    @IBOutlet weak var ItemLabel: UILabel!

    @IBOutlet weak var ItemBackgroundImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}

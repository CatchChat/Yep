//
//  LoadMoreTableViewCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class LoadMoreTableViewCell: UITableViewCell {

    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = UIEdgeInsets(top: 0, left: UIScreen.mainScreen().bounds.width, bottom: 0, right: 0)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

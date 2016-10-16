//
//  LoadMoreTableViewCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/30.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class LoadMoreTableViewCell: UITableViewCell {

    var isLoading: Bool = false {
        didSet {
            if isLoading {
                loadingActivityIndicator.startAnimating()
                noMoreResultsLabel.isHidden = true
            } else {
                loadingActivityIndicator.stopAnimating()
                noMoreResultsLabel.isHidden = false
            }
        }
    }

    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var noMoreResultsLabel: UILabel! {
        didSet {
            noMoreResultsLabel.textColor = UIColor.yep_mangmorGrayColor()
            noMoreResultsLabel.text = String.trans_promptNoMoreResults
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = UIEdgeInsets(top: 0, left: UIScreen.main.bounds.width, bottom: 0, right: 0)
        noMoreResultsLabel.isHidden = true
    }
}
    

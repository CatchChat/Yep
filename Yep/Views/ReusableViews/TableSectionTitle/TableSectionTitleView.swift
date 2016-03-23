//
//  TableSectionTitleView.swift
//  Yep
//
//  Created by NIX on 16/3/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class TableSectionTitleView: UITableViewHeaderFooterView {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(15)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "titleLable": titleLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[titleLable]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[titleLable]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }
}

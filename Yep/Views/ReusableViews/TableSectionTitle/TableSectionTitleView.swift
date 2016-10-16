//
//  TableSectionTitleView.swift
//  Yep
//
//  Created by NIX on 16/3/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

final class TableSectionTitleView: UITableViewHeaderFooterView {

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 0.502, green: 0.502, blue: 0.502, alpha: 1)
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "titleLabel": titleLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLabel]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[titleLabel]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)
    }
}

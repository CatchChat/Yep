//
//  MentionView.swift
//  Yep
//
//  Created by nixzhu on 16/1/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class MentionView: UIView {

    static let height: CGFloat = 150

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.redColor()
        return tableView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "tableView": tableView,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[tableView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }
}


//
//  ConversationMoreView.swift
//  Yep
//
//  Created by NIX on 15/6/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationMoreView: UIView {

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        return view
        }()

    lazy var tableView: UITableView = {
        let view = UITableView()
        return view
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {
        addSubview(containerView)
        containerView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "containerView": containerView,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

}

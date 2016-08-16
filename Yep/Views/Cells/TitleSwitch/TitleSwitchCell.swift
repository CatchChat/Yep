//
//  TitleSwitchCell.swift
//  Yep
//
//  Created by NIX on 16/6/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class TitleSwitchCell: UITableViewCell {

    var toggleSwitchStateChangedAction: ((on: Bool) -> Void)?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
        label.text = "Title"
        return label
    }()

    lazy var toggleSwitch: UISwitch = {
        let s = UISwitch()
        s.addTarget(self, action: #selector(TitleSwitchCell.toggleSwitchStateChanged(_:)), forControlEvents: .ValueChanged)
        return s
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func toggleSwitchStateChanged(sender: UISwitch) {

        toggleSwitchStateChangedAction?(on: sender.on)
    }

    private func makeUI() {

        contentView.addSubview(titleLabel)
        contentView.addSubview(toggleSwitch)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "titleLable": titleLabel,
            "toggleSwitch": toggleSwitch,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[titleLable]-[toggleSwitch]-20-|", options: [.AlignAllCenterY], metrics: nil, views: views)

        let centerY = titleLabel.centerYAnchor.constraintEqualToAnchor(contentView.centerYAnchor)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints([centerY])
    }
}


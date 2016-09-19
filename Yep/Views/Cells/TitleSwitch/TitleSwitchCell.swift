//
//  TitleSwitchCell.swift
//  Yep
//
//  Created by NIX on 16/6/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class TitleSwitchCell: UITableViewCell {

    var toggleSwitchStateChangedAction: ((_ on: Bool) -> Void)?

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)
        label.text = "Title"
        return label
    }()

    lazy var toggleSwitch: UISwitch = {
        let s = UISwitch()
        s.addTarget(self, action: #selector(TitleSwitchCell.toggleSwitchStateChanged(_:)), for: .valueChanged)
        return s
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc fileprivate func toggleSwitchStateChanged(_ sender: UISwitch) {

        toggleSwitchStateChangedAction?(sender.isOn)
    }

    fileprivate func makeUI() {

        contentView.addSubview(titleLabel)
        contentView.addSubview(toggleSwitch)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toggleSwitch.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "titleLable": titleLabel,
            "toggleSwitch": toggleSwitch,
        ] as [String : Any]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[titleLable]-[toggleSwitch]-20-|", options: [.alignAllCenterY], metrics: nil, views: views)

        let centerY = titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate([centerY])
    }
}


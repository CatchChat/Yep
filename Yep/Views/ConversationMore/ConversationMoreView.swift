//
//  ConversationMoreView.swift
//  Yep
//
//  Created by NIX on 15/6/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationMoreDetailCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .DisclosureIndicator

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        textLabel?.textColor = UIColor.darkGrayColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ConversationMoreCheckCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        textLabel?.textColor = UIColor.darkGrayColor()

        makeUI()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var checkedSwitch: UISwitch = {
        let s = UISwitch()
        return s
        }()

    func makeUI() {
        contentView.addSubview(checkedSwitch)
        checkedSwitch.setTranslatesAutoresizingMaskIntoConstraints(false)

        let checkedSwitchConstraintCenterY = NSLayoutConstraint(item: checkedSwitch, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let checkedSwitchConstraintTrailing = NSLayoutConstraint(item: checkedSwitch, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1, constant: -20)

        NSLayoutConstraint.activateConstraints([checkedSwitchConstraintCenterY, checkedSwitchConstraintTrailing])
    }
}

class ConversationMoreView: UIView {

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        return view
        }()

    lazy var tableView: UITableView = {
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = 60
        view.scrollEnabled = false

        view.registerClass(ConversationMoreDetailCell.self, forCellReuseIdentifier: "ConversationMoreDetailCell")
        view.registerClass(ConversationMoreCheckCell.self, forCellReuseIdentifier: "ConversationMoreCheckCell")
        return view
        }()

    var showProfileAction: (() -> Void)?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        addSubview(containerView)
        containerView.setTranslatesAutoresizingMaskIntoConstraints(false)

        containerView.addSubview(tableView)
        tableView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "containerView": containerView,
            "tableView": tableView,
        ]

        // layout for containerView

        let containerViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(containerViewConstraintsH)
        NSLayoutConstraint.activateConstraints(containerViewConstraintsV)

        // layour for tableView

        let tableViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let tableViewBottomConstraint = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: containerView, attribute: .Bottom, multiplier: 1.0, constant: 0)

        let tableViewHeightConstraint = NSLayoutConstraint(item: tableView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 300)

        NSLayoutConstraint.activateConstraints(tableViewConstraintsH)
        NSLayoutConstraint.activateConstraints([tableViewBottomConstraint, tableViewHeightConstraint])
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ConversationMoreView: UITableViewDataSource, UITableViewDelegate {

    enum Row: Int {
        case ShowProfile = 0
        case DoNotDisturb
        case Report
        case Block
        case Cancel
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let row = Row(rawValue: indexPath.row) {
            switch row {

            case .ShowProfile:
                let cell = tableView.dequeueReusableCellWithIdentifier("ConversationMoreDetailCell") as! ConversationMoreDetailCell

                cell.textLabel?.text = NSLocalizedString("View profile", comment: "")

                return cell

            case .DoNotDisturb:

                let cell = tableView.dequeueReusableCellWithIdentifier("ConversationMoreCheckCell") as! ConversationMoreCheckCell

                cell.textLabel?.text = NSLocalizedString("Do not disturb", comment: "")

                return cell

            default:
                break
            }
        }

        return UITableViewCell()
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        if let row = Row(rawValue: indexPath.row) {
            switch row {

            case .ShowProfile:
                showProfileAction?()

            default:
                break
            }
        }
    }
}


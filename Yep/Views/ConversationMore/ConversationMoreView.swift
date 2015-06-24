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

        let centerY = NSLayoutConstraint(item: checkedSwitch, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: checkedSwitch, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1, constant: -20)

        NSLayoutConstraint.activateConstraints([centerY, trailing])
    }
}

class ConversationMoreColorTitleCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        makeUI()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var colorTitleLabel: UILabel = {
        let label = UILabel()
        return label
        }()

    var colorTitleLabelTextColor: UIColor = UIColor.yepTintColor() {
        willSet {
            colorTitleLabel.textColor = newValue
        }
    }

    enum FontStyle {
        case Light
        case Regular
    }

    var colorTitleLabelFontStyle: FontStyle = .Light {
        willSet {
            switch newValue {
            case .Light:
                colorTitleLabel.font = UIFont(name: "Helvetica-Light", size: 18)!
            case .Regular:
                colorTitleLabel.font = UIFont(name: "Helvetica", size: 18)!
            }
        }
    }

    func makeUI() {

        contentView.addSubview(colorTitleLabel)
        colorTitleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)

        let centerY = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let centerX = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([centerY, centerX])
    }
}

class ConversationMoreView: UIView {

    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
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
        view.registerClass(ConversationMoreColorTitleCell.self, forCellReuseIdentifier: "ConversationMoreColorTitleCell")
        return view
        }()

    var showProfileAction: (() -> Void)?

    var toggleDoNotDisturbAction: (() -> Void)?

    var reportAction: (() -> Void)?

    var tableViewBottomConstraint: NSLayoutConstraint?

    func showInView(view: UIView) {

        frame = view.bounds

        view.addSubview(self)

        layoutIfNeeded()

        UIView.animateWithDuration(0.05, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.containerView.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.3)

        }, completion: { finished in
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.tableViewBottomConstraint?.constant = 0

                self.layoutIfNeeded()

            }, completion: { finished in
            })
        })
    }

    func hide() {

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
            self.tableViewBottomConstraint?.constant = 300

            self.layoutIfNeeded()

        }, completion: { finished in

            UIView.animateWithDuration(0.05, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.containerView.backgroundColor = UIColor.clearColor()

            }, completion: { finished in
                self.removeFromSuperview()
            })
        })
    }

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

        let tableViewBottomConstraint = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: containerView, attribute: .Bottom, multiplier: 1.0, constant: 300)

        self.tableViewBottomConstraint = tableViewBottomConstraint

        let tableViewHeightConstraint = NSLayoutConstraint(item: tableView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 300)

        NSLayoutConstraint.activateConstraints(tableViewConstraintsH)
        NSLayoutConstraint.activateConstraints([tableViewBottomConstraint, tableViewHeightConstraint])
    }
}

// MARK: - Actions

extension ConversationMoreView {

    func toggleDoNotDisturb() {
        toggleDoNotDisturbAction?()
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
                cell.checkedSwitch.addTarget(self, action: "toggleDoNotDisturb", forControlEvents: UIControlEvents.ValueChanged)

                return cell

            case .Report:
                let cell = tableView.dequeueReusableCellWithIdentifier("ConversationMoreColorTitleCell") as! ConversationMoreColorTitleCell

                cell.colorTitleLabel.text = NSLocalizedString("Report", comment: "")
                cell.colorTitleLabelTextColor = UIColor.yepTintColor()
                cell.colorTitleLabelFontStyle = .Light

                return cell

            case .Block:
                let cell = tableView.dequeueReusableCellWithIdentifier("ConversationMoreColorTitleCell") as! ConversationMoreColorTitleCell

                cell.colorTitleLabel.text = NSLocalizedString("Block", comment: "")
                cell.colorTitleLabelTextColor = UIColor.redColor()
                cell.colorTitleLabelFontStyle = .Light

                return cell

            case .Cancel:
                let cell = tableView.dequeueReusableCellWithIdentifier("ConversationMoreColorTitleCell") as! ConversationMoreColorTitleCell

                cell.colorTitleLabel.text = NSLocalizedString("Cancel", comment: "")
                cell.colorTitleLabelTextColor = UIColor.yepTintColor()
                cell.colorTitleLabelFontStyle = .Regular

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

            case .DoNotDisturb:
                break

            case .Report:
                reportAction?()

            case .Block:
                break
                
            case .Cancel:
                hide()

            default:
                break
            }
        }
    }
}


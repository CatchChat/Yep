//
//  DiscoverFilterView.swift
//  Yep
//
//  Created by NIX on 15/7/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class DiscoverFilterCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        //accessoryType = .DisclosureIndicator

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        textLabel?.textColor = UIColor.darkGrayColor()
        textLabel?.font = UIFont(name: "Helvetica-Light", size: 18)!
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var checkLabel: UILabel = {
        let s = UILabel()
        return s
        }()

    func makeUI() {
        contentView.addSubview(checkLabel)
        checkLabel.setTranslatesAutoresizingMaskIntoConstraints(false)

        let centerY = NSLayoutConstraint(item: checkLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: checkLabel, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1, constant: -20)

        NSLayoutConstraint.activateConstraints([centerY, trailing])
    }
}

class DiscoverFilterView: UIView {

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

        view.registerClass(DiscoverFilterCell.self, forCellReuseIdentifier: "DiscoverFilterCell")
        view.registerClass(ConversationMoreColorTitleCell.self, forCellReuseIdentifier: "ConversationMoreColorTitleCell")
        return view
        }()


    var tableViewBottomConstraint: NSLayoutConstraint?

    func showInView(view: UIView) {

        frame = view.bounds

        view.addSubview(self)

        layoutIfNeeded()

        containerView.alpha = 1

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

    func hideAndDo(afterHideAction: (() -> Void)?) {

        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveLinear, animations: { _ in
            self.containerView.alpha = 0

            self.tableViewBottomConstraint?.constant = 300

            self.layoutIfNeeded()

        }, completion: { finished in
            self.removeFromSuperview()
        })

        delay(0.1) {
            afterHideAction?()
        }
    }

    var isFirstTimeBeenAddAsSubview = true

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if isFirstTimeBeenAddAsSubview {
            isFirstTimeBeenAddAsSubview = false

            makeUI()

            let tap = UITapGestureRecognizer(target: self, action: "hide")
            containerView.addGestureRecognizer(tap)

            tap.cancelsTouchesInView = true
            tap.delegate = self
        }
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

// MARK: - UIGestureRecognizerDelegate

extension DiscoverFilterView: UIGestureRecognizerDelegate {

    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        if touch.view != containerView {
            return false
        }

        return true
    }
}

// MARK: - Actions
//
//extension ConversationMoreView {
//
//    func toggleDoNotDisturb() {
//        toggleDoNotDisturbAction?()
//    }
//}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension DiscoverFilterView: UITableViewDataSource, UITableViewDelegate {

    enum Row: Int {
        case Nearby = 0
        case Time
        case Default
        case Cancel
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if let row = Row(rawValue: indexPath.row) {
            switch row {

            case .Nearby:

                let cell = tableView.dequeueReusableCellWithIdentifier("DiscoverFilterCell") as! DiscoverFilterCell

                cell.textLabel?.text = NSLocalizedString("Nearby", comment: "")

                return cell

            case .Time:

                let cell = tableView.dequeueReusableCellWithIdentifier("DiscoverFilterCell") as! DiscoverFilterCell

                cell.textLabel?.text = NSLocalizedString("Time", comment: "")

                return cell

            case .Default:

                let cell = tableView.dequeueReusableCellWithIdentifier("DiscoverFilterCell") as! DiscoverFilterCell

                cell.textLabel?.text = NSLocalizedString("Default", comment: "")

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
                
            case .Nearby:
                hideAndDo { [weak self] in
                }
                
            case .Time:
                break
                
            case .Default:
                break

            case .Cancel:
                hide()
                
            default:
                break
            }
        }
    }
}


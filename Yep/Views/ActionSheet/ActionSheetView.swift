//
//  ActionSheetView.swift
//  Yep
//
//  Created by NIX on 16/3/2.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

// MARK: - ActionSheetDefaultCell

final private class ActionSheetDefaultCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var colorTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)
        return label
    }()

    var colorTitleLabelTextColor: UIColor = UIColor.yepTintColor() {
        willSet {
            colorTitleLabel.textColor = newValue
        }
    }

    func makeUI() {

        contentView.addSubview(colorTitleLabel)
        colorTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let centerY = NSLayoutConstraint(item: colorTitleLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        let centerX = NSLayoutConstraint(item: colorTitleLabel, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([centerY, centerX])
    }
}

// MARK: - ActionSheetDetailCell

final private class ActionSheetDetailCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        accessoryType = .disclosureIndicator

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        textLabel?.textColor = UIColor.darkGray

        textLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - ActionSheetSwitchCell

final private class ActionSheetSwitchCell: UITableViewCell {

    var action: ((Bool) -> Void)?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        textLabel?.textColor = UIColor.darkGray

        textLabel?.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var checkedSwitch: UISwitch = {
        let s = UISwitch()
        s.addTarget(self, action: #selector(ActionSheetSwitchCell.toggleSwitch(_:)), for: .valueChanged)
        return s
    }()

    @objc fileprivate func toggleSwitch(_ sender: UISwitch) {
        action?(sender.isOn)
    }

    func makeUI() {
        contentView.addSubview(checkedSwitch)
        checkedSwitch.translatesAutoresizingMaskIntoConstraints = false

        let centerY = NSLayoutConstraint(item: checkedSwitch, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: checkedSwitch, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -20)

        NSLayoutConstraint.activate([centerY, trailing])
    }
}

// MARK: - ActionSheetSubtitleSwitchCell

final private class ActionSheetSubtitleSwitchCell: UITableViewCell {

    var action: ((Bool) -> Void)?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: UIFontWeightLight)
        label.textColor = UIColor.lightGray
        return label
    }()

    lazy var checkedSwitch: UISwitch = {
        let s = UISwitch()
        s.addTarget(self, action: #selector(ActionSheetSwitchCell.toggleSwitch(_:)), for: .valueChanged)
        return s
    }()

    @objc fileprivate func toggleSwitch(_ sender: UISwitch) {
        action?(sender.isOn)
    }

    func makeUI() {
        contentView.addSubview(checkedSwitch)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkedSwitch.translatesAutoresizingMaskIntoConstraints = false

        let titleStackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])

        titleStackView.axis = .vertical
        titleStackView.distribution = .fill
        titleStackView.alignment = .fill
        titleStackView.spacing = 2
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleStackView)

        do {
            let centerY = NSLayoutConstraint(item: titleStackView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
            let leading = NSLayoutConstraint(item: titleStackView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1, constant: 20)

            NSLayoutConstraint.activate([centerY, leading])
        }

        do {
            let centerY = NSLayoutConstraint(item: checkedSwitch, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
            let trailing = NSLayoutConstraint(item: checkedSwitch, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -20)

            NSLayoutConstraint.activate([centerY, trailing])
        }

        let gap = NSLayoutConstraint(item: checkedSwitch, attribute: .leading, relatedBy: .equal, toItem: titleStackView, attribute: .trailing, multiplier: 1, constant: 10)

        NSLayoutConstraint.activate([gap])
    }
}

final private class ActionSheetCheckCell: UITableViewCell {

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        makeUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var colorTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightLight)
        return label
    }()

    lazy var checkImageView: UIImageView = {
        let image = UIImage.yep_iconLocationCheckmark
        let imageView = UIImageView(image: image)
        return imageView
    }()

    var colorTitleLabelTextColor: UIColor = UIColor.yepTintColor() {
        willSet {
            colorTitleLabel.textColor = newValue
        }
    }

    func makeUI() {

        contentView.addSubview(colorTitleLabel)
        contentView.addSubview(checkImageView)
        colorTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkImageView.translatesAutoresizingMaskIntoConstraints = false

        let centerY = NSLayoutConstraint(item: colorTitleLabel, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        let centerX = NSLayoutConstraint(item: colorTitleLabel, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([centerY, centerX])


        let checkImageViewCenterY = NSLayoutConstraint(item: checkImageView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1, constant: 0)
        let checkImageViewTrailing = NSLayoutConstraint(item: checkImageView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1, constant: -20)

        NSLayoutConstraint.activate([checkImageViewCenterY, checkImageViewTrailing])
    }
}

// MARK: - ActionSheetView

final class ActionSheetView: UIView {

    enum Item {
        case `default`(title: String, titleColor: UIColor, action: () -> Bool)
        case detail(title: String, titleColor: UIColor, action: () -> Void)
        case `switch`(title: String, titleColor: UIColor, switchOn: Bool, action: (_ switchOn: Bool) -> Void)
        case subtitleSwitch(title: String, titleColor: UIColor, subtitle: String, subtitleColor: UIColor, switchOn: Bool, action: (_ switchOn: Bool) -> Void)
        case check(title: String, titleColor: UIColor, checked: Bool, action: () -> Void)
        case cancel
    }

    var items: [Item]

    fileprivate let rowHeight: CGFloat = 60

    fileprivate var totalHeight: CGFloat {
        return CGFloat(items.count) * rowHeight
    }

    init(items: [Item]) {
        self.items = items

        super.init(frame: CGRect.zero)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    fileprivate lazy var tableView: UITableView = {
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = self.rowHeight
        view.isScrollEnabled = false

        view.registerClassOf(ActionSheetDefaultCell.self)
        view.registerClassOf(ActionSheetDetailCell.self)
        view.registerClassOf(ActionSheetSwitchCell.self)
        view.registerClassOf(ActionSheetSubtitleSwitchCell.self)
        view.registerClassOf(ActionSheetCheckCell.self)

        return view
    }()

    fileprivate var isFirstTimeBeenAddedAsSubview = true
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if isFirstTimeBeenAddedAsSubview {
            isFirstTimeBeenAddedAsSubview = false

            makeUI()

            let tap = UITapGestureRecognizer(target: self, action: #selector(ActionSheetView.hide))
            containerView.addGestureRecognizer(tap)

            tap.cancelsTouchesInView = true
            tap.delegate = self
        }
    }

    func refreshItems() {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

    fileprivate var tableViewBottomConstraint: NSLayoutConstraint?

    fileprivate func makeUI() {

        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "containerView": containerView,
            "tableView": tableView,
        ]

        // layout for containerView

        let containerViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[containerView]|", options: [], metrics: nil, views: views)
        let containerViewConstraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[containerView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(containerViewConstraintsH)
        NSLayoutConstraint.activate(containerViewConstraintsV)

        // layout for tableView

        let tableViewConstraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views)

        let tableViewBottomConstraint = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: containerView, attribute: .bottom, multiplier: 1.0, constant: self.totalHeight)

        self.tableViewBottomConstraint = tableViewBottomConstraint

        let tableViewHeightConstraint = NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: self.totalHeight)

        NSLayoutConstraint.activate(tableViewConstraintsH)
        NSLayoutConstraint.activate([tableViewBottomConstraint, tableViewHeightConstraint])
    }

    func showInView(_ view: UIView) {

        frame = view.bounds

        view.addSubview(self)

        layoutIfNeeded()

        containerView.alpha = 1

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: { [weak self] _ in
            self?.containerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        }, completion: nil)

        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: { [weak self] _ in
            self?.tableViewBottomConstraint?.constant = 0
            self?.layoutIfNeeded()
        }, completion: nil)
    }

    func hide() {

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.tableViewBottomConstraint?.constant = strongSelf.totalHeight
            strongSelf.layoutIfNeeded()
        }, completion: nil)

        UIView.animate(withDuration: 0.2, delay: 0.1, options: .curveEaseOut, animations: { [weak self] _ in
            self?.containerView.backgroundColor = UIColor.clear

        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }

    func hideAndDo(_ afterHideAction: (() -> Void)?) {

        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveLinear, animations: { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.containerView.alpha = 0

            strongSelf.tableViewBottomConstraint?.constant = strongSelf.totalHeight

            strongSelf.layoutIfNeeded()
            
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
        
        _ = delay(0.1) {
            afterHideAction?()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ActionSheetView: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        if touch.view != containerView {
            return false
        }

        return true
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension ActionSheetView: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = items[indexPath.row]

        switch item {

        case let .default(title, titleColor, _):

            let cell: ActionSheetDefaultCell = tableView.dequeueReusableCell()
            cell.colorTitleLabel.text = title
            cell.colorTitleLabelTextColor = titleColor

            return cell

        case let .detail(title, titleColor, _):

            let cell: ActionSheetDetailCell = tableView.dequeueReusableCell()
            cell.textLabel?.text = title
            cell.textLabel?.textColor = titleColor

            return cell

        case let .switch(title, titleColor, switchOn, action):

            let cell: ActionSheetSwitchCell = tableView.dequeueReusableCell()
            cell.textLabel?.text = title
            cell.textLabel?.textColor = titleColor
            cell.checkedSwitch.isOn = switchOn
            cell.action = action

            return cell

        case let .subtitleSwitch(title, titleColor, subtitle, subtitleColor, switchOn, action):

            let cell: ActionSheetSubtitleSwitchCell = tableView.dequeueReusableCell()
            cell.titleLabel.text = title
            cell.titleLabel.textColor = titleColor
            cell.subtitleLabel.text = subtitle
            cell.subtitleLabel.textColor = subtitleColor
            cell.checkedSwitch.isOn = switchOn
            cell.action = action

            return cell

        case let .check(title, titleColor, checked, _):

            let cell: ActionSheetCheckCell = tableView.dequeueReusableCell()
            cell.colorTitleLabel.text = title
            cell.colorTitleLabelTextColor = titleColor
            cell.checkImageView.isHidden = !checked

            return cell

        case .cancel:

            let cell: ActionSheetDefaultCell = tableView.dequeueReusableCell()
            cell.colorTitleLabel.text = String.trans_cancel
            cell.colorTitleLabelTextColor = UIColor.yepTintColor()

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let item = items[indexPath.row]

        switch item {

        case .default(_, _, let action):

            if action() {
                hide()
            }

        case .detail(_, _, let action):

            hideAndDo {
                action()
            }

        case .switch:

            break

        case .subtitleSwitch:
            
            break

        case .check(_, _, _, let action):

            action()
            hide()

        case .cancel:

            hide()
            break
        }
    }
}


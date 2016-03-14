//
//  PopoverView.swift
//  Yep
//
//  Created by ChaiYixiao on 3/14/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

// MARK: PopoverDefaultCell

private class PopoverDefaultCell: UITableViewCell {
    class var popoverReuseIdentifier: String {
        return "\(self)"
    }
    
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
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Light", size: 18)!
        }
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
        
        let centerY = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let centerX = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activateConstraints([centerY, centerX])
    }
}

// MARK: PopoverDetailCell

private class PopoverDetailCell: UITableViewCell {
    
    class var popoverReuseIdentifier: String {
        return "\(self)"
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .DisclosureIndicator
        
        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        textLabel?.textColor = UIColor.darkGrayColor()
        
        if #available(iOS 8.2, *) {
            textLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
        } else {
            textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)!
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: PopoverSwitchCell

private class PopoverSwitchCell: UITableViewCell {
    
    class var popoverReuseIdentifier: String {
        return "\(self)"
    }
    
    var action: (Bool -> Void)?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        textLabel?.textColor = UIColor.darkGrayColor()
        
        if #available(iOS 8.2, *) {
            textLabel?.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
        } else {
            textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)!
        }
        
        makeUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var checkedSwitch: UISwitch = {
        let s = UISwitch()
        s.addTarget(self, action: "toggleSwitch:", forControlEvents: .ValueChanged)
        return s
    }()
    
    @objc private func toggleSwitch(sender: UISwitch) {
        action?(sender.on)
    }
    
    func makeUI() {
        contentView.addSubview(checkedSwitch)
        checkedSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        let centerY = NSLayoutConstraint(item: checkedSwitch, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: checkedSwitch, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1, constant: -20)
        
        NSLayoutConstraint.activateConstraints([centerY, trailing])
    }
}

// MARK: PopoverCheckCell

private class PopoverCheckCell: UITableViewCell {
    
    class var popoverReuseIdentifier: String {
        return "\(self)"
//        return "PopoverCheckCell"
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        makeUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var colorTitleLabel: UILabel = {
        let label = UILabel()
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Light", size: 18)!
        }
        return label
    }()
    
    lazy var checkImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "icon_location_checkmark"))
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
        
        let centerY = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let centerX = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activateConstraints([centerY, centerX])
        
        
        let checkImageViewCenterY = NSLayoutConstraint(item: checkImageView, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let checkImageViewTrailing = NSLayoutConstraint(item: checkImageView, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1, constant: -20)
        
        NSLayoutConstraint.activateConstraints([checkImageViewCenterY, checkImageViewTrailing])
    }
}

class PopoverView: UIView {

    enum Item {
        case Default(title: String, titleColor: UIColor, action: () -> Bool)
        case Detail(title: String, titleColor: UIColor, action: () -> Void)
        case Switch(title: String, titleColor: UIColor, switchOn: Bool, action: (switchOn: Bool) -> Void)
        case Check(title: String, titleColor: UIColor, checked: Bool, action: () -> Void)
        case Cancel
    }
    
    var items: [Item]
    
    private let rowHeight: CGFloat = 60
    
    private var totalHeight: CGFloat {
        return CGFloat(items.count) * rowHeight
    }
    
    init(items: [Item]) {
        self.items = items
        
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let view = UITableView()
        view.dataSource = self
        view.delegate = self
        view.rowHeight = self.rowHeight
        view.scrollEnabled = false
        
        view.registerClass(PopoverDefaultCell.self, forCellReuseIdentifier: PopoverDefaultCell.popoverReuseIdentifier)
        view.registerClass(PopoverDetailCell.self, forCellReuseIdentifier: PopoverDetailCell.popoverReuseIdentifier)
        view.registerClass(PopoverSwitchCell.self, forCellReuseIdentifier: PopoverSwitchCell.popoverReuseIdentifier)
        view.registerClass(PopoverCheckCell.self, forCellReuseIdentifier: PopoverCheckCell.popoverReuseIdentifier)
        
        return view
    }()
    
    private var isFirstTimeBeenAddedAsSubview = true
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if isFirstTimeBeenAddedAsSubview {
            isFirstTimeBeenAddedAsSubview = false
            
            makeUI()
       }
    }
    
    func refreshItems() {
        dispatch_async(dispatch_get_main_queue()) { [weak self] in
            self?.tableView.reloadData()
        }
    }
    
    private func makeUI() {
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        let tableViewLeading = NSLayoutConstraint(item: tableView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: 0)
        let tableViewTop = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: self, attribute: .Top, multiplier: 1, constant: 0)
        NSLayoutConstraint.activateConstraints([tableViewLeading, tableViewTop])
//       TODO: Add Constraints

    }
    
    func showInView(view: UIView) {
        
        frame = view.bounds
        
        view.addSubview(self)
        
        layoutIfNeeded()
    }
    
    func hide(){
        
    }
    
    func delayAndDo(afterAction: (() -> Void)?) {
        
        delay(0.1) {
            afterAction?()
        }
    }
}

extension PopoverView: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = items[indexPath.row]
        
        switch item {
            
        case let .Default(title, titleColor, _):
            
            let cell = tableView.dequeueReusableCellWithIdentifier(PopoverDefaultCell.popoverReuseIdentifier) as! PopoverDefaultCell
            cell.colorTitleLabel.text = title
            cell.colorTitleLabelTextColor = titleColor
            
            return cell
            
        case let .Detail(title, titleColor, _):
            
            let cell = tableView.dequeueReusableCellWithIdentifier(PopoverDetailCell.popoverReuseIdentifier) as! PopoverDetailCell
            cell.textLabel?.text = title
            cell.textLabel?.textColor = titleColor
            
            return cell
            
        case let .Switch(title, titleColor, switchOn, action):
            
            let cell = tableView.dequeueReusableCellWithIdentifier(PopoverSwitchCell.popoverReuseIdentifier) as! PopoverSwitchCell
            cell.textLabel?.text = title
            cell.textLabel?.textColor = titleColor
            cell.checkedSwitch.on = switchOn
            cell.action = action
            
            return cell
            
        case let .Check(title, titleColor, checked, _):
            
            let cell = tableView.dequeueReusableCellWithIdentifier(PopoverCheckCell.popoverReuseIdentifier) as! PopoverCheckCell
            cell.colorTitleLabel.text = title
            cell.colorTitleLabelTextColor = titleColor
            cell.checkImageView.hidden = !checked
            
            return cell
            
        case .Cancel:
            
            let cell = tableView.dequeueReusableCellWithIdentifier(PopoverDefaultCell.popoverReuseIdentifier) as! PopoverDefaultCell
            cell.colorTitleLabel.text = NSLocalizedString("Cancel", comment: "")
            cell.colorTitleLabelTextColor = UIColor.yepTintColor()
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        let item = items[indexPath.row]
        
        switch item {
            
        case .Default(_, _, let action):
            
            if action() {
                hide()
            }
            
        case .Detail(_, _, let action):
            
             delayAndDo {
                action()
            }
            
        case .Switch:
            
            break
            
        case .Check(_, _, _, let action):
            
            action()
            hide()
            
        case .Cancel:
            
            hide()
            break
        }
    }
}
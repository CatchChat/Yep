//
//  ConversationMoreView.swift
//  Yep
//
//  Created by ChaiYixiao on 3/14/16.
//  Copyright © 2016 Catch Inc. All rights reserved.
//

import UIKit

/*
enum MoreViewType: Int {
    case OneToOne = 0
    case Topic
}

class ConversationMoreDetailCell: UITableViewCell {
    
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

class ConversationMoreCheckCell: UITableViewCell {
    
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
        return s
    }()
    
    func makeUI() {
        contentView.addSubview(checkedSwitch)
        checkedSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        let centerY = NSLayoutConstraint(item: checkedSwitch, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let trailing = NSLayoutConstraint(item: checkedSwitch, attribute: .Trailing, relatedBy: .Equal, toItem: contentView, attribute: .Trailing, multiplier: 1, constant: -20)
        
        NSLayoutConstraint.activateConstraints([centerY, trailing])
    }
    
    func updateWithNotificationEnabled(notificationEnabled: Bool) {
        checkedSwitch.on = !notificationEnabled
    }
}

class ConversationMoreColorTitleCell: UITableViewCell {
    
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
                if #available(iOS 8.2, *) {
                    colorTitleLabel.font = UIFont.systemFontOfSize(18, weight: UIFontWeightLight)
                } else {
                    colorTitleLabel.font = UIFont(name: "HelveticaNeue-Light", size: 18)!
                }
            case .Regular:
                colorTitleLabel.font = UIFont.systemFontOfSize(18)
            }
        }
    }
    
    func makeUI() {
        
        contentView.addSubview(colorTitleLabel)
        colorTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let centerY = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1, constant: 0)
        let centerX = NSLayoutConstraint(item: colorTitleLabel, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0)
        
        NSLayoutConstraint.activateConstraints([centerY, centerX])
    }
    
    func updateWithBlocked(blocked: Bool) {
        
        if blocked {
            colorTitleLabel.text = NSLocalizedString("Unblock", comment: "")
        } else {
            colorTitleLabel.text = NSLocalizedString("Block", comment: "")
        }
        
        colorTitleLabelTextColor = UIColor.redColor()
    }
}

class ConversationMoreView: UIView {
    
    var conversation: Conversation?
    
    let totalHeight: CGFloat = 60 * 5
    
    var type: MoreViewType = .OneToOne {
        didSet {
            tableView.reloadData()
        }
    }
    
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
    
    
    var notificationEnabled: Bool = true {
        didSet {
            
            if notificationEnabled != oldValue {
                switch type {
                case .OneToOne:
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        
                        if let strongSelf = self {
                            if let cell = strongSelf.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: Row.DoNotDisturb.rawValue, inSection: 0)) as? ConversationMoreCheckCell {
                                
                                cell.updateWithNotificationEnabled(strongSelf.notificationEnabled)
                            } else {
                                strongSelf.tableView.reloadData()
                            }
                        }
                    }
                case .Topic:
                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        
                        if let strongSelf = self {
                            if let cell = strongSelf.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: TopicRow.PushNotifications.rawValue, inSection: 0)) as? ConversationMoreCheckCell {
                                
                                cell.updateWithNotificationEnabled(!strongSelf.notificationEnabled)
                            } else {
                                strongSelf.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    var showProfileAction: (() -> Void)?
    var toggleDoNotDisturbAction: (() -> Void)?
    var reportAction: (() -> Void)?
    var toggleBlockAction: (() -> Void)?
    var shareAction: (() -> Void)?
    var updateGroupAffairAction: (() -> Void)?
    var unsubscribeAction: (() -> Void)?

    var afterGotSettingsForUserAction: ((userID: String, blocked: Bool, doNotDisturb: Bool) -> Void)?
    var afterGotSettingsForGroupAction: ((groupID: String, notificationEnabled: Bool) -> Void)?
    
    private var moreViewUpdatePushNotificationsAction: ((notificationEnabled: Bool) -> Void)?
    var blocked: Bool = true {
        didSet {
            if blocked != oldValue {
                dispatch_async(dispatch_get_main_queue()) { [weak self] in
                    
                    guard let strongSelf = self else {
                        return
                    }
                    
                    let cell = strongSelf.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: Row.Block.rawValue, inSection: 0)) as! ConversationMoreColorTitleCell
                    cell.updateWithBlocked(strongSelf.blocked)
                }
            }
        }
    }
    
    var hide: (() -> Void)?
    
    var tableViewBottomConstraint: NSLayoutConstraint?
    
    func showInView(view: UIView) {
        
        frame = view.bounds
        
        view.addSubview(self)
        
        layoutIfNeeded()
        
        containerView.alpha = 1
        
        self.tableView.separatorColor = UIColor.yepCellSeparatorColor()
        self.tableViewBottomConstraint?.constant = self.bottomConstraint()
        self.layoutIfNeeded()
    }
    
    func delayAndDo(afterHideAction: (() -> Void)?) {
        
        delay(0.1) {
            afterHideAction?()
        }
    }
    
    func bottomConstraint() -> CGFloat {
        switch type {
        case .OneToOne:
            return 0
        case .Topic:
            return 60
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
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorColor = UIColor.yepCellSeparatorColor()
        
        let viewsDictionary = [
            "containerView": containerView,
            "tableView": tableView,
        ]
        
        // layout for containerView
        
        let containerViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        NSLayoutConstraint.activateConstraints(containerViewConstraintsH)
        NSLayoutConstraint.activateConstraints(containerViewConstraintsV)
        
        // layout for tableView
        
        let tableViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: viewsDictionary)
        
        let tableViewBottomConstraint = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: containerView, attribute: .Bottom, multiplier: 1.0, constant: self.totalHeight)
        
        self.tableViewBottomConstraint = tableViewBottomConstraint
        
        let tableViewHeightConstraint = NSLayoutConstraint(item: tableView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: self.totalHeight)
        
        NSLayoutConstraint.activateConstraints(tableViewConstraintsH)
        NSLayoutConstraint.activateConstraints([tableViewBottomConstraint, tableViewHeightConstraint])
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ConversationMoreView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        
        if touch.view != containerView {
            return false
        }
        
        return true
    }
}

// MARK: - Actions

extension ConversationMoreView {
    
    func toggleDoNotDisturb() {
        toggleDoNotDisturbAction?() //TODO Topic Disturb
        hide?()
    }
}
*/
// MARK: - UITableViewDataSource, UITableViewDelegate


class ConversationMoreViewManager {
    
    var conversation: Conversation?
    
    var showProfileAction: (() -> Void)?
    var toggleDoNotDisturbAction: (() -> Void)?
    var reportAction: (() -> Void)?
    var toggleBlockAction: (() -> Void)?
    var shareFeedAction: (() -> Void)?
    var updateGroupAffairAction: (() -> Void)?
    var hide: (() -> Void)?
    
    var afterGotSettingsForUserAction: ((userID: String, blocked: Bool, doNotDisturb: Bool) -> Void)?
    var afterGotSettingsForGroupAction: ((groupID: String, notificationEnabled: Bool) -> Void)?
    
    private var moreViewUpdatePushNotificationsAction: ((notificationEnabled: Bool) -> Void)?
    
    var userNotificationEnabled: Bool = true {
        didSet {
            if moreViewCreated {
                moreView.items[1] = makeDoNotDisturbItem(notificationEnabled: userNotificationEnabled)
                moreView.refreshItems()
            }
        }
    }
    
    var userBlocked: Bool = false {
        didSet {
            if moreViewCreated {
                moreView.items[3] = makeBlockItem(blocked: userBlocked)
                moreView.refreshItems()
            }
        }
    }
    
    var groupNotificationEnabled: Bool = true {
        didSet {
            if moreViewCreated {
                moreView.items[0] = makePushNotificationsItem(notificationEnabled: groupNotificationEnabled)
                moreView.refreshItems()
            }
        }
    }
    
    private var moreViewCreated: Bool = false
    
    lazy var moreView: PopoverView = {
        
        let cancelItem = PopoverView.Item.Cancel
        
        let view: PopoverView
        
        if let user = self.conversation?.withFriend {
            
            view = PopoverView(items: [
                .Detail(
                    title: NSLocalizedString("View profile", comment: ""),
                    titleColor: UIColor.darkGrayColor(),
                    action: { [weak self] in
                        self?.showProfileAction?()
                    }
                ),
                self.makeDoNotDisturbItem(notificationEnabled: user.notificationEnabled), // 1
                .Default(
                    title: NSLocalizedString("Report", comment: ""),
                    titleColor: UIColor.yepTintColor(),
                    action: { [weak self] in
                        self?.reportAction?()
                        return true
                    }
                ),
                self.makeBlockItem(blocked: user.blocked), // 3
                cancelItem,
                ]
            )
            
            do {
                let userID = user.userID
                
                settingsForUser(userID: userID, failureHandler: nil, completion: { [weak self] blocked, doNotDisturb in
                    self?.afterGotSettingsForUserAction?(userID: userID, blocked: blocked, doNotDisturb: doNotDisturb)
                    })
            }
            
        } else if let group = self.conversation?.withGroup {
            
            view = PopoverView(items: [
                self.makePushNotificationsItem(notificationEnabled: group.notificationEnabled), // 0
                .Default(
                    title: NSLocalizedString("Share this feed", comment: ""),
                    titleColor: UIColor.yepTintColor(),
                    action: { [weak self] in
                        self?.shareFeedAction?()
                        return true
                    }
                ),
                self.updateGroupItem(group: group), // 2
                cancelItem,
                ]
            )
            
            do {
                self.moreViewUpdatePushNotificationsAction = { [weak self] notificationEnabled in
                    guard let strongSelf = self else { return }
                    strongSelf.moreView.items[0] = strongSelf.makePushNotificationsItem(notificationEnabled: notificationEnabled)
                    strongSelf.moreView.refreshItems()
                }
                
                let groupID = group.groupID
                
                settingsForGroup(groupID: groupID, failureHandler: nil, completion: { [weak self]  doNotDisturb in
                    self?.afterGotSettingsForGroupAction?(groupID: groupID, notificationEnabled: !doNotDisturb)
                    })
            }
            
        } else {
            view = PopoverView(items: [])
            println("lazy PopoverView: should NOT be there!")
        }
        
        self.moreViewCreated = true
        
        return view
    }()
    
    // MARK: Public
    
    func updateForGroupAffair() {
        if moreViewCreated, let group = self.conversation?.withGroup {
            moreView.items[2] = updateGroupItem(group: group)
            moreView.refreshItems()
        }
    }
    
    // MARK: Private
    
    private func makeDoNotDisturbItem(notificationEnabled notificationEnabled: Bool) -> PopoverView.Item {
        return .Switch(
            title: NSLocalizedString("Do not disturb", comment: ""),
            titleColor: UIColor.darkGrayColor(),
            switchOn: !notificationEnabled,
            action: { [weak self] switchOn in
                self?.toggleDoNotDisturbAction?()
            }
        )
    }
    
    private func makePushNotificationsItem(notificationEnabled notificationEnabled: Bool) -> PopoverView.Item {
        return .Switch(
            title: NSLocalizedString("Push notifications", comment: ""),
            titleColor: UIColor.darkGrayColor(),
            switchOn: notificationEnabled,
            action: { [weak self] switchOn in
                self?.toggleDoNotDisturbAction?()
            }
        )
    }
    
    private func makeBlockItem(blocked blocked: Bool) -> PopoverView.Item {
        return .Default(
            title: blocked ? NSLocalizedString("Unblock", comment: "") : NSLocalizedString("Block", comment: ""),
            titleColor: UIColor.redColor(),
            action: { [weak self] in
                self?.toggleBlockAction?()
                return false
            }
        )
    }
    
    private func updateGroupItem(group group: Group) -> PopoverView.Item {
        
        let isMyFeed = group.withFeed?.creator?.isMe ?? false
        let includeMe = group.includeMe
        
        let groupActionTitle: String
        if isMyFeed {
            groupActionTitle = NSLocalizedString("Delete", comment: "")
        } else {
            if includeMe {
                groupActionTitle = NSLocalizedString("Unsubscribe", comment: "")
            } else {
                groupActionTitle = NSLocalizedString("Subscribe", comment: "")
            }
        }
        
        return .Default(
            title: groupActionTitle,
            titleColor: UIColor.redColor(),
            action: { [weak self] in
                self?.updateGroupAffairAction?()
                return true
            }
        )
    }
}


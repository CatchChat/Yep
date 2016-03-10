//
//  ConversationMoreViewManager.swift
//  Yep
//
//  Created by NIX on 16/3/8.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation

class ConversationMoreViewManager {

    var conversation: Conversation?

    var showProfileAction: (() -> Void)?
    var toggleDoNotDisturbAction: (() -> Void)?
    var reportAction: (() -> Void)?
    var toggleBlockAction: (() -> Void)?
    var shareFeedAction: (() -> Void)?
    var updateGroupAffairAction: (() -> Void)?

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

    lazy var moreView: ActionSheetView = {

        let cancelItem = ActionSheetView.Item.Cancel

        let view: ActionSheetView

        if let user = self.conversation?.withFriend {

            view = ActionSheetView(items: [
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

            view = ActionSheetView(items: [
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
            view = ActionSheetView(items: [])
            println("lazy ActionSheetView: should NOT be there!")
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

    private func makeDoNotDisturbItem(notificationEnabled notificationEnabled: Bool) -> ActionSheetView.Item {
        return .Switch(
            title: NSLocalizedString("Do not disturb", comment: ""),
            titleColor: UIColor.darkGrayColor(),
            switchOn: !notificationEnabled,
            action: { [weak self] switchOn in
                self?.toggleDoNotDisturbAction?()
            }
        )
    }

    private func makePushNotificationsItem(notificationEnabled notificationEnabled: Bool) -> ActionSheetView.Item {
        return .Switch(
            title: NSLocalizedString("Push notifications", comment: ""),
            titleColor: UIColor.darkGrayColor(),
            switchOn: notificationEnabled,
            action: { [weak self] switchOn in
                self?.toggleDoNotDisturbAction?()
            }
        )
    }

    private func makeBlockItem(blocked blocked: Bool) -> ActionSheetView.Item {
        return .Default(
            title: blocked ? NSLocalizedString("Unblock", comment: "") : NSLocalizedString("Block", comment: ""),
            titleColor: UIColor.redColor(),
            action: { [weak self] in
                self?.toggleBlockAction?()
                return false
            }
        )
    }

    private func updateGroupItem(group group: Group) -> ActionSheetView.Item {

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


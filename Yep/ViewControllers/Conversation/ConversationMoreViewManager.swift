//
//  ConversationMoreViewManager.swift
//  Yep
//
//  Created by NIX on 16/3/8.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import YepKit

final class ConversationMoreViewManager {

    var conversation: Conversation?

    var showProfileAction: (() -> Void)?
    var toggleDoNotDisturbAction: (() -> Void)?
    var reportAction: (() -> Void)?
    var toggleBlockAction: (() -> Void)?
    var shareFeedAction: (() -> Void)?
    var updateGroupAffairAction: (() -> Void)?

    var afterGotSettingsForUserAction: ((_ userID: String, _ blocked: Bool, _ doNotDisturb: Bool) -> Void)?
    var afterGotSettingsForGroupAction: ((_ groupID: String, _ notificationEnabled: Bool) -> Void)?

    fileprivate var moreViewUpdatePushNotificationsAction: ((_ notificationEnabled: Bool) -> Void)?

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

    fileprivate var moreViewCreated: Bool = false

    lazy var moreView: ActionSheetView = {

        let reportItem = ActionSheetView.Item.default(
            title: NSLocalizedString("Report", comment: ""),
            titleColor: UIColor.yepTintColor(),
            action: { [weak self] in
                self?.reportAction?()
                return true
            }
        )

        let cancelItem = ActionSheetView.Item.cancel

        let view: ActionSheetView

        if let user = self.conversation?.withFriend {

            view = ActionSheetView(items: [
                .detail(
                    title: NSLocalizedString("View profile", comment: ""),
                    titleColor: UIColor.darkGray,
                    action: { [weak self] in
                        self?.showProfileAction?()
                    }
                ),
                self.makeDoNotDisturbItem(notificationEnabled: user.notificationEnabled), // 1
                reportItem,
                self.makeBlockItem(blocked: user.blocked), // 3
                cancelItem,
                ]
            )

            do {
                let userID = user.userID

                settingsForUser(userID: userID, failureHandler: nil, completion: { [weak self] blocked, doNotDisturb in
                    self?.afterGotSettingsForUserAction?(userID, blocked, doNotDisturb)
                })
            }

        } else if let group = self.conversation?.withGroup {

            view = ActionSheetView(items: [
                self.makePushNotificationsItem(notificationEnabled: group.notificationEnabled), // 0
                .default(
                    title: NSLocalizedString("Share this feed", comment: ""),
                    titleColor: UIColor.yepTintColor(),
                    action: { [weak self] in
                        self?.shareFeedAction?()
                        return true
                    }
                ),
                self.updateGroupItem(group: group), // 2
                reportItem,
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
                    self?.afterGotSettingsForGroupAction?(groupID, !doNotDisturb)
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

    fileprivate func makeDoNotDisturbItem(notificationEnabled: Bool) -> ActionSheetView.Item {
        return .switch(
            title: String.trans_titleDoNotDisturb,
            titleColor: UIColor.darkGray,
            switchOn: !notificationEnabled,
            action: { [weak self] switchOn in
                self?.toggleDoNotDisturbAction?()
            }
        )
    }

    fileprivate func makePushNotificationsItem(notificationEnabled: Bool) -> ActionSheetView.Item {
        return .switch(
            title: NSLocalizedString("Push Notifications", comment: ""),
            titleColor: UIColor.darkGray,
            switchOn: notificationEnabled,
            action: { [weak self] switchOn in
                self?.toggleDoNotDisturbAction?()
            }
        )
    }

    fileprivate func makeBlockItem(blocked: Bool) -> ActionSheetView.Item {
        return .default(
            title: blocked ? NSLocalizedString("Unblock", comment: "") : String.trans_titleBlock,
            titleColor: UIColor.red,
            action: { [weak self] in
                self?.toggleBlockAction?()
                return false
            }
        )
    }

    fileprivate func updateGroupItem(group: Group) -> ActionSheetView.Item {

        let isMyFeed = group.withFeed?.creator?.isMe ?? false
        let includeMe = group.includeMe

        let groupActionTitle: String
        if isMyFeed {
            groupActionTitle = String.trans_titleDelete
        } else {
            if includeMe {
                groupActionTitle = NSLocalizedString("Unsubscribe", comment: "")
            } else {
                groupActionTitle = NSLocalizedString("Subscribe", comment: "")
            }
        }

        return .default(
            title: groupActionTitle,
            titleColor: UIColor.red,
            action: { [weak self] in
                self?.updateGroupAffairAction?()
                return true
            }
        )
    }
}


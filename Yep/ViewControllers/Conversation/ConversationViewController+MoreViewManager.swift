//
//  ConversationViewController+MoreViewManager.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import MonkeyKing

extension ConversationViewController {

    func makeConversationMoreViewManager() -> ConversationMoreViewManager {

        let manager = ConversationMoreViewManager()

        manager.conversation = self.conversation

        manager.showProfileAction = { [weak self] in
            self?.performSegueWithIdentifier("showProfile", sender: nil)
        }

        manager.toggleDoNotDisturbAction = { [weak self] in
            self?.toggleDoNotDisturb()
        }

        manager.reportAction = { [weak self] in
            self?.tryReport()
        }

        manager.toggleBlockAction = { [weak self] in
            self?.toggleBlock()
        }

        manager.shareFeedAction = { [weak self] in
            self?.shareFeed()
        }

        manager.updateGroupAffairAction = { [weak self, weak manager] in
            self?.tryUpdateGroupAffair(afterSubscribed: { [weak self] in
                guard let strongSelf = self else { return }
                manager?.updateForGroupAffair()

                if strongSelf.isSubscribeViewShowing {
                    strongSelf.subscribeView.hide()
                }
            })
        }

        manager.afterGotSettingsForUserAction = { [weak self] userID, blocked, doNotDisturb in
            self?.updateNotificationEnabled(!doNotDisturb, forUserWithUserID: userID)
            self?.updateBlocked(blocked, forUserWithUserID: userID)
        }

        manager.afterGotSettingsForGroupAction = { [weak self] groupID, notificationEnabled in
            self?.updateNotificationEnabled(notificationEnabled, forGroupWithGroupID: groupID)
        }
        
        return manager
    }

    private func toggleDoNotDisturb() {

        if let user = conversation.withFriend {

            let userID = user.userID

            if user.notificationEnabled {
                disableNotificationFromUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("disableNotificationFromUserWithUserID \(success)")
                })

                updateNotificationEnabled(false, forUserWithUserID: userID)

            } else {
                enableNotificationFromUserWithUserID(userID, failureHandler: nil, completion: {  success in
                    println("enableNotificationFromUserWithUserID \(success)")
                })

                updateNotificationEnabled(true, forUserWithUserID: userID)
            }

        } else if let group = conversation.withGroup {

            let groupID = group.groupID

            if group.notificationEnabled {

                disableNotificationFromCircleWithCircleID(groupID, failureHandler: nil, completion: { success in
                    println("disableNotificationFromUserWithUserID \(success)")
                })

                updateNotificationEnabled(false, forGroupWithGroupID: groupID)

            } else {
                enableNotificationFromCircleWithCircleID(groupID, failureHandler: nil, completion: {success in
                    println("enableNotificationFromCircleWithCircleID \(success)")
                    
                })
                
                updateNotificationEnabled(true, forGroupWithGroupID: groupID)
            }
        }
    }

    private func tryReport() {

        if let user = conversation.withFriend {
            let profileUser = ProfileUser.UserType(user)
            report(.User(profileUser))

        } else if let feed = self.conversation?.withGroup?.withFeed {
            report(.Feed(feedID: feed.feedID))
        }
    }

    private func toggleBlock() {

        if let user = conversation.withFriend {

            let userID = user.userID

            if user.blocked {
                unblockUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("unblockUserWithUserID \(success)")

                    self.updateBlocked(false, forUserWithUserID: userID)
                })

            } else {
                blockUserWithUserID(userID, failureHandler: nil, completion: { success in
                    println("blockUserWithUserID \(success)")

                    self.updateBlocked(true, forUserWithUserID: userID)

                    deleteSearchableItems(searchableItemType: .User, itemIDs: [userID])
                })
            }
        }
    }

    func shareFeed() {

        guard let
            description = conversation.withGroup?.withFeed?.body,
            groupID = conversation.withGroup?.groupID else {
                return
        }

        guard let groupShareURLString = self.groupShareURLString else {

            shareURLStringOfGroupWithGroupID(groupID, failureHandler: nil, completion: { [weak self] groupShareURLString in

                self?.groupShareURLString = groupShareURLString

                SafeDispatch.async { [weak self] in
                    self?.shareFeedWithDescripion(description, groupShareURLString: groupShareURLString)
                }
            })

            return
        }

        shareFeedWithDescripion(description, groupShareURLString: groupShareURLString)
    }

    private func shareFeedWithDescripion(description: String, groupShareURLString: String) {

        let info = MonkeyKing.Info(
            title: NSLocalizedString("Join Us", comment: ""),
            description: description,
            thumbnail: feedView?.mediaView.imageView1.image,
            media: .URL(NSURL(string: groupShareURLString)!)
        )

        let timeLineinfo = MonkeyKing.Info(
            title: "\(NSLocalizedString("Join Us", comment: "")) \(description)",
            description: description,
            thumbnail: feedView?.mediaView.imageView1.image,
            media: .URL(NSURL(string: groupShareURLString)!)
        )

        let sessionMessage = MonkeyKing.Message.WeChat(.Session(info: info))

        let weChatSessionActivity = WeChatActivity(
            type: .Session,
            message: sessionMessage,
            finish: { success in
                println("share Feed to WeChat Session success: \(success)")
            }
        )

        let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info: timeLineinfo))

        let weChatTimelineActivity = WeChatActivity(
            type: .Timeline,
            message: timelineMessage,
            finish: { success in
                println("share Feed to WeChat Timeline success: \(success)")
            }
        )

        let shareText = "\(description) \(groupShareURLString)\n\(NSLocalizedString("From Yep", comment: ""))"

        let activityViewController = UIActivityViewController(activityItems: [shareText], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])
        activityViewController.excludedActivityTypes = [UIActivityTypeMessage, UIActivityTypeMail]

        SafeDispatch.async { [weak self] in
            self?.presentViewController(activityViewController, animated: true, completion: nil)
        }
    }

    private func tryUpdateGroupAffair(afterSubscribed afterSubscribed: (() -> Void)? = nil) {

        guard let group = conversation.withGroup, feed = group.withFeed, feedCreator = feed.creator else {
            return
        }

        let feedID = feed.feedID

        func doDeleteConversation(afterLeaveGroup afterLeaveGroup: (() -> Void)? = nil) -> Void {

            SafeDispatch.async { [weak self] in

                self?.checkTypingStatusTimer?.invalidate()

                guard let conversation = self?.conversation, realm = conversation.realm else {
                    return
                }

                realm.beginWrite()

                deleteConversation(conversation, inRealm: realm, afterLeaveGroup: {
                    doInNextRunLoop {
                        afterLeaveGroup?()
                    }
                })

                let _ = try? realm.commitWrite()

                realm.refresh()

                NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedConversation, object: nil)

                deleteSearchableItems(searchableItemType: .Feed, itemIDs: [feedID])
            }
        }

        let isMyFeed = feedCreator.isMe
        // 若是创建者，再询问是否删除 Feed
        if isMyFeed {

            YepAlert.confirmOrCancel(title: NSLocalizedString("Delete", comment: ""), message: String.trans_promptAlsoDeleteThisFeed, confirmTitle: NSLocalizedString("Delete", comment: ""), cancelTitle: NSLocalizedString("Not now", comment: ""), inViewController: self, withConfirmAction: {

                doDeleteConversation(afterLeaveGroup: { [weak self] in
                    deleteFeedWithFeedID(feedID, failureHandler: nil, completion: {
                        println("deleted feed: \(feedID)")
                    })

                    self?.afterDeletedFeedAction?(feedID: feedID)

                    SafeDispatch.async { [weak self] in

                        NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.deletedFeed, object: feedID)

                        self?.navigationController?.popViewControllerAnimated(true)
                    }
                })

            }, cancelAction: { [weak self] in
                doDeleteConversation(afterLeaveGroup: {
                    SafeDispatch.async { [weak self] in
                        self?.navigationController?.popViewControllerAnimated(true)
                    }
                })
            })

        } else {
            let includeMe = group.includeMe
            // 不然考虑订阅或取消订阅
            if includeMe {
                doDeleteConversation(afterLeaveGroup: {
                    SafeDispatch.async { [weak self] in
                        self?.navigationController?.popViewControllerAnimated(true)
                    }
                })

            } else {
                let groupID = group.groupID
                joinGroup(groupID: groupID, failureHandler: nil, completion: { [weak self] in
                    println("subscribe OK")

                    self?.updateGroupToIncludeMe() {
                        afterSubscribed?()
                    }
                })
            }
        }
    }

    private func updateNotificationEnabled(enabled: Bool, forUserWithUserID userID: String) {

        guard let realm = try? Realm() else {
            return
        }

        if let user = userWithUserID(userID, inRealm: realm) {
            let _ = try? realm.write {
                user.notificationEnabled = enabled
            }

            moreViewManager.userNotificationEnabled = enabled
        }
    }

    private func updateNotificationEnabled(enabled: Bool, forGroupWithGroupID: String) {

        guard let realm = try? Realm() else {
            return
        }

        if let group = groupWithGroupID(forGroupWithGroupID, inRealm: realm) {
            let _ = try? realm.write {
                group.notificationEnabled = enabled
            }

            moreViewManager.groupNotificationEnabled = enabled
        }
    }

    func updateBlocked(blocked: Bool, forUserWithUserID userID: String, needUpdateUI: Bool = true) {

        guard let realm = try? Realm() else {
            return
        }

        if let user = userWithUserID(userID, inRealm: realm) {
            let _ = try? realm.write {
                user.blocked = blocked
            }

            if needUpdateUI {
                moreViewManager.userBlocked = blocked
            }
        }
    }
}


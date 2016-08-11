//
//  ConversationViewController+Feed.swift
//  Yep
//
//  Created by nixzhu on 15/11/9.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift

extension ConversationViewController {

    func prepareConversationForFeed(feed: DiscoveredFeed, inRealm realm: Realm) -> Conversation? {

        let groupID = feed.groupID
        var group = groupWithGroupID(groupID, inRealm: realm)

        if group == nil {

            let newGroup = Group()
            newGroup.groupID = groupID
            newGroup.includeMe = false

            realm.add(newGroup)

            group = newGroup
        }

        guard let feedGroup = group else {
            return nil
        }

        feedGroup.groupType = GroupType.Public.rawValue

        if feedGroup.conversation == nil {

            let newConversation = Conversation()

            newConversation.type = ConversationType.Group.rawValue
            newConversation.withGroup = feedGroup

            realm.add(newConversation)
        }

        guard let feedConversation = feedGroup.conversation else {
            return nil
        }

        if let group = group {
            saveFeedWithDiscoveredFeed(feed, group: group, inRealm: realm)
        }

        return feedConversation
    }
}


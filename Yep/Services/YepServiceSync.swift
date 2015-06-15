//
//  YepServiceSync.swift
//  Yep
//
//  Created by NIX on 15/3/20.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift


let YepNewMessagesReceivedNotification = "YepNewMessagesReceivedNotification"


func downloadAttachmentOfMessage(message: Message) {

    func updateAttachmentOfMessage(message: Message, withAttachmentFileName attachmentFileName: String, inRealm realm: Realm) {
        realm.write {
            message.localAttachmentName = attachmentFileName
            message.downloadState = MessageDownloadState.Downloaded.rawValue
        }
    }

    func updateThumbnailOfMessage(message: Message, withThumbnailFileName thumbnailFileName: String, inRealm realm: Realm) {
        realm.write {
            message.localThumbnailName = thumbnailFileName
        }
    }

    let messageID = message.messageID
    let attachmentURLString = message.attachmentURLString
    let mediaType = message.mediaType

    if !attachmentURLString.isEmpty && message.downloadState != MessageDownloadState.Downloaded.rawValue {
        if let url = NSURL(string: attachmentURLString) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let data = NSData(contentsOfURL: url)

                if let data = data {
                    let fileName = NSUUID().UUIDString

                    dispatch_async(dispatch_get_main_queue()) {
                        let realm = Realm()
                        
                        if let message = messageWithMessageID(messageID, inRealm: realm) {
                            
                            switch mediaType {
                                
                            case MessageMediaType.Image.rawValue:
                                if let fileURL = NSFileManager.saveMessageImageData(data, withName: fileName) {
                                    updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                }
                                
                            case MessageMediaType.Video.rawValue:
                                if let fileURL = NSFileManager.saveMessageVideoData(data, withName: fileName) {
                                    updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                }
                                
                            case MessageMediaType.Audio.rawValue:
                                if let fileURL = NSFileManager.saveMessageAudioData(data, withName: fileName) {
                                    updateAttachmentOfMessage(message, withAttachmentFileName: fileName, inRealm: realm)
                                }
                                
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    if mediaType == MessageMediaType.Video.rawValue {
        let thumbnailURLString = message.thumbnailURLString

        if !thumbnailURLString.isEmpty && message.localThumbnailName.isEmpty {
            
            if let url = NSURL(string: thumbnailURLString) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    
                    let data = NSData(contentsOfURL: url)

                    if let data = data {
                        let fileName = NSUUID().UUIDString

                        dispatch_async(dispatch_get_main_queue()) {

                            let realm = Realm()
                            
                            if let message = messageWithMessageID(messageID, inRealm: realm) {
                                if let fileURL = NSFileManager.saveMessageImageData(data, withName: fileName) {
                                    updateThumbnailOfMessage(message, withThumbnailFileName: fileName, inRealm: realm)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

}

func skillsFromUserSkillList(userSkillList: List<UserSkill>) -> [Skill] {

    var userSkills = [UserSkill]()

    for userSkill in userSkillList {
        userSkills.append(userSkill)
    }
    
    return userSkills.map({ userSkill -> Skill? in
        if let category = userSkill.category {
            let skillCategory = SkillCategory(id: category.skillCategoryID, name: category.name, localName: category.localName, skills: [])

            let skill = Skill(category: skillCategory, id: userSkill.skillID, name: userSkill.name, localName: userSkill.localName, coverURLString: userSkill.coverURLString)

            return skill
        }

        return nil

    }).filter({ $0 != nil }).map({ skill in skill! })
}

func userSkillsFromSkills(skills: [Skill], inRealm realm: Realm) -> [UserSkill] {

    return skills.map({ skill -> UserSkill? in

        let skillID = skill.id
        var userSkill = userSkillWithSkillID(skillID, inRealm: realm)

        if userSkill == nil {
            let newUserSkill = UserSkill()
            newUserSkill.skillID = skillID
            newUserSkill.name = skillID
            newUserSkill.localName = skill.localName

            if let coverURLString = skill.coverURLString {
                newUserSkill.coverURLString = coverURLString
            }

            realm.add(newUserSkill)

            userSkill = newUserSkill
        }

        if let userSkill = userSkill {
            if let skillCategory = skill.category, skillCategoryID = skill.category?.id {
                var userSkillCategory = userSkillCategoryWithSkillCategoryID(skillCategoryID, inRealm: realm)

                if userSkillCategory == nil {
                    let newUserSkillCategory = UserSkillCategory()
                    newUserSkillCategory.skillCategoryID = skillCategoryID
                    newUserSkillCategory.name = skillCategory.name
                    newUserSkillCategory.localName = skillCategory.localName

                    realm.add(newUserSkillCategory)

                    userSkillCategory = newUserSkillCategory
                }

                if let userSkillCategory = userSkillCategory {
                    userSkill.category = userSkillCategory
                }
            }
        }

        return userSkill

    }).filter({ $0 != nil }).map({ skill in skill! })
}

func userSocialAccountProvidersFromSocialAccountProviders(socialAccountProviders: [DiscoveredUser.SocialAccountProvider]) -> [UserSocialAccountProvider] {
    return socialAccountProviders.map({ _provider -> UserSocialAccountProvider in
        let provider = UserSocialAccountProvider()
        provider.name = _provider.name
        provider.enabled = _provider.enabled

        return provider
    })
}

func userSkillsFromSkillsData(skillsData: [JSONDictionary], inRealm realm: Realm) -> [UserSkill] {
    var userSkills = [UserSkill]()

    for skillInfo in skillsData {
        if
            let categoryData = skillInfo["category"] as? JSONDictionary,
            let skillID = skillInfo["id"] as? String,
            let skillName = skillInfo["name"] as? String,
            let skillLocalName = skillInfo["name_string"] as? String {

                var userSkill = userSkillWithSkillID(skillID, inRealm: realm)

                if userSkill == nil {
                    let newUserSkill = UserSkill()
                    newUserSkill.skillID = skillID
                    newUserSkill.name = skillID
                    newUserSkill.localName = skillLocalName

                    if let coverURLString = skillInfo["cover_url"] as? String {
                        newUserSkill.coverURLString = coverURLString
                    }

                    realm.add(newUserSkill)

                    userSkill = newUserSkill
                }

                if let userSkill = userSkill {

                    if let
                        skillCategoryID = categoryData["id"] as? String,
                        skillCategoryName = categoryData["name"] as? String,
                        skillCategoryLocalName = categoryData["name_string"] as? String {

                            var userSkillCategory = userSkillCategoryWithSkillCategoryID(skillCategoryID, inRealm: realm)

                            if userSkillCategory == nil {
                                let newUserSkillCategory = UserSkillCategory()
                                newUserSkillCategory.skillCategoryID = skillCategoryID
                                newUserSkillCategory.name = skillCategoryName
                                newUserSkillCategory.localName = skillCategoryLocalName

                                realm.add(newUserSkillCategory)

                                userSkillCategory = newUserSkillCategory
                            }

                            if let userSkillCategory = userSkillCategory {
                                userSkill.category = userSkillCategory
                            }
                    }

                    userSkills.append(userSkill)
                }
        }
    }

    return userSkills
}

func syncMyInfoAndDoFurtherAction(furtherAction: () -> Void) {

    userInfo(failureHandler: { (reason, errorMessage) in
        defaultFailureHandler(reason, errorMessage)

        furtherAction()

    }, completion: { friendInfo in

        //println("my userInfo: \(friendInfo)")

        furtherAction()

        if let myUserID = YepUserDefaults.userID.value {

            let realm = Realm()

            var me = userWithUserID(myUserID, inRealm: realm)

            if me == nil {
                let newUser = User()
                newUser.userID = myUserID

                newUser.friendState = UserFriendState.Me.rawValue

                if let createdUnixTime = friendInfo["created_at"] as? NSTimeInterval {
                    newUser.createdUnixTime = createdUnixTime
                }

                realm.beginWrite()
                realm.add(newUser)
                realm.commitWrite()

                me = newUser
            }

            if let user = me {
                realm.beginWrite()

                // 更新用户信息

                if let lastSignInUnixTime = friendInfo["last_sign_in_at"] as? NSTimeInterval {
                    user.lastSignInUnixTime = lastSignInUnixTime
                }

                if let nickname = friendInfo["nickname"] as? String {
                    user.nickname = nickname
                }

                if let introduction = friendInfo["introduction"] as? String {
                    user.introduction = introduction
                }

                if let avatarURLString = friendInfo["avatar_url"] as? String {
                    user.avatarURLString = avatarURLString
                }

                // 更新技能

                if let learningSkillsData = friendInfo["learning_skills"] as? [JSONDictionary] {
                    user.learningSkills.removeAll()
                    let userSkills = userSkillsFromSkillsData(learningSkillsData, inRealm: realm)
                    user.learningSkills.extend(userSkills)
                }

                if let masterSkillsData = friendInfo["master_skills"] as? [JSONDictionary] {
                    user.masterSkills.removeAll()
                    let userSkills = userSkillsFromSkillsData(masterSkillsData, inRealm: realm)
                    user.masterSkills.extend(userSkills)
                }

                // 更新 Social Account Provider

                user.socialAccountProviders.removeAll()

                if let providersInfo = friendInfo["providers"] as? [String: Bool] {
                    for (name, enabled) in providersInfo {
                        let provider = UserSocialAccountProvider()
                        provider.name = name
                        provider.enabled = enabled

                        user.socialAccountProviders.append(provider)
                    }
                }

                realm.commitWrite()


                // also save some infomation in YepUserDefaults

                if let introduction = friendInfo["introduction"] as? String {
                    YepUserDefaults.introduction.value = introduction
                }

                if let areaCode = friendInfo["phone_code"] as? String {
                    YepUserDefaults.areaCode.value = areaCode
                }

                if let mobile = friendInfo["mobile"] as? String {
                    YepUserDefaults.mobile.value = mobile
                }
            }
        }
    })
}

func syncFriendshipsAndDoFurtherAction(furtherAction: () -> Void) {
    friendships { allFriendships in
        //println("\n allFriendships: \(allFriendships)")

        // 先整理出所有的 friend 的 userID
        var remoteUerIDSet = Set<String>()
        for friendshipInfo in allFriendships {
            if let friendInfo = friendshipInfo["friend"] as? JSONDictionary {
                if let userID = friendInfo["id"] as? String {
                    remoteUerIDSet.insert(userID)
                }
            }
        }

        dispatch_async(realmQueue) {

            // 改变没有 friendship 的 user 的状态

            let realm = Realm()

            let localUsers = realm.objects(User)

            for i in 0..<localUsers.count {
                let localUser = localUsers[i]

                if !remoteUerIDSet.contains(localUser.userID) {

                    realm.beginWrite()

                    localUser.friendshipID = ""

                    if let myUserID = YepUserDefaults.userID.value {
                        if myUserID == localUser.userID {
                            localUser.friendState = UserFriendState.Me.rawValue

                        } else if localUser.friendState == UserFriendState.Normal.rawValue {
                            localUser.friendState = UserFriendState.Stranger.rawValue
                        }
                    }

                    localUser.isBestfriend = false

                    realm.commitWrite()
                }
            }

            // 添加有 friendship 但本地存储还没有的 user，更新信息

            for friendshipInfo in allFriendships {
                if let friendInfo = friendshipInfo["friend"] as? JSONDictionary {
                    if let userID = friendInfo["id"] as? String {
                        var user = userWithUserID(userID, inRealm: realm)

                        if user == nil {
                            let newUser = User()
                            newUser.userID = userID

                            if let createdUnixTime = friendInfo["created_at"] as? NSTimeInterval {
                                newUser.createdUnixTime = createdUnixTime
                            }

                            realm.beginWrite()
                            realm.add(newUser)
                            realm.commitWrite()

                            user = newUser
                        }

                        if let user = user {
                            realm.beginWrite()

                            // 更新用户信息

                            if let lastSignInUnixTime = friendInfo["last_sign_in_at"] as? NSTimeInterval {
                                user.lastSignInUnixTime = lastSignInUnixTime
                            }

                            if let nickname = friendInfo["nickname"] as? String {
                                user.nickname = nickname
                            }

                            if let introduction = friendInfo["introduction"] as? String {
                                user.introduction = introduction
                            }

                            if let avatarURLString = friendInfo["avatar_url"] as? String {
                                user.avatarURLString = avatarURLString
                            }

                            if let friendshipID = friendshipInfo["id"] as? String {
                                user.friendshipID = friendshipID
                            }

                            user.friendState = UserFriendState.Normal.rawValue

                            if let isBestfriend = friendInfo["favored"] as? Bool {
                                user.isBestfriend = isBestfriend
                            }
                            
                            if let bestfriendIndex = friendInfo["favored_position"] as? Int {
                                user.bestfriendIndex = bestfriendIndex
                            }


                            // 更新技能

                            if let learningSkillsData = friendInfo["learning_skills"] as? [JSONDictionary] {
                                user.learningSkills.removeAll()
                                let userSkills = userSkillsFromSkillsData(learningSkillsData, inRealm: realm)
                                user.learningSkills.extend(userSkills)
                            }

                            if let masterSkillsData = friendInfo["master_skills"] as? [JSONDictionary] {
                                user.masterSkills.removeAll()
                                let userSkills = userSkillsFromSkillsData(masterSkillsData, inRealm: realm)
                                user.masterSkills.extend(userSkills)
                            }

                            // 更新 Social Account Provider

                            user.socialAccountProviders.removeAll()

                            if let providersInfo = friendInfo["providers"] as? [String: Bool] {
                                for (name, enabled) in providersInfo {
                                    let provider = UserSocialAccountProvider()
                                    provider.name = name
                                    provider.enabled = enabled

                                    user.socialAccountProviders.append(provider)
                                }
                            }

                            realm.commitWrite()
                        }
                    }
                }
            }
            
            // do further action

            furtherAction()
        }
    }
}

func syncGroupsAndDoFurtherAction(furtherAction: () -> Void) {
    groups { allGroups in
        //println("allGroups: \(allGroups)")

        // 先整理出所有的 group 的 groupID
        var remoteGroupIDSet = Set<String>()
        for groupInfo in allGroups {
            if let groupID = groupInfo["id"] as? String {
                remoteGroupIDSet.insert(groupID)
            }
        }

        dispatch_async(realmQueue) {

            // 在本地去除远端没有的 Group

            let realm = Realm()

            let localGroups = realm.objects(Group)

            realm.beginWrite()

            var groupsToDelete = [Group]()
            for i in 0..<localGroups.count {
                let localGroup = localGroups[i]

                if !remoteGroupIDSet.contains(localGroup.groupID) {
                    groupsToDelete.append(localGroup)
                }
            }
            for group in groupsToDelete {
                realm.delete(group)
                // TODO: 级联删除关联的数据对象
            }

            realm.commitWrite()

            // 增加本地没有的 Group

            for groupInfo in allGroups {
                syncGroupWithGroupInfo(groupInfo, inRealm: realm)
            }
            
            // do further action
            
            furtherAction()
        }
    }
}

private func syncGroupWithGroupInfo(groupInfo: JSONDictionary, inRealm realm: Realm) {
    if let groupID = groupInfo["id"] as? String {
        var group = groupWithGroupID(groupID, inRealm: realm)

        if group == nil {
            let newGroup = Group()
            newGroup.groupID = groupID
            if let groupName = groupInfo["name"] as? String {
                newGroup.groupName = groupName
            }

            realm.beginWrite()
            realm.add(newGroup)
            realm.commitWrite()

            group = newGroup
        }

        if let group = group {

            if group.conversation == nil {
                let conversation = Conversation()
                conversation.type = ConversationType.Group.rawValue
                conversation.withGroup = group

                realm.beginWrite()
                realm.add(conversation)
                realm.commitWrite()
            }

            // Group Owner

            if let ownerInfo = groupInfo["owner"] as? JSONDictionary {
                if let ownerID = ownerInfo["id"] as? String {
                    var owner = userWithUserID(ownerID, inRealm: realm)

                    if owner == nil {
                        let newUser = User()

                        newUser.userID = ownerID

                        if let createdUnixTime = ownerInfo["created_at"] as? NSTimeInterval {
                            newUser.createdUnixTime = createdUnixTime
                        }

                        if let myUserID = YepUserDefaults.userID.value {
                            if myUserID == ownerID {
                                newUser.friendState = UserFriendState.Me.rawValue
                            } else {
                                newUser.friendState = UserFriendState.Stranger.rawValue
                            }
                        } else {
                            newUser.friendState = UserFriendState.Stranger.rawValue
                        }

                        realm.beginWrite()
                        realm.add(newUser)
                        realm.commitWrite()
                        
                        owner = newUser
                    }
                    
                    if let owner = owner {
                        realm.beginWrite()

                        // 更新个人信息

                        if let lastSignInUnixTime = ownerInfo["last_sign_in_at"] as? NSTimeInterval {
                            owner.lastSignInUnixTime = lastSignInUnixTime
                        }

                        if let nickname = ownerInfo["nickname"] as? String {
                            owner.nickname = nickname
                        }

                        if let introduction = ownerInfo["introduction"] as? String {
                            owner.introduction = introduction
                        }

                        if let avatarURLString = ownerInfo["avatar_url"] as? String {
                            owner.avatarURLString = avatarURLString
                        }

                        // 更新技能

                        if let learningSkillsData = ownerInfo["learning_skills"] as? [JSONDictionary] {
                            owner.learningSkills.removeAll()
                            let userSkills = userSkillsFromSkillsData(learningSkillsData, inRealm: realm)
                            owner.learningSkills.extend(userSkills)
                        }

                        if let masterSkillsData = ownerInfo["master_skills"] as? [JSONDictionary] {
                            owner.masterSkills.removeAll()
                            let userSkills = userSkillsFromSkillsData(masterSkillsData, inRealm: realm)
                            owner.masterSkills.extend(userSkills)
                        }

                        // 更新 Social Account Provider

                        owner.socialAccountProviders.removeAll()

                        if let providersInfo = ownerInfo["providers"] as? [String: Bool] {
                            for (name, enabled) in providersInfo {
                                let provider = UserSocialAccountProvider()
                                provider.name = name
                                provider.enabled = enabled

                                owner.socialAccountProviders.append(provider)
                            }
                        }

                        group.owner = owner

                        realm.commitWrite()
                    }
                }
            }

            // 同步 Group 的成员

            if let remoteMembers = groupInfo["members"] as? [JSONDictionary] {
                var memberIDSet = Set<String>()
                for memberInfo in remoteMembers {
                    if let memberID = memberInfo["id"] as? String {
                        memberIDSet.insert(memberID)
                    }
                }

                var localMembers = group.members

                // 去除远端没有的 member

                for (index, member) in enumerate(localMembers) {
                    let user = member
                    if !memberIDSet.contains(user.userID) {
                        localMembers.removeAtIndex(index)
                    }
                }

                // 加上本地没有的 member

                for memberInfo in remoteMembers {
                    if let memberID = memberInfo["id"] as? String {
                        var member = userWithUserID(memberID, inRealm: realm)

                        if member == nil {
                            let newMember = User()

                            newMember.userID = memberID

                            if let createdUnixTime = memberInfo["created_at"] as? NSTimeInterval {
                                newMember.createdUnixTime = createdUnixTime
                            }

                            if let myUserID = YepUserDefaults.userID.value {
                                if myUserID == memberID {
                                    newMember.friendState = UserFriendState.Me.rawValue
                                } else {
                                    newMember.friendState = UserFriendState.Stranger.rawValue
                                }
                            } else {
                                newMember.friendState = UserFriendState.Stranger.rawValue
                            }

                            realm.write {
                                realm.add(newMember)

                                localMembers.append(newMember)
                            }

                            member = newMember
                        }

                        if let member = member {

                            realm.beginWrite()

                            // 更新个人信息

                            if let lastSignInUnixTime = memberInfo["last_sign_in_at"] as? NSTimeInterval {
                                member.lastSignInUnixTime = lastSignInUnixTime
                            }

                            if let nickname = memberInfo["nickname"] as? String {
                                member.nickname = nickname
                            }

                            if let introduction = memberInfo["introduction"] as? String {
                                member.introduction = introduction
                            }

                            if let avatarURLString = memberInfo["avatar_url"] as? String {
                                member.avatarURLString = avatarURLString
                            }

                            // 更新技能

                            if let learningSkillsData = memberInfo["learning_skills"] as? [JSONDictionary] {
                                member.learningSkills.removeAll()
                                let userSkills = userSkillsFromSkillsData(learningSkillsData, inRealm: realm)
                                member.learningSkills.extend(userSkills)
                            }

                            if let masterSkillsData = memberInfo["master_skills"] as? [JSONDictionary] {
                                member.masterSkills.removeAll()
                                let userSkills = userSkillsFromSkillsData(masterSkillsData, inRealm: realm)
                                member.masterSkills.extend(userSkills)
                            }

                            // 更新 Social Account Provider

                            member.socialAccountProviders.removeAll()

                            if let providersInfo = memberInfo["providers"] as? [String: Bool] {
                                for (name, enabled) in providersInfo {
                                    let provider = UserSocialAccountProvider()
                                    provider.name = name
                                    provider.enabled = enabled

                                    member.socialAccountProviders.append(provider)
                                }
                            }

                            realm.commitWrite()
                        }
                    }
                }

                realm.beginWrite()
                group.members.removeAll()
                group.members.extend(localMembers)
                realm.commitWrite()
            }
        }
    }
}

func syncUnreadMessagesAndDoFurtherAction(furtherAction: (messageIDs: [String]) -> Void) {
    unreadMessages { allUnreadMessages in
        //println("\n allUnreadMessages: \(allUnreadMessages)")
        println("Got unread message \(allUnreadMessages.count)")
        
        dispatch_async(realmQueue) {

            let realm = Realm()

            var messageIDs = [String]()

            for messageInfo in allUnreadMessages {
                syncMessageWithMessageInfo(messageInfo, inRealm: realm) { _messageIDs in
                    messageIDs += _messageIDs
                }
            }

            // do futher action
            println("加个打印，希望能等到 Realm 在线程间同步好")
            furtherAction(messageIDs: messageIDs)
        }
    }
}

func syncMessagesReadStatus() {
    
    sentButUnreadMessages(failureHandler: { (reason, message) -> Void in
        
    }, completion: { messagesDictionary in
      
        if let messageIDs = messagesDictionary["message_ids"] as? [String] {
            let realm = Realm()
            var messages = messagesUnreadSentByMe(inRealm: realm)
            
            var toMarkMessages = [Message]()
            
            if messageIDs.count < 1 {
                for oldMessage in messages {
                    if oldMessage.sendState == MessageSendState.Successed.rawValue {
                        toMarkMessages.append(oldMessage)
                    }
                }
            } else {
                for messageID in messageIDs {
                    let predicate = NSPredicate(format: "messageID != %@", argumentArray: [messageID])
                    messages = messages.filter(predicate)
                }
                
                for message in messages {
                    toMarkMessages.append(message)
                }
            }
            
            realm.write {
                for message in toMarkMessages {
                    message.sendState = MessageSendState.Read.rawValue
                    message.readed = true
                }
            }
            
            
        }
    })
}

func syncMessageWithMessageInfo(messageInfo: JSONDictionary, inRealm realm: Realm, andDoFurtherAction furtherAction: ((messageIDs: [String]) -> Void)? ) {

    func deleteMessage(message: Message, inRealm realm: Realm) {
        realm.beginWrite()
        realm.delete(message)
        realm.commitWrite()
    }

    if let messageID = messageInfo["id"] as? String {
        
        var message = messageWithMessageID(messageID, inRealm: realm)

        if message == nil {
            let newMessage = Message()
            newMessage.messageID = messageID

            if let updatedUnixTime = messageInfo["updated_at"] as? NSTimeInterval {
                newMessage.createdUnixTime = updatedUnixTime
            }

            // TODO: 可能可以根据是否已进入Conversation界面来修改到达时间，减少聊天界面的插入切换
            // 之后消息以到达时间排序

            realm.write {
                realm.add(newMessage)
            }

            message = newMessage
        }

        // 开始填充消息

        if let message = message {

            // 纪录消息的发送者

            if let senderInfo = messageInfo["sender"] as? JSONDictionary {
                if let senderID = senderInfo["id"] as? String {
                    var sender = userWithUserID(senderID, inRealm: realm)

                    if sender == nil {
                        let newUser = User()

                        newUser.userID = senderID

                        newUser.friendState = UserFriendState.Stranger.rawValue

                        realm.beginWrite()
                        realm.add(newUser)
                        realm.commitWrite()

                        sender = newUser
                    }

                    if let sender = sender {
                        realm.beginWrite()

                        if let nickname = senderInfo["nickname"] as? String {
                            sender.nickname = nickname
                        }

                        if let avatarURLString = senderInfo["avatar_url"] as? String {
                            sender.avatarURLString = avatarURLString
                        }

                        message.fromFriend = sender

                        realm.commitWrite()


                        // 查询消息来自的 Group，为空就表示来自 User

                        var sendFromGroup: Group? = nil

                        if let recipientType = messageInfo["recipient_type"] as? String {
                            if recipientType == "Circle" {
                                if let groupID = messageInfo["recipient_id"] as? String {
                                    sendFromGroup = groupWithGroupID(groupID, inRealm: realm)

                                    if sendFromGroup == nil {
                                        let newGroup = Group()
                                        newGroup.groupID = groupID

                                        if let groupInfo = messageInfo["circle"] as? JSONDictionary {
                                            if let groupName = groupInfo["name"] as? String {
                                                newGroup.groupName = groupName
                                            }
                                        }

                                        realm.beginWrite()
                                        realm.add(newGroup)
                                        realm.commitWrite()

                                        sendFromGroup = newGroup
                                    }
                                }
                            }
                        }

                        // 纪录消息所属的 Conversation

                        var conversation: Conversation? = nil

                        if let sendFromGroup = sendFromGroup {
                            conversation = sendFromGroup.conversation
                        } else {
                            conversation = sender.conversation
                        }

                        // 没有 Conversation 就尝试建立它

                        if conversation == nil {
                            let newConversation = Conversation()

                            if let sendFromGroup = sendFromGroup {
                                newConversation.type = ConversationType.Group.rawValue
                                newConversation.withGroup = sendFromGroup
                            } else {
                                newConversation.type = ConversationType.OneToOne.rawValue
                                newConversation.withFriend = sender
                            }

                            realm.beginWrite()
                            realm.add(newConversation)
                            realm.commitWrite()

                            conversation = newConversation
                        }

                        // 在保证有 Conversation 的情况下继续，不然消息没有必要保留
                        if let conversation = conversation {
                            realm.beginWrite()

                            conversation.updatedUnixTime = message.createdUnixTime

                            message.conversation = conversation

                            var sectionDateMessageID: String?
                            tryCreateSectionDateMessageInConversation(conversation, beforeMessage: message, inRealm: realm) { sectionDateMessage in
                                realm.add(sectionDateMessage)
                                sectionDateMessageID = sectionDateMessage.messageID
                            }

                            // 纪录消息的 detail 信息

                            if let textContent = messageInfo["text_content"] as? String {
                                message.textContent = textContent
                            }

                            if
                                let longitude = messageInfo["longitude"] as? Double,
                                let latitude = messageInfo["latitude"] as? Double {

                                    let newCoordinate = Coordinate()
                                    newCoordinate.longitude = longitude
                                    newCoordinate.latitude = latitude

                                    message.coordinate = newCoordinate
                            }

                            if let attachments = messageInfo["attachments"] as? [JSONDictionary] {
                                for attachmentInfo in attachments {

                                    // S3: normal file
                                    if let normalFileInfo = attachmentInfo["file"] as? JSONDictionary {
                                        if let fileURLString = normalFileInfo["url"] as? String {
                                            if let kind = attachmentInfo["kind"] as? String {
                                                if kind == "thumbnail" {
                                                    message.thumbnailURLString = fileURLString
                                                } else {
                                                    message.attachmentURLString = fileURLString
                                                }
                                            }
                                        }

                                        if let metaData = attachmentInfo["metadata"] as? String {
                                            message.metaData = metaData
                                        }
                                    }
                                    /*
                                    else if let fallbackFileInfo = attachmentInfo["fallback_file"] as? JSONDictionary {
                                        if let fileURLString = fallbackFileInfo["url"] as? String {
                                            if let kind = attachmentInfo["kind"] as? String {
                                                if kind == "thumbnail" {
                                                    message.thumbnailURLString = fileURLString
                                                } else {
                                                    message.attachmentURLString = fileURLString
                                                }
                                            }
                                        }
                                    }
                                    */
                                }

                                if let mediaType = messageInfo["media_type"] as? String {

                                    switch mediaType {
                                    case MessageMediaType.Text.description:
                                        message.mediaType = MessageMediaType.Text.rawValue
                                    case MessageMediaType.Image.description:
                                        message.mediaType = MessageMediaType.Image.rawValue
                                    case MessageMediaType.Video.description:
                                        message.mediaType = MessageMediaType.Video.rawValue
                                    case MessageMediaType.Audio.description:
                                        message.mediaType = MessageMediaType.Audio.rawValue
                                    case MessageMediaType.Sticker.description:
                                        message.mediaType = MessageMediaType.Sticker.rawValue
                                    case MessageMediaType.Location.description:
                                        message.mediaType = MessageMediaType.Location.rawValue
                                    default:
                                        break
                                    }
                                    // TODO: 若有更多的 Media Type
                                }
                            }

                            realm.commitWrite()


                            // Do furtherAction after sync

                            //println("syncMessageWithMessageInfo do furtherAction")
                            if let sectionDateMessageID = sectionDateMessageID{
                                furtherAction?(messageIDs: [sectionDateMessageID, messageID])
                            } else {
                                furtherAction?(messageIDs: [messageID])
                            }

                        } else {
                            deleteMessage(message, inRealm: realm)
                        }
                    }
                }
            }
        }
    }
}


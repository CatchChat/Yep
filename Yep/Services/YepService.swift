//
//  YepService.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import Realm

let baseURL = NSURL(string: "http://park.catchchatchina.com")!

// Models

struct LoginUser: Printable {
    let accessToken: String
    let userID: String
    let nickname: String
    let avatarURLString: String?
    let pusherID: String

    var description: String {
        return "LoginUser(accessToken: \(accessToken), userID: \(userID), nickname: \(nickname), avatarURLString: \(avatarURLString), \(pusherID))"
    }
}

struct QiniuProvider: Printable {
    let token: String
    let key: String
    let downloadURLString: String

    var description: String {
        return "QiniuProvider(token: \(token), key: \(key), downloadURLString: \(downloadURLString))"
    }
}

func saveTokenAndUserInfoOfLoginUser(loginUser: LoginUser) {
    YepUserDefaults.setUserID(loginUser.userID)
    YepUserDefaults.setNickname(loginUser.nickname)
    if let avatarURLString = loginUser.avatarURLString {
        YepUserDefaults.setAvatarURLString(avatarURLString)
    }
    YepUserDefaults.setPusherID(loginUser.pusherID)

    // NOTICE: 因为一些操作依赖于 accessToken 做检测，又可能依赖上面其他值，所以要放在最后赋值
    YepUserDefaults.setV1AccessToken(loginUser.accessToken)
}

// MARK: Register

func validateMobile(mobile: String, withAreaCode areaCode: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: ((Bool, String)) -> Void) {
    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
    ]

    let parse: JSONDictionary -> (Bool, String)? = { data in
        println("data: \(data)")
        if let available = data["available"] as? Bool {
            if available {
                return (available, "")
            } else {
                if let message = data["message"] as? String {
                    return (available, message)
                }
            }
        }
        
        return (false, "")
    }

    let resource = jsonResource(path: "/api/v1/users/mobile_validate", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }

}

func registerMobile(mobile: String, withAreaCode areaCode: String, #nickname: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {
    let requestParameters: JSONDictionary = [
        "mobile": mobile,
        "phone_code": areaCode,
        "nickname": nickname,
        "longitude": 0, // TODO: 注册时不好提示用户访问位置，或许设置技能或用户利用位置查找好友时再提示并更新位置信息
        "latitude": 0
    ]

    let parse: JSONDictionary -> Bool? = { data in
        if let state = data["state"] as? String {
            if state == "blocked" {
                return true
            }
        }

        return false
    }

    let resource = jsonResource(path: "/api/v1/registration/create", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func verifyMobile(mobile: String, withAreaCode areaCode: String, #verifyCode: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: LoginUser -> Void) {
    let requestParameters: JSONDictionary = [
        "mobile": mobile,
        "phone_code": areaCode,
        "token": verifyCode,
        "client": YepConfig.clientType(),
        "expiring": 0, // 永不过期
    ]

    let parse: JSONDictionary -> LoginUser? = { data in

        if let accessToken = data["access_token"] as? String {
            if let user = data["user"] as? [String: AnyObject] {
                if
                    let userID = user["id"] as? String,
                    let nickname = user["nickname"] as? String,
                    let pusherID = user["pusher_id"] as? String {
                        let avatarURLString = user["avatar_url"] as? String
                        return LoginUser(accessToken: accessToken, userID: userID, nickname: nickname, avatarURLString: avatarURLString, pusherID: pusherID)
                }
            }
        }

        return nil
    }

    let resource = jsonResource(path: "/api/v1/registration/update", method: .PUT, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

// MARK: User

func updateMyselfWithInfo(info: JSONDictionary, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {

    // nickname
    // avatar_url
    // username
    // latitude
    // longitude

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/api/v1/user", method: .PATCH, requestParameters: info, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func sendVerifyCode(ofMobile mobile: String, withAreaCode areaCode: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {

    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        if let status = data["status"] as? String {
            if status == "sms sent" {
                return true
            }
        }

        return false
    }

    let resource = jsonResource(path: "/api/v1/auth/send_verify_code", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func resendVoiceVerifyCode(ofMobile mobile: String, withAreaCode areaCode: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {
    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        if let status = data["state"] as? String {
            return true
        }

        return false
    }

    let resource = jsonResource(path: "/api/v1/registration/resend_verify_code_by_voice", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }

}

func loginByMobile(mobile: String, withAreaCode areaCode: String, #verifyCode: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: LoginUser -> Void) {

    let requestParameters: JSONDictionary = [
        "mobile": mobile,
        "phone_code": areaCode,
        "verify_code": verifyCode,
        "client": YepConfig.clientType(),
        "expiring": 0, // 永不过期
    ]

    let parse: JSONDictionary -> LoginUser? = { data in

        if let accessToken = data["access_token"] as? String {
            if let user = data["user"] as? [String: AnyObject] {
                if
                    let userID = user["id"] as? String,
                    let nickname = user["nickname"] as? String,
                    let pusherID = user["pusher_id"] as? String {
                        let avatarURLString = user["avatar_url"] as? String
                        return LoginUser(accessToken: accessToken, userID: userID, nickname: nickname, avatarURLString: avatarURLString, pusherID: pusherID)
                }
            }
        }
        
        return nil
    }

    let resource = jsonResource(path: "/api/v1/auth/token_by_mobile", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

// MARK: Contacts

func searchUsersByMobile(mobile: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: [JSONDictionary] -> Void) {
    
    let requestParameters = [
        "q": mobile
    ]
    
    let parse: JSONDictionary -> [JSONDictionary]? = { data in
        if let users = data["users"] as? [JSONDictionary] {
            return users
        }
        return []
    }
    
    let resource = authJsonResource(path: "/api/v1/users/search", method: .GET, requestParameters: requestParameters, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

// MARK: Friendships

private func headFriendships(#completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/friendships", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
}

private func moreFriendships(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/friendships", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func discoverUsers(#master_skills: [String], #learning_skills: [String], #sort: String,#failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {
    
    let requestParameters = [
        "master_skills": master_skills,
        "learning_skills": learning_skills,
        "sort": sort
    ]
    
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/api/v1/user/discover", method: .GET, requestParameters: requestParameters as! JSONDictionary, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func friendships(#completion: [JSONDictionary] -> Void) {

    headFriendships { result in
        if
            let count = result["count"] as? Int,
            let currentPage = result["current_page"] as? Int,
            let perPage = result["per_page"] as? Int {
                if count <= currentPage * perPage {
                    if let friendships = result["friendships"] as? [JSONDictionary] {
                        completion(friendships)
                    } else {
                        completion([])
                    }

                } else {
                    var friendships = [JSONDictionary]()

                    if let page1Friendships = result["friendships"] as? [JSONDictionary] {
                        friendships += page1Friendships
                    }

                    // We have more friends

                    let downloadGroup = dispatch_group_create()

                    for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                        dispatch_group_enter(downloadGroup)

                        moreFriendships(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                            dispatch_group_leave(downloadGroup)
                        }, completion: { result in
                            if let currentPageFriendships = result["friendships"] as? [JSONDictionary] {
                                friendships += currentPageFriendships
                            }
                            dispatch_group_leave(downloadGroup)
                        })
                    }

                    dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                        completion(friendships)
                    }
                }
        }
    }
}

// MARK: Groups

func headGroups(#failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/circles", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func moreGroups(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/circles", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func groups(#completion: [JSONDictionary] -> Void) {
    return headGroups(failureHandler: nil, completion: { result in
        if
            let count = result["count"] as? Int,
            let currentPage = result["current_page"] as? Int,
            let perPage = result["per_page"] as? Int {
                if count <= currentPage * perPage {
                    if let groups = result["circles"] as? [JSONDictionary] {
                        completion(groups)
                    } else {
                        completion([])
                    }

                } else {
                    var groups = [JSONDictionary]()

                    if let page1Groups = result["circles"] as? [JSONDictionary] {
                        groups += page1Groups
                    }

                    // We have more groups

                    let downloadGroup = dispatch_group_create()

                    for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                        dispatch_group_enter(downloadGroup)

                        moreGroups(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                            dispatch_group_leave(downloadGroup)

                        }, completion: { result in
                            if let currentPageGroups = result["circles"] as? [JSONDictionary] {
                                groups += currentPageGroups
                            }
                            dispatch_group_leave(downloadGroup)
                        })
                    }

                    dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                        completion(groups)
                    }

                }
        }
    })
}

// MARK: Messages

func headUnreadMessages(#completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/messages/unread", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
}

func moreUnreadMessages(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/api/v1/messages/unread", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func unreadMessages(#completion: [JSONDictionary] -> Void) {
    headUnreadMessages { result in
        if
            let count = result["count"] as? Int,
            let currentPage = result["current_page"] as? Int,
            let perPage = result["per_page"] as? Int {
                if count <= currentPage * perPage {
                    if let messages = result["messages"] as? [JSONDictionary] {
                        completion(messages)
                    } else {
                        completion([])
                    }

                } else {
                    var messages = [JSONDictionary]()

                    if let page1Messages = result["messages"] as? [JSONDictionary] {
                        messages += page1Messages
                    }

                    // We have more messages

                    let downloadGroup = dispatch_group_create()

                    for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                        dispatch_group_enter(downloadGroup)

                        moreUnreadMessages(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                            dispatch_group_leave(downloadGroup)
                            }, completion: { result in
                                if let currentPageMessages = result["messages"] as? [JSONDictionary] {
                                    messages += currentPageMessages
                                }
                                dispatch_group_leave(downloadGroup)
                        })
                    }

                    dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                        completion(messages)
                    }
                }
        }
    }
}

func createMessageWithMessageInfo(messageInfo: JSONDictionary, #failureHandler: ((Reason, String?) -> Void)?, #completion: (messageID: String) -> Void) {

    let parse: JSONDictionary -> String? = { data in
        if let messageID = data["id"] as? String {
            return messageID
        }
        return nil
    }

    let resource = authJsonResource(path: "/api/v1/messages", method: .POST, requestParameters: messageInfo, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func sendText(text: String, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    sendMessageWithMediaType(.Text, inFilePath: nil, orFileData: nil, metaData: nil, text: text, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendImageInFilePath(filePath: String?, orFileData fileData: NSData?, #metaData: String?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    sendMessageWithMediaType(.Image, inFilePath: filePath, orFileData: fileData, metaData: metaData, text: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendAudioInFilePath(filePath: String?, orFileData fileData: NSData?, #metaData: String?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    sendMessageWithMediaType(.Audio, inFilePath: filePath, orFileData: fileData, metaData: metaData, text: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendMessageWithMediaType(mediaType: MessageMediaType, inFilePath filePath: String?, orFileData fileData: NSData?, #metaData: String?, #text: String?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {
    // 因为 message_id 必须来自远端，线程无法切换，所以这里暂时没用 realmQueue // TOOD: 也许有办法

    let realm = RLMRealm.defaultRealm()

    realm.beginWriteTransaction()

    let message = Message()
    //message.messageID = messageID

    message.mediaType = mediaType.rawValue

    if let text = text {
        message.textContent = text
    }

    realm.addObject(message)

    realm.commitWriteTransaction()


    // 消息来自于自己

    if let me = tryGetOrCreateMe() {
        realm.beginWriteTransaction()
        message.fromFriend = me
        realm.commitWriteTransaction()
    }

    // 消息的 Conversation，没有就创建

    var conversation: Conversation? = nil

    realm.beginWriteTransaction()

    if recipientType == "User" {
        if let withFriend = userWithUserID(recipientID) {
            conversation = withFriend.conversation
        }

    } else {
        if let withGroup = groupWithGroupID(recipientID) {
            conversation = withGroup.conversation
        }
    }

    if conversation == nil {
        let newConversation = Conversation()

        if recipientType == "User" {
            newConversation.type = ConversationType.OneToOne.rawValue

            if let withFriend = userWithUserID(recipientID) {
                newConversation.withFriend = withFriend
            }


        } else {
            newConversation.type = ConversationType.Group.rawValue

            if let withGroup = groupWithGroupID(recipientID) {
                newConversation.withGroup = withGroup
            }
        }

        conversation = newConversation
    }

    if let conversation = conversation {
        conversation.updatedAt = message.createdAt // 关键哦
        message.conversation = conversation
    }

    realm.commitWriteTransaction()


    // 发出之前就显示 Message
    afterCreatedMessage(message)


    // 下面开始真正的消息发送

    var messageInfo: JSONDictionary = [
        "recipient_id": recipientID,
        "recipient_type": recipientType,
        "media_type": mediaType.description,
    ]

    if mediaType == MessageMediaType.Text {

        messageInfo["text_content"] = text

        createMessageWithMessageInfo(messageInfo, failureHandler: { (reason, errorMessage) in
            if let failureHandler = failureHandler {
                failureHandler(reason, errorMessage)
            }

            dispatch_async(dispatch_get_main_queue()) {
                realm.beginWriteTransaction()
                message.sendState = MessageSendState.Failed.rawValue
                realm.commitWriteTransaction()
            }

        }, completion: { messageID in
            dispatch_async(dispatch_get_main_queue()) {
                realm.beginWriteTransaction()
                message.messageID = messageID
                message.sendState = MessageSendState.Successed.rawValue
                realm.commitWriteTransaction()
            }

            completion(success: true)
        })

    } else {

        // TODO: mimetype
        var mimeType = ""

        switch mediaType {
        case .Image:
            mimeType = "image/jpeg"
        case .Video:
            mimeType = "video/mp4"
        case .Audio:
            mimeType = "audio/m4a"
        default:
            break 
        }

        s3PrivateUploadParams(failureHandler: nil) { s3UploadParams in
            uploadFileToS3(inFilePath: filePath, orFileData: fileData, mimeType: mimeType, s3UploadParams: s3UploadParams) { (result, error) in

                // TODO: attachments
                switch mediaType {
                case .Image:
                    if let metaData = metaData {
                        let attachments = ["image": [["file": s3UploadParams.key, "metadata": metaData]]]
                        messageInfo["attachments"] = attachments

                    } else {
                        let attachments = ["image": [["file": s3UploadParams.key]]]
                        messageInfo["attachments"] = attachments
                    }

                case .Video:
                    if let metaData = metaData {
                        let attachments = ["video": [["file": s3UploadParams.key, "metadata": metaData]]]
                        messageInfo["attachments"] = attachments

                    } else {
                        let attachments = ["video": [["file": s3UploadParams.key]]]
                        messageInfo["attachments"] = attachments
                    }

                case .Audio:
                    if let metaData = metaData {
                        let attachments = ["audio": [["file": s3UploadParams.key, "metadata": metaData]]]
                        messageInfo["attachments"] = attachments

                    } else {
                        let attachments = ["audio": [["file": s3UploadParams.key]]]
                        messageInfo["attachments"] = attachments
                    }

                default:
                    break
                }

                createMessageWithMessageInfo(messageInfo, failureHandler: { (reason, errorMessage) in
                    if let failureHandler = failureHandler {
                        failureHandler(reason, errorMessage)
                    }

                    dispatch_async(dispatch_get_main_queue()) {
                        realm.beginWriteTransaction()
                        message.sendState = MessageSendState.Failed.rawValue
                        realm.commitWriteTransaction()
                    }

                }, completion: { messageID in
                    dispatch_async(dispatch_get_main_queue()) {
                        realm.beginWriteTransaction()
                        message.messageID = messageID
                        message.sendState = MessageSendState.Successed.rawValue
                        realm.commitWriteTransaction()
                    }

                    completion(success: true)
                })

            }
        }
    }
}

func markAsReadMessage(message: Message ,#failureHandler: ((Reason, String?) -> Void)?, #completion: (Bool) -> Void) {

    if message.readed || message.messageID.isEmpty || message.downloadState != MessageDownloadState.Downloaded.rawValue {
        return
    }

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/api/v1/messages/\(message.messageID)/mark_as_read", method: .PATCH, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

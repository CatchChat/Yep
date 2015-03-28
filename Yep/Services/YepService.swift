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

func validateMobile(mobile: String, withAreaCode areaCode: String, #failureHandler: ((Reason, String?) -> ())?, #completion: ((Bool, String)) -> Void) {
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

func registerMobile(mobile: String, withAreaCode areaCode: String, #nickname: String, #failureHandler: ((Reason, String?) -> ())?, #completion: Bool -> Void) {
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

func verifyMobile(mobile: String, withAreaCode areaCode: String, #verifyCode: String, #failureHandler: ((Reason, String?) -> ())?, #completion: LoginUser -> Void) {
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

// MARK: Login

func sendVerifyCode(ofMobile mobile: String, withAreaCode areaCode: String, #failureHandler: ((Reason, String?) -> ())?, #completion: Bool -> Void) {

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

func loginByMobile(mobile: String, withAreaCode areaCode: String, #verifyCode: String, #failureHandler: ((Reason, String?) -> ())?, #completion: LoginUser -> Void) {

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

func searchUsersWithPhoneNumber(ofPhoneNumber phoneNumber: String, #failureHandler: ((Reason, String?) -> ())?, #completion: [AnyObject] -> Void) {
    
    let requestParameters = [
        "q": phoneNumber
    ]
    
    let parse: JSONDictionary -> [AnyObject]? = { data in
        if let users = data["users"] as? [AnyObject] {
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

// MARK: Upload

func publicUploadToken(#failureHandler: ((Reason, String?) -> ())?, #completion: QiniuProvider -> Void) {

    let parse: JSONDictionary -> QiniuProvider? = { data in
        if let provider = data["provider"] as? String {
            if provider == "qiniu" {
                if let options = data["options"] as? [String: AnyObject] {
                    if
                        let token = options["token"] as? String,
                        let key = options["key"] as? String,
                        let downloadURLString = options["download_url"] as? String {
                            return QiniuProvider(token: token, key: key, downloadURLString: downloadURLString)
                    }
                }
            }
        }

        return nil
    }

    let resource = authJsonResource(path: "/api/v1/attachments/public_upload_token", method: .GET, requestParameters: [:], parse: parse)

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

private func moreFriendships(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Reason, String?) -> ())?, #completion: JSONDictionary -> Void) {
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

func friendships(#completion: [JSONDictionary] -> Void) {

    return headFriendships { result in
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

func headGroups(#failureHandler: ((Reason, String?) -> ())?, #completion: JSONDictionary -> Void) {
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

func moreGroups(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Reason, String?) -> ())?, #completion: JSONDictionary -> Void) {
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

func moreUnreadMessages(inPage page: Int, withPerPage perPage: Int, #failureHandler: ((Reason, String?) -> ())?, #completion: JSONDictionary -> Void) {
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
    return headUnreadMessages { result in
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

func createMessageWithMessageInfo(messageInfo: JSONDictionary, #failureHandler: ((Reason, String?) -> ())?, #completion: (messageID: String) -> Void) {

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

func sendText(text: String, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> (), #failureHandler: ((Reason, String?) -> ())?, #completion: (success: Bool) -> Void) {

    // 因为 message_id 必须来自远端，线程无法切换，所以这里暂时没用 realmQueue // TOOD: 也许有办法

    let realm = RLMRealm.defaultRealm()

    realm.beginWriteTransaction()

    let message = Message()
    //message.messageID = messageID
    message.mediaType = MessageMediaType.Text.rawValue
    message.textContent = text

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

    let messageInfo: JSONDictionary = [
        "recipient_id": recipientID,
        "recipient_type": recipientType,
        "media_type": MessageMediaType.Text.rawValue,
        "text_content": text,
    ]

    createMessageWithMessageInfo(messageInfo, failureHandler: { (reason, errorMessage) in
        if let failureHandler = failureHandler {
            failureHandler(reason, errorMessage)
        }

    }, completion: { messageID in
        dispatch_async(dispatch_get_main_queue()) {
            realm.beginWriteTransaction()
            message.messageID = messageID
            realm.commitWriteTransaction()

            afterCreatedMessage(message)
        }

        completion(success: true)
    })
}



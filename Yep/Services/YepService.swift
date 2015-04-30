//
//  YepService.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import Realm

let baseURL = NSURL(string: "http://park-staging.catchchatchina.com")!

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
    YepUserDefaults.userID.value = loginUser.userID
    YepUserDefaults.nickname.value = loginUser.nickname
    YepUserDefaults.avatarURLString.value = loginUser.avatarURLString
    YepUserDefaults.pusherID.value = loginUser.pusherID

    // NOTICE: 因为一些操作依赖于 accessToken 做检测，又可能依赖上面其他值，所以要放在最后赋值
    YepUserDefaults.v1AccessToken.value = loginUser.accessToken
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

// MARK: Skills

struct Skill: Hashable {
    let id: String
    let name: String
    let localName: String

    var hashValue: Int {
        return id.hashValue
    }
}

func ==(lhs: Skill, rhs: Skill) -> Bool {
    return lhs.id == rhs.id
}

struct SkillCategory {
    let id: String
    let name: String
    let localName: String

    let skills: [Skill]
}

/*
func skillsInSkillCategory(skillCategoryID: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: [Skill] -> Void) {
    let parse: JSONDictionary -> [Skill]? = { data in
        println("skillCategories \(data)")

        if let skillsData = data["skills"] as? [JSONDictionary] {

            var skills = [Skill]()

            for skillInfo in skillsData {
                if
                    let skillID = skillInfo["id"] as? String,
                    let skillName = skillInfo["name"] as? String {
                        let skill = Skill(id: skillID, name: skillName, localName: skillName) // TODO: Skill localName
                        skills.append(skill)
                }
            }

            return skills
        }

        return nil
    }

    let resource = authJsonResource(path: "/api/v1/skill_categories/\(skillCategoryID)/skills", method: .GET, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}
*/

func skillsFromSkillsData(skillsData: [JSONDictionary]) -> [Skill] {
    var skills = [Skill]()

    for skillInfo in skillsData {
        if
            let skillID = skillInfo["id"] as? String,
            let skillName = skillInfo["name"] as? String,
            let skillLocalName = skillInfo["name_string"] as? String {
                let skill = Skill(id: skillID, name: skillName, localName: skillName)
                skills.append(skill)
        }
    }

    return skills
}

func allSkillCategories(#failureHandler: ((Reason, String?) -> Void)?, #completion: [SkillCategory] -> Void) {

    let parse: JSONDictionary -> [SkillCategory]? = { data in
        println("skillCategories \(data)")

        if let categoriesData = data["categories"] as? [JSONDictionary] {

            var skillCategories = [SkillCategory]()

            for categoryInfo in categoriesData {
                if
                    let categoryID = categoryInfo["id"] as? String,
                    let categoryName = categoryInfo["name"] as? String,
                    let categoryLocalName = categoryInfo["name_string"] as? String,
                    let skillsData = categoryInfo["skills"] as? [JSONDictionary] {

                        let skills = skillsFromSkillsData(skillsData)

                        let skillCategory = SkillCategory(id: categoryID, name: categoryName, localName: categoryLocalName, skills: skills)

                        skillCategories.append(skillCategory)
                }
            }

            return skillCategories
        }

        return nil
    }

    let resource = authJsonResource(path: "/api/v1/skill_categories", method: .GET, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

enum SkillSet: Printable {
    case Master
    case Learning

    var description: String {
        switch self {
        case Master:
            return "master_skills"
        case Learning:
            return "learning_skills"
        }
    }
}

func addSkill(skill: Skill, toSkillSet skillSet: SkillSet, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {

    let requestParameters: JSONDictionary = [
        "skill_id": skill.id,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        println("addSkill \(data)")
        return true
    }

    let resource = authJsonResource(path: "/api/v1/\(skillSet)", method: .POST, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func deleteSkill(skill: Skill, fromSkillSet skillSet: SkillSet, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {

    let parse: JSONDictionary -> Bool? = { data in
        println("deleteSkill \(data)")
        return true
    }

    let resource = authJsonResource(path: "/api/v1/\(skillSet)/\(skill.id)", method: .DELETE, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

// MARK: User

func userInfo(#failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {
    let parse: JSONDictionary -> JSONDictionary? = { data in
        println("userInfo \(data)")
        return data
    }

    let resource = authJsonResource(path: "/api/v1/user", method: .GET, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func updateMyselfWithInfo(info: JSONDictionary, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {

    // nickname
    // avatar_url
    // username
    // latitude
    // longitude

    let parse: JSONDictionary -> Bool? = { data in
        println("updateMyself \(data)")
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

enum DiscoveredUserSortStyle: String {
    case Distance = "distance"
    case LastSignIn = "last_sign_in_at"
}

struct DiscoveredUser {
    let id: String
    let nickname: String
    let avatarURLString: String

    let createdAt: NSDate
    let lastSignInAt: NSDate

    let longitude: Double
    let latitude: Double
    let distance: Double

    let masterSkills: [Skill]
    let learningSkills: [Skill]
}

func discoverUsers(#masterSkills: [String], #learningSkills: [String], #discoveredUserSortStyle: DiscoveredUserSortStyle, #failureHandler: ((Reason, String?) -> Void)?, #completion: [DiscoveredUser] -> Void) {
    
    let requestParameters = [
        "master_skills": masterSkills,
        "learning_skills": learningSkills,
        "sort": discoveredUserSortStyle.rawValue
    ]
    
    let parse: JSONDictionary -> [DiscoveredUser]? = { data in

        println("discoverUsers: \(data)")

        if let usersData = data["users"] as? [JSONDictionary] {

            var discoveredUsers = [DiscoveredUser]()

            for userInfo in usersData {
                if let
                    id = userInfo["id"] as? String,
                    nickname = userInfo["nickname"] as? String,
                    avatarURLString = userInfo["avatar_url"] as? String,
                    //createdAt = userInfo["created_at"] as? String,
                    longitude = userInfo["longitude"] as? Double,
                    latitude = userInfo["latitude"] as? Double,
                    distance = userInfo["distance"] as? Double,
                    masterSkillsData = userInfo["master_skills"] as? [JSONDictionary],
                    learningSkillsData = userInfo["learning_skills"] as? [JSONDictionary] {
                        let createdAt = NSDate()
                        let lastSignInAt = NSDate()

                        let masterSkills = skillsFromSkillsData(masterSkillsData)
                        let learningSkills = skillsFromSkillsData(learningSkillsData)

                        let discoverUser = DiscoveredUser(id: id, nickname: nickname, avatarURLString: avatarURLString, createdAt: createdAt, lastSignInAt: lastSignInAt, longitude: longitude, latitude: latitude, distance: distance, masterSkills: masterSkills, learningSkills: learningSkills)
                        
                        discoveredUsers.append(discoverUser)
                }
            }

            return discoveredUsers
        }

        return nil
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

    println("Message info \(messageInfo)")
    
//    if FayeService.sharedManager.client.connected {
//        
//        switch messageInfo["recipient_type"] as! String {
//        case "Circle":
//            FayeService.sharedManager.sendGroupMessage(messageInfo, circleID: messageInfo["recipient_id"] as! String)
//        case "User":
//            FayeService.sharedManager.sendPrivateMessage(messageInfo, userID: messageInfo["recipient_id"] as! String)
//        default:
//            break
//            
//        }
//        
//        completion(messageID: "")
//        
//    } else {
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
//    }
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

func sendVideoInFilePath(filePath: String?, orFileData fileData: NSData?, #metaData: String?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    sendMessageWithMediaType(.Video, inFilePath: filePath, orFileData: fileData, metaData: metaData, text: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
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

        tryCreateSectionDateMessageInConversation(conversation, beforeMessage: message) { sectionDateMessage in
            realm.addObject(sectionDateMessage)
        }
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

        s3PrivateUploadParams(failureHandler: nil) { s3UploadParams in
            uploadFileToS3(inFilePath: filePath, orFileData: fileData, mimeType: mediaType.mineType(), s3UploadParams: s3UploadParams) { (result, error) in

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

                let doCreateMessage = {
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

                // 对于 Video 还要再传 thumbnail，……
                if mediaType == .Video {

                    var thumbnailData: NSData?

                    if
                        let filePath = filePath,
                        let image = thumbnailImageOfVideoInVideoURL(NSURL(fileURLWithPath: filePath)!) {
                            thumbnailData = UIImageJPEGRepresentation(image, YepConfig.messageImageCompressionQuality())
                    }

                    s3PrivateUploadParams(failureHandler: nil) { s3UploadParams in
                        uploadFileToS3(inFilePath: nil, orFileData: thumbnailData, mimeType: MessageMediaType.Image.mineType(), s3UploadParams: s3UploadParams) { (result, error) in

                            if let metaData = metaData {
                                let attachments = ["video": [["file": s3UploadParams.key, "metadata": metaData]], "thumbnail": [["file": s3UploadParams.key]]]
                                messageInfo["attachments"] = attachments

                            } else {
                                let attachments = ["video": [["file": s3UploadParams.key]], "thumbnail": [["file": s3UploadParams.key]]]
                                messageInfo["attachments"] = attachments
                            }

                            doCreateMessage()
                        }
                    }

                } else {
                    doCreateMessage()
                }
            }
        }
    }
}

func markAsReadMessage(message: Message ,#failureHandler: ((Reason, String?) -> Void)?, #completion: (Bool) -> Void) {

    if message.readed || message.messageID.isEmpty {
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

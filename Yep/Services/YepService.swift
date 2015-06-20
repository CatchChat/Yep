//
//  YepService.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift
import CoreLocation

let baseURL = NSURL(string: "http://park-staging.catchchatchina.com")!
let fayeBaseURL = NSURL(string: "ws://faye-staging.catchchatchina.com/faye")!

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

struct SkillCategory {
    let id: String
    let name: String
    let localName: String

    let skills: [Skill]
}

struct Skill: Hashable {

    let category: SkillCategory?

    let id: String
    let name: String
    let localName: String
    let coverURLString: String?

    var hashValue: Int {
        return id.hashValue
    }
}

func ==(lhs: Skill, rhs: Skill) -> Bool {
    return lhs.id == rhs.id
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

                var skillCategory: SkillCategory?
                if
                    let skillCategoryData = skillInfo["category"] as? JSONDictionary,
                    let categoryID = skillCategoryData["id"] as? String,
                    let categoryName = skillCategoryData["name"] as? String,
                    let categoryLocalName = skillCategoryData["name_string"] as? String {
                        skillCategory = SkillCategory(id: categoryID, name: categoryName, localName: categoryLocalName, skills: [])
                }

                let coverURLString = skillInfo["cover_url"] as? String

                let skill = Skill(category: skillCategory, id: skillID, name: skillName, localName: skillLocalName, coverURLString: coverURLString)

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

enum VerifyCodeMethod: String {
    case SMS = "sms"
    case Call = "call"
}

func sendVerifyCodeOfMobile(mobile: String, withAreaCode areaCode: String, useMethod method: VerifyCodeMethod, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {

    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
        "method": method.rawValue
    ]

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = jsonResource(path: "/api/v1/sms_verification_codes", method: .POST, requestParameters: requestParameters, parse: parse)

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

        //println("loginByMobile: \(data)")

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

typealias UploadContact = [String: String]

func friendsInContacts(contacts: [UploadContact], #failureHandler: ((Reason, String?) -> Void)?, #completion: [DiscoveredUser] -> Void) {

    if let
        contactsData = NSJSONSerialization.dataWithJSONObject(contacts, options: .PrettyPrinted, error: nil),
        contactsString = NSString(data: contactsData, encoding: NSUTF8StringEncoding) {

            let requestParameters: JSONDictionary = [
                "contacts": contactsString
            ]

            let parse: JSONDictionary -> [DiscoveredUser]? = { data in
                if let registeredContacts = data["registered_users"] as? [JSONDictionary] {

                    //println("registeredContacts: \(registeredContacts)")
                    
                    var discoveredUsers = [DiscoveredUser]()

                    for registeredContact in registeredContacts {
                        if let discoverUser = parseDiscoveredUser(registeredContact) {
                            discoveredUsers.append(discoverUser)
                        }
                    }

                    return discoveredUsers

                } else {
                    return nil
                }
            }

            let resource = authJsonResource(path: "/api/v1/contacts/upload", method: .POST, requestParameters: requestParameters, parse: parse)
            
            if let failureHandler = failureHandler {
                apiRequest({_ in}, baseURL, resource, failureHandler, completion)
            } else {
                apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
            }

    } else {
        completion([])
    }
}

enum ReportReason {
    case Porno
    case Advertising
    case Scams
    case Other(String)

    var type: Int {
        switch self {
        case .Porno:
            return 0
        case .Advertising:
            return 1
        case .Scams:
            return 2
        case .Other(let description):
            return 3
        }
    }

    var description: String {
        switch self {
        case .Porno:
            return NSLocalizedString("Porno", comment: "")
        case .Advertising:
            return NSLocalizedString("Advertising", comment: "")
        case .Scams:
            return NSLocalizedString("Scams", comment: "")
        case .Other(let description):
            return NSLocalizedString("Other", comment: "")
        }
    }
}

func reportProfileUser(profileUser: ProfileUser, forReason reason: ReportReason, #failureHandler: ((Reason, String?) -> Void)?, #completion: Bool -> Void) {

    let userID: String

    switch profileUser {
    case .DiscoveredUserType(let discoveredUser):
        userID = discoveredUser.id
    case .UserType(let user):
        userID = user.userID
    }

    var requestParameters: JSONDictionary = [
        "recipient_id": userID,
        "report_type": reason.type
    ]

    switch reason {
    case .Other(let description):
        requestParameters["reason"] = description
    default:
        break
    }

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/api/v1/user_reports", method: .POST, requestParameters: requestParameters, parse: parse)

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
    case Default = "default"

    var name: String {
        switch self {
        case .Distance:
            return NSLocalizedString("Nearby", comment: "")
        case .LastSignIn:
            return NSLocalizedString("Time", comment: "")
        case .Default:
            return NSLocalizedString("Default", comment: "")
        }
    }
}

struct DiscoveredUser {

    struct SocialAccountProvider {
        let name: String
        let enabled: Bool
    }

    let id: String
    let nickname: String
    let introduction: String?
    let avatarURLString: String

    let createdUnixTime: NSTimeInterval
    let lastSignInUnixTime: NSTimeInterval

    let longitude: Double
    let latitude: Double
    let distance: Double

    let masterSkills: [Skill]
    let learningSkills: [Skill]

    let socialAccountProviders: [SocialAccountProvider]
}

let parseDiscoveredUser: JSONDictionary -> DiscoveredUser? = { userInfo in
    if let
        id = userInfo["id"] as? String,
        nickname = userInfo["nickname"] as? String,
        avatarURLString = userInfo["avatar_url"] as? String,
        createdUnixTime = userInfo["created_at"] as? NSTimeInterval,
        lastSignInUnixTime = userInfo["last_sign_in_at"] as? NSTimeInterval,
        longitude = userInfo["longitude"] as? Double,
        latitude = userInfo["latitude"] as? Double,
        distance = userInfo["distance"] as? Double,
        masterSkillsData = userInfo["master_skills"] as? [JSONDictionary],
        learningSkillsData = userInfo["learning_skills"] as? [JSONDictionary],
        socialAccountProvidersInfo = userInfo["providers"] as? [String: Bool] {

            let masterSkills = skillsFromSkillsData(masterSkillsData)
            let learningSkills = skillsFromSkillsData(learningSkillsData)

            var socialAccountProviders = Array<DiscoveredUser.SocialAccountProvider>()

            for (name, enabled) in socialAccountProvidersInfo {
                let provider = DiscoveredUser.SocialAccountProvider(name: name, enabled: enabled)

                socialAccountProviders.append(provider)
            }

            let introduction = userInfo["introduction"] as? String

            let discoverUser = DiscoveredUser(id: id, nickname: nickname, introduction: introduction, avatarURLString: avatarURLString, createdUnixTime: createdUnixTime, lastSignInUnixTime: lastSignInUnixTime, longitude: longitude, latitude: latitude, distance: distance, masterSkills: masterSkills, learningSkills: learningSkills, socialAccountProviders: socialAccountProviders)

            return discoverUser
    }

    return nil
}

let parseDiscoveredUsers: JSONDictionary -> [DiscoveredUser]? = { data in

    //println("discoverUsers: \(data)")

    if let usersData = data["users"] as? [JSONDictionary] {

        var discoveredUsers = [DiscoveredUser]()

        for userInfo in usersData {

            if let discoverUser = parseDiscoveredUser(userInfo) {
                discoveredUsers.append(discoverUser)
            }
        }

        return discoveredUsers
    }
    
    return nil
}


func discoverUsers(#masterSkills: [String], #learningSkills: [String], #discoveredUserSortStyle: DiscoveredUserSortStyle, #failureHandler: ((Reason, String?) -> Void)?, #completion: [DiscoveredUser] -> Void) {
    
    let requestParameters:[String: AnyObject] = [
        "master_skills": masterSkills,
        "learning_skills": learningSkills,
        "sort": discoveredUserSortStyle.rawValue
    ]
    
    let parse = parseDiscoveredUsers
    
    let resource = authJsonResource(path: "/api/v1/user/discover", method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

func searchUsersByQ(q: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: [DiscoveredUser] -> Void) {

    let requestParameters = [
        "q": q
    ]

    let parse = parseDiscoveredUsers

    let resource = authJsonResource(path: "/api/v1/users/search", method: .GET, requestParameters: requestParameters, parse: parse)

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

func sentButUnreadMessages(#failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/api/v1/messages/sent_unread", method: .GET, requestParameters:[:] , parse: parse )
    
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

    func apiCreateMessageWithMessageInfo(messageInfo: JSONDictionary, #failureHandler: ((Reason, String?) -> Void)?, #completion: (messageID: String) -> Void) {

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


    if
        FayeService.sharedManager.client.connected,
        let recipientType = messageInfo["recipient_type"] as? String,
        let recipientID = messageInfo["recipient_id"] as? String {

            switch recipientType {

            case "Circle":
                FayeService.sharedManager.sendGroupMessage(messageInfo, circleID: recipientID, completion: { (success, messageID) in

                    if success, let messageID = messageID {
                        println("Mesasge id is \(messageID)")

                        completion(messageID: messageID)

                    } else {
                        if let failureHandler = failureHandler {
                            failureHandler(Reason.CouldNotParseJSON, "Faye Created Message Error")
                        } else {
                            defaultFailureHandler(Reason.CouldNotParseJSON, "Faye Created Message Error")
                        }

                        println("Faye failed, use API to create message")
                        apiCreateMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: completion)
                    }
                })

            case "User":
                FayeService.sharedManager.sendPrivateMessage(messageInfo, messageType: .Default, userID: recipientID, completion: { (success, messageID) in

                    // 这里有一定概率不执行，导致不能标记，也没有 messageID，需要进一步研究
                    println("completion sendPrivateMessage Default")

                    if success, let messageID = messageID {
                        println("Mesasge id is \(messageID)")

                        completion(messageID: messageID)

                    } else {
                        if success {
                            println("Mesasgeing package without message id")

                        } else {
                            if let failureHandler = failureHandler {
                                failureHandler(Reason.CouldNotParseJSON, "Faye Created Message Error")
                            } else {
                                defaultFailureHandler(Reason.CouldNotParseJSON, "Faye Created Message Error")
                            }

                            println("Faye failed, use API to create message")
                            apiCreateMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: completion)
                        }
                    }
                })
                
            default:
                break
            }
        
    } else {
        apiCreateMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: completion)
    }
}

func sendText(text: String, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
        var moreInfo = info
        moreInfo["text_content"] = text
        return moreInfo
    }
    createAndSendMessageWithMediaType(.Text, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendImageInFilePath(filePath: String?, orFileData fileData: NSData?, #metaData: String?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.Image, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendAudioInFilePath(filePath: String?, orFileData fileData: NSData?, #metaData: String?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.Audio, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendVideoInFilePath(filePath: String?, orFileData fileData: NSData?, #metaData: String?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.Video, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendLocationWithCoordinate(coordinate: CLLocationCoordinate2D, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
        var moreInfo = info
        moreInfo["longitude"] = coordinate.longitude
        moreInfo["latitude"] = coordinate.latitude
        return moreInfo
    }

    createAndSendMessageWithMediaType(.Location, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func createAndSendMessageWithMediaType(mediaType: MessageMediaType, inFilePath filePath: String?, orFileData fileData: NSData?, #metaData: String?, #fillMoreInfo: (JSONDictionary -> JSONDictionary)?, toRecipient recipientID: String, #recipientType: String, #afterCreatedMessage: (Message) -> Void, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {
    // 因为 message_id 必须来自远端，线程无法切换，所以这里暂时没用 realmQueue // TOOD: 也许有办法

    let realm = Realm()

    realm.beginWrite()

    let message = Message()
    //message.messageID = messageID

    message.mediaType = mediaType.rawValue

    realm.add(message)

    realm.commitWrite()


    // 消息来自于自己

    if let me = tryGetOrCreateMeInRealm(realm) {
        realm.write {
            message.fromFriend = me
        }
    }

    // 消息的 Conversation，没有就创建

    var conversation: Conversation? = nil

    realm.beginWrite()

    if recipientType == "User" {
        if let withFriend = userWithUserID(recipientID, inRealm: realm) {
            conversation = withFriend.conversation
        }

    } else {
        if let withGroup = groupWithGroupID(recipientID, inRealm: realm) {
            conversation = withGroup.conversation
        }
    }

    if conversation == nil {
        let newConversation = Conversation()

        if recipientType == "User" {
            newConversation.type = ConversationType.OneToOne.rawValue

            if let withFriend = userWithUserID(recipientID, inRealm: realm) {
                newConversation.withFriend = withFriend
            }

        } else {
            newConversation.type = ConversationType.Group.rawValue

            if let withGroup = groupWithGroupID(recipientID, inRealm: realm) {
                newConversation.withGroup = withGroup
            }
        }

        conversation = newConversation
    }

    if let conversation = conversation {
        conversation.updatedUnixTime = message.createdUnixTime // 关键哦
        message.conversation = conversation

        tryCreateSectionDateMessageInConversation(conversation, beforeMessage: message, inRealm: realm) { sectionDateMessage in
            realm.add(sectionDateMessage)
        }
    }

    realm.commitWrite()


    var messageInfo: JSONDictionary = [
        "recipient_id": recipientID,
        "recipient_type": recipientType,
        "media_type": mediaType.description,
    ]

    if let fillMoreInfo = fillMoreInfo {
        messageInfo = fillMoreInfo(messageInfo)
    }

    realm.beginWrite()

    if let textContent = messageInfo["text_content"] as? String {
        message.textContent = textContent
    }

    if let
        longitude = messageInfo["longitude"] as? Double,
        latitude = messageInfo["latitude"] as? Double {
            let coordinate = Coordinate()
            coordinate.longitude = longitude
            coordinate.latitude = latitude

            message.coordinate = coordinate
    }

    realm.commitWrite()


    // 发出之前就显示 Message
    afterCreatedMessage(message)

    // 下面开始真正的消息发送
    sendMessage(message, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, failureHandler: failureHandler, completion: completion)
}

func sendMessage(message: Message, inFilePath filePath: String?, orFileData fileData: NSData?, #metaData: String?, #fillMoreInfo: (JSONDictionary -> JSONDictionary)?, toRecipient recipientID: String, #recipientType: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    if let mediaType = MessageMediaType(rawValue: message.mediaType) {

        var messageInfo: JSONDictionary = [
            "recipient_id": recipientID,
            "recipient_type": recipientType,
            "media_type": mediaType.description,
        ]

        if let fillMoreInfo = fillMoreInfo {
            messageInfo = fillMoreInfo(messageInfo)
        }

        switch mediaType {

        case .Text, .Location:
            createMessageWithMessageInfo(messageInfo, failureHandler: { (reason, errorMessage) in
                if let failureHandler = failureHandler {
                    failureHandler(reason, errorMessage)
                }

                dispatch_async(dispatch_get_main_queue()) {

                    let realm = message.realm

                    realm?.write {
                        message.sendState = MessageSendState.Failed.rawValue
                    }

                    NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                }

            }, completion: { messageID in

                dispatch_async(dispatch_get_main_queue()) {
                    let realm = message.realm
                    realm?.write {
                        message.messageID = messageID
                        message.sendState = MessageSendState.Successed.rawValue
                    }

                    completion(success: true)

                    NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                }
            })

        default:

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
                                let realm = message.realm
                                realm?.write {
                                    message.sendState = MessageSendState.Failed.rawValue
                                }

                                NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                            }

                        }, completion: { messageID in
                            dispatch_async(dispatch_get_main_queue()) {
                                let realm = message.realm
                                realm?.write {
                                    message.messageID = messageID
                                    message.sendState = MessageSendState.Successed.rawValue
                                }

                                completion(success: true)

                                NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                            }
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

                        s3PrivateUploadParams(failureHandler: nil) { thumbnailS3UploadParams in
                            uploadFileToS3(inFilePath: nil, orFileData: thumbnailData, mimeType: MessageMediaType.Image.mineType(), s3UploadParams: thumbnailS3UploadParams) { (result, error) in

                                if let metaData = metaData {
                                    let attachments = [
                                        "video": [
                                            ["file": s3UploadParams.key, "metadata": metaData]
                                        ],
                                        "thumbnail": [["file": thumbnailS3UploadParams.key]]
                                    ]
                                    messageInfo["attachments"] = attachments
                                    
                                } else {
                                    let attachments = [
                                        "video": [
                                            ["file": s3UploadParams.key]
                                        ],
                                        "thumbnail": [["file": thumbnailS3UploadParams.key]]
                                    ]
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
}

func resendMessage(message: Message, #failureHandler: ((Reason, String?) -> Void)?, #completion: (success: Bool) -> Void) {

    var recipientID: String?
    var recipientType: String?

    if let conversation = message.conversation {
        if conversation.type == ConversationType.OneToOne.rawValue {
            recipientID = conversation.withFriend?.userID
            recipientType = ConversationType.OneToOne.nameForServer

        } else if conversation.type == ConversationType.Group.rawValue {
            recipientID = conversation.withGroup?.groupID
            recipientType = ConversationType.Group.nameForServer
        }
    }

    if let
        recipientID = recipientID,
        recipientType = recipientType,
        messageMediaType = MessageMediaType(rawValue: message.mediaType) {

            switch messageMediaType {

            case .Text:

                let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
                    var moreInfo = info
                    moreInfo["text_content"] = message.textContent
                    return moreInfo
                }

                sendMessage(message, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, failureHandler: failureHandler, completion: completion)

            case .Image:
                let filePath = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName)?.path

                sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, failureHandler: failureHandler, completion: completion)

           case .Video:
                let filePath = NSFileManager.yepMessageVideoURLWithName(message.localAttachmentName)?.path

                sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, failureHandler: failureHandler, completion: completion)

            case .Audio:
                let filePath = NSFileManager.yepMessageAudioURLWithName(message.localAttachmentName)?.path

                sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, failureHandler: failureHandler, completion: completion)

            case .Location:
                if let coordinate = message.coordinate {
                    let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
                        var moreInfo = info
                        moreInfo["longitude"] = coordinate.longitude
                        moreInfo["latitude"] = coordinate.latitude
                        return moreInfo
                    }

                    sendMessage(message, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, failureHandler: failureHandler, completion: completion)
                }

            default:
                break
            }
    }
}

func markAsReadMessage(message: Message ,#failureHandler: ((Reason, String?) -> Void)?, #completion: (Bool) -> Void) {

    if message.messageID.isEmpty {
        return
    }
    
    let state = UIApplication.sharedApplication().applicationState
    if state == UIApplicationState.Background || state == UIApplicationState.Inactive {
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

func authURLRequestWithURL(url: NSURL) -> NSURLRequest {
    
    var request = NSMutableURLRequest(URL: url)
    
    if let token = YepUserDefaults.v1AccessToken.value {
        request.setValue("Token token=\"\(token)\"", forHTTPHeaderField: "Authorization")
    }

    return request
}

func socialAccountWithProvider(provider: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: JSONDictionary -> Void) {
    
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/api/v1/user/\(provider)", method: .GET, requestParameters: [:], parse: parse)
    
    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

struct GithubWork {

    struct Repo {
        let name: String
        let language: String?
        let description: String
        let stargazersCount: Int
        let htmlURLString: String
    }

    struct User {
        let loginName: String
        let avatarURLString: String
        let htmlURLString: String
        let publicReposCount: Int
        let followersCount: Int
        let followingCount: Int
    }

    let repos: [Repo]
    let user: User
}

func githubWorkOfUserWithUserID(userID: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: GithubWork -> Void) {

    let parse: JSONDictionary -> GithubWork? = { data in

        if let reposData = data["repos"] as? [JSONDictionary], userInfo = data["user"] as? JSONDictionary {

            //println("reposData: \(reposData)")

            var repos = Array<GithubWork.Repo>()

            for repoInfo in reposData {
                if let
                    name = repoInfo["name"] as? String,
                    description = repoInfo["description"] as? String,
                    stargazersCount = repoInfo["stargazers_count"] as? Int,
                    htmlURLString = repoInfo["html_url"] as? String {

                        let language = repoInfo["language"] as? String
                        let repo = GithubWork.Repo(name: name, language: language, description: description, stargazersCount: stargazersCount, htmlURLString: htmlURLString)

                        repos.append(repo)
                }
            }

            repos.sort { $0.stargazersCount > $1.stargazersCount }

            if let
                loginName = userInfo["login"] as? String,
                avatarURLString = userInfo["avatar_url"] as? String,
                htmlURLString = userInfo["html_url"] as? String,
                publicReposCount = userInfo["public_repos"] as? Int,
                followersCount = userInfo["followers"] as? Int,
                followingCount = userInfo["following"] as? Int {

                    let user = GithubWork.User(loginName: loginName, avatarURLString: avatarURLString, htmlURLString: htmlURLString, publicReposCount: publicReposCount, followersCount: followersCount, followingCount: followingCount)

                    let githubWork = GithubWork(repos: repos, user: user)

                    return githubWork
            }
        }

        return nil
    }

    let resource = authJsonResource(path: "/api/v1/users/\(userID)/github", method: .GET, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

struct DribbbleWork {

    struct Shot {

        struct Images {
            let hidpi: String?
            let normal: String
            let teaser: String
        }

        let title: String
        let description: String
        let htmlURLString: String
        let images: Images
        let likesCount: Int
        let commentsCount: Int
    }

    let shots: [Shot]
}

func dribbbleWorkOfUserWithUserID(userID: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: DribbbleWork -> Void) {

    let parse: JSONDictionary -> DribbbleWork? = { data in

        if let shotsData = data["shots"] as? [JSONDictionary] {
            var shots = Array<DribbbleWork.Shot>()

            for shotInfo in shotsData {
                if let
                    title = shotInfo["title"] as? String,
                    description = shotInfo["description"] as? String,
                    htmlURLString = shotInfo["html_url"] as? String,
                    imagesInfo = shotInfo["images"] as? JSONDictionary,
                    likesCount = shotInfo["likes_count"] as? Int,
                    commentsCount = shotInfo["comments_count"] as? Int {
                        if let
                            normal = imagesInfo["normal"] as? String,
                            teaser = imagesInfo["teaser"] as? String {
                                let hidpi = imagesInfo["hidpi"] as? String

                                let images = DribbbleWork.Shot.Images(hidpi: hidpi, normal: normal, teaser: teaser)

                                let shot = DribbbleWork.Shot(title: title, description: description, htmlURLString: htmlURLString, images: images, likesCount: likesCount, commentsCount: commentsCount)

                                shots.append(shot)
                        }
                }
            }

            return DribbbleWork(shots: shots)
        }

        return nil
    }

    let resource = authJsonResource(path: "/api/v1/users/\(userID)/dribbble", method: .GET, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}


struct InstagramWork {

    struct Media {

        struct Images {
            let lowResolution: String
            let standardResolution: String
            let thumbnail: String
        }

        let linkURLString: String
        let images: Images
        let likesCount: Int
        let commentsCount: Int
    }

    let medias: [Media]
}

func instagramWorkOfUserWithUserID(userID: String, #failureHandler: ((Reason, String?) -> Void)?, #completion: InstagramWork -> Void) {

    let parse: JSONDictionary -> InstagramWork? = { data in
        //println("instagramData:\(data)")

        if let mediaData = data["media"] as? [JSONDictionary] {
            var medias = Array<InstagramWork.Media>()

            for mediaInfo in mediaData {
                if let
                    linkURLString = mediaInfo["link"] as? String,
                    imagesInfo = mediaInfo["images"] as? JSONDictionary,
                    likesInfo = mediaInfo["likes"] as? JSONDictionary,
                    commentsInfo = mediaInfo["comments"] as? JSONDictionary {
                        if let
                            lowResolutionInfo = imagesInfo["low_resolution"] as? JSONDictionary,
                            standardResolutionInfo = imagesInfo["standard_resolution"] as? JSONDictionary,
                            thumbnailInfo = imagesInfo["thumbnail"] as? JSONDictionary,

                            lowResolution = lowResolutionInfo["url"] as? String,
                            standardResolution = standardResolutionInfo["url"] as? String,
                            thumbnail = thumbnailInfo["url"] as? String,

                            likesCount = likesInfo["count"] as? Int,
                            commentsCount = commentsInfo["count"] as? Int {

                                let images = InstagramWork.Media.Images(lowResolution: lowResolution, standardResolution: standardResolution, thumbnail: thumbnail)

                                let media = InstagramWork.Media(linkURLString: linkURLString, images: images, likesCount: likesCount, commentsCount: commentsCount)

                                medias.append(media)
                        }
                }
            }

            return InstagramWork(medias: medias)
        }

        return nil
    }

    let resource = authJsonResource(path: "/api/v1/users/\(userID)/instagram", method: .GET, requestParameters: [:], parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL, resource, failureHandler, completion)
    } else {
        apiRequest({_ in}, baseURL, resource, defaultFailureHandler, completion)
    }
}

enum SocialWork {
    case Dribbble(DribbbleWork)
    case Instagram(InstagramWork)
}

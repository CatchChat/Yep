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
import Alamofire

#if STAGING
let yepBaseURL = NSURL(string: "https://park-staging.catchchatchina.com/api")!
let fayeBaseURL = NSURL(string: "wss://faye-staging.catchchatchina.com/faye")!
#else
let yepBaseURL = NSURL(string: "https://api.soyep.com")!
let fayeBaseURL = NSURL(string: "wss://faye.catchchatchina.com/faye")!
#endif

// Models

struct LoginUser: CustomStringConvertible {
    let accessToken: String
    let userID: String
    let username: String?
    let nickname: String
    let avatarURLString: String?
    let pusherID: String

    var description: String {
        return "LoginUser(accessToken: \(accessToken), userID: \(userID), nickname: \(nickname), avatarURLString: \(avatarURLString), \(pusherID))"
    }
}

/*
struct QiniuProvider: CustomStringConvertible {
    let token: String
    let key: String
    let downloadURLString: String

    var description: String {
        return "QiniuProvider(token: \(token), key: \(key), downloadURLString: \(downloadURLString))"
    }
}
*/

func saveTokenAndUserInfoOfLoginUser(loginUser: LoginUser) {
    YepUserDefaults.userID.value = loginUser.userID
    YepUserDefaults.nickname.value = loginUser.nickname
    YepUserDefaults.avatarURLString.value = loginUser.avatarURLString
    YepUserDefaults.pusherID.value = loginUser.pusherID

    // NOTICE: 因为一些操作依赖于 accessToken 做检测，又可能依赖上面其他值，所以要放在最后赋值
    YepUserDefaults.v1AccessToken.value = loginUser.accessToken
}

// MARK: - Register

func validateMobile(mobile: String, withAreaCode areaCode: String, failureHandler: FailureHandler?, completion: ((Bool, String)) -> Void) {
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

    let resource = jsonResource(path: "/v1/users/mobile_validate", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func registerMobile(mobile: String, withAreaCode areaCode: String, nickname: String, failureHandler: FailureHandler?, completion: Bool -> Void) {
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

    let resource = jsonResource(path: "/v1/registration/create", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func verifyMobile(mobile: String, withAreaCode areaCode: String, verifyCode: String, failureHandler: FailureHandler?, completion: LoginUser -> Void) {
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
                        let username = user["username"] as? String
                        let avatarURLString = user["avatar_url"] as? String
                        return LoginUser(accessToken: accessToken, userID: userID, username: username, nickname: nickname, avatarURLString: avatarURLString, pusherID: pusherID)
                }
            }
        }

        return nil
    }

    let resource = jsonResource(path: "/v1/registration/update", method: .PUT, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Skills

struct SkillCategory {
    let id: String
    let name: String
    let localName: String

    let skills: [Skill]
}

struct Skill: Hashable {

    let category: SkillCategory?

    var skillCategory: SkillCell.Skill.Category? {
        if let category = category {
            return SkillCell.Skill.Category(rawValue: category.name)
        }
        return nil
    }

    let id: String
    let name: String
    let localName: String
    let coverURLString: String?

    var hashValue: Int {
        return id.hashValue
    }

    static func fromJSONDictionary(skillInfo: JSONDictionary) -> Skill? {
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

                return skill
        }

        return nil
    }
}

func ==(lhs: Skill, rhs: Skill) -> Bool {
    return lhs.id == rhs.id
}

func skillsFromSkillsData(skillsData: [JSONDictionary]) -> [Skill] {
    var skills = [Skill]()

    for skillInfo in skillsData {

        if let skill = Skill.fromJSONDictionary(skillInfo) {
            skills.append(skill)
        }
    }

    return skills
}

func allSkillCategories(failureHandler failureHandler: FailureHandler?, completion: [SkillCategory] -> Void) {

    let parse: JSONDictionary -> [SkillCategory]? = { data in
        //println("skillCategories \(data)")

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

    let resource = authJsonResource(path: "/v1/skill_categories", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

enum SkillSet: Int {
    case Master
    case Learning

    var serverPath: String {
        switch self {
        case Master:
            return "master_skills"
        case Learning:
            return "learning_skills"
        }
    }

    var name: String {
        switch self {
        case .Master:
            return NSLocalizedString("Master", comment: "")
        case .Learning:
            return NSLocalizedString("Learning", comment: "")
        }
    }

    var annotationText: String {
        switch self {
        case .Master:
            return NSLocalizedString("What are you good at?", comment: "")
        case .Learning:
            return NSLocalizedString("What are you learning?", comment: "")
        }
    }
    var failedSelectSkillMessage: String {
        switch self {
        case .Master:
            return NSLocalizedString("This skill already in another learning skills set!", comment: "")
        case .Learning:
            return NSLocalizedString("This skill already in another master skills set!", comment: "")
        }
    }
}

func addSkillWithSkillID(skillID: String, toSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let requestParameters: JSONDictionary = [
        "skill_id": skillID,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        println("addSkill \(skillID)")
        return true
    }

    let resource = authJsonResource(path: "/v1/\(skillSet.serverPath)", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func addSkill(skill: Skill, toSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: Bool -> Void) {

    addSkillWithSkillID(skill.id, toSkillSet: skillSet, failureHandler: failureHandler, completion: completion)
}

func deleteSkillWithID(skillID: String, fromSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/\(skillSet.serverPath)/\(skillID)", method: .DELETE, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func deleteSkill(skill: Skill, fromSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: Bool -> Void) {

    deleteSkillWithID(skill.id, fromSkillSet: skillSet, failureHandler: failureHandler, completion: completion)
}

func updateCoverOfSkillWithSkillID(skillID: String, coverURLString: String, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let requestParameters: JSONDictionary = [
        "cover_url": coverURLString,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/skills/\(skillID)", method: .PATCH, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - User

func userInfoOfUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func discoverUserByUsername(username: String, failureHandler: FailureHandler?, completion: DiscoveredUser -> Void) {

    let parse: JSONDictionary -> DiscoveredUser? = { data in

        //println("discoverUserByUsernamedata: \(data)")
        return parseDiscoveredUser(data)
    }

    let resource = authJsonResource(path: "/v1/users/\(username)/profile", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// 自己的信息
func userInfo(failureHandler failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/user", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func updateMyselfWithInfo(info: JSONDictionary, failureHandler: FailureHandler?, completion: Bool -> Void) {

    // nickname
    // avatar_url
    // username
    // latitude
    // longitude

    let parse: JSONDictionary -> Bool? = { data in
        //println("updateMyself \(data)")
        return true
    }
    
    let resource = authJsonResource(path: "/v1/user", method: .PATCH, requestParameters: info, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func updateAvatarWithImageData(imageData: NSData, failureHandler: FailureHandler?, completion: String -> Void) {

    guard let token = YepUserDefaults.v1AccessToken.value else {
        println("updateAvatarWithImageData no token")
        return
    }

    let parameters: [String: String] = [
        "Authorization": "Token token=\"\(token)\"",
    ]

    let filename = "avatar.jpg"

    Alamofire.upload(.PATCH, yepBaseURL.absoluteString + "/v1/user/set_avatar", headers: parameters, multipartFormData: { multipartFormData in

        multipartFormData.appendBodyPart(data: imageData, name: "avatar", fileName: filename, mimeType: "image/jpeg")

    }, encodingCompletion: { encodingResult in
        //println("encodingResult: \(encodingResult)")

        switch encodingResult {

        case .Success(let upload, _, _):

            upload.responseJSON(completionHandler: { response in

                guard let
                    data = response.data,
                    json = decodeJSON(data),
                    avatarInfo = json["avatar"] as? JSONDictionary,
                    avatarURLString = avatarInfo["url"] as? String
                else {
                    failureHandler?(reason: .CouldNotParseJSON, errorMessage: nil)
                    return
                }

                completion(avatarURLString)
            })

        case .Failure(let encodingError):

            failureHandler?(reason: .Other(nil), errorMessage: "\(encodingError)")
        }
    })
}

enum VerifyCodeMethod: String {
    case SMS = "sms"
    case Call = "call"
}

func sendVerifyCodeOfMobile(mobile: String, withAreaCode areaCode: String, useMethod method: VerifyCodeMethod, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let requestParameters = [
        "mobile": mobile,
        "phone_code": areaCode,
        "method": method.rawValue
    ]

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = jsonResource(path: "/v1/sms_verification_codes", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func loginByMobile(mobile: String, withAreaCode areaCode: String, verifyCode: String, failureHandler: FailureHandler?, completion: LoginUser -> Void) {

    println("User login type is \(YepConfig.clientType())")
    
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
                        let username = user["username"] as? String
                        let avatarURLString = user["avatar_url"] as? String
                        return LoginUser(accessToken: accessToken, userID: userID, username: username, nickname: nickname, avatarURLString: avatarURLString, pusherID: pusherID)
                }
            }
        }
        
        return nil
    }

    let resource = jsonResource(path: "/v1/auth/token_by_mobile", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func logout(failureHandler failureHandler: FailureHandler?, completion: () -> Void) {

    let parse: JSONDictionary -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/auth/logout", method: .DELETE, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func disableNotificationFromUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/dnd", method: .POST, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func enableNotificationFromUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/dnd", method: .DELETE, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func disableNotificationFromCircleWithCircleID(circleID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {
    
    let parse: JSONDictionary -> Bool? = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(circleID)/dnd", method: .POST, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func enableNotificationFromCircleWithCircleID(circleID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {
    
    let parse: JSONDictionary -> Bool? = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(circleID)/dnd", method: .DELETE, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func headBlockedUsers(failureHandler failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/blocked_users", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
}

private func moreBlockedUsers(inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/blocked_users", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func blockedUsersByMe(failureHandler failureHandler: FailureHandler?, completion: [DiscoveredUser] -> Void) {

    let parse: [JSONDictionary] -> [DiscoveredUser] = { blockedUsersData in

        var blockedUsers = [DiscoveredUser]()

        for blockedUserInfo in blockedUsersData {
            if let blockedUser = parseDiscoveredUser(blockedUserInfo) {
                blockedUsers.append(blockedUser)
            }
        }

        return blockedUsers
    }

    headBlockedUsers(failureHandler: failureHandler, completion: { result in

        guard let page1BlockedUsers = result["blocked_users"] as? [JSONDictionary] else {
            completion([])
            return
        }

        guard let count = result["count"] as? Int, currentPage = result["current_page"] as? Int, perPage = result["per_page"] as? Int else {

            println("blockedUsersByMe not paging info.")

            completion(parse(page1BlockedUsers))
            return
        }

        if count <= currentPage * perPage {
            completion(parse(page1BlockedUsers))
            
        } else {
            var blockedUsers = [JSONDictionary]()

            blockedUsers += page1BlockedUsers

            // We have more blockedUsers

            let downloadGroup = dispatch_group_create()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                dispatch_group_enter(downloadGroup)

                moreBlockedUsers(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    failureHandler?(reason: reason, errorMessage: errorMessage)

                    dispatch_group_leave(downloadGroup)

                    }, completion: { result in
                        if let currentPageBlockedUsers = result["blocked_users"] as? [JSONDictionary] {
                            blockedUsers += currentPageBlockedUsers
                        }
                        dispatch_group_leave(downloadGroup)
                })
            }

            dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                completion(parse(blockedUsers))
            }
        }
    })
}

func blockUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let requestParameters = [
        "user_id": userID
    ]

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/blocked_users", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func unblockUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/blocked_users/\(userID)", method: .DELETE, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func settingsForUser(userID userID: String, failureHandler: FailureHandler?, completion: (blocked: Bool, doNotDisturb: Bool) -> Void) {

    let parse: JSONDictionary -> (Bool, Bool)? = { data in

        if let
            blocked = data["blocked"] as? Bool,
            doNotDisturb = data["dnd"] as? Bool {
                return (blocked, doNotDisturb)
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/settings_with_current_user", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func settingsForGroup(groupID groupID: String, failureHandler: FailureHandler?, completion: (doNotDisturb: Bool) -> Void) {
    
    let parse: JSONDictionary -> (Bool)? = { data in
        
        if let
            doNotDisturb = data["dnd"] as? Bool {
                return doNotDisturb
        }
        
        return nil
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/dnd", method: .GET, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Contacts

func searchUsersByMobile(mobile: String, failureHandler: FailureHandler?, completion: [JSONDictionary] -> Void) {
    
    let requestParameters = [
        "q": mobile
    ]
    
    let parse: JSONDictionary -> [JSONDictionary]? = { data in
        if let users = data["users"] as? [JSONDictionary] {
            return users
        }
        return []
    }
    
    let resource = authJsonResource(path: "/v1/users/search", method: .GET, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

typealias UploadContact = [String: String]

func friendsInContacts(contacts: [UploadContact], failureHandler: FailureHandler?, completion: [DiscoveredUser] -> Void) {

    if let
        contactsData = try? NSJSONSerialization.dataWithJSONObject(contacts, options: .PrettyPrinted),
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

            let resource = authJsonResource(path: "/v1/contacts/upload", method: .POST, requestParameters: requestParameters, parse: parse)
            
            if let failureHandler = failureHandler {
                apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
            } else {
                apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
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
        case .Other:
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
        case .Other:
            return NSLocalizedString("Other", comment: "")
        }
    }
}

func reportProfileUser(profileUser: ProfileUser, forReason reason: ReportReason, failureHandler: FailureHandler?, completion: () -> Void) {

    let userID: String

    switch profileUser {
    case .DiscoveredUserType(let discoveredUser):
        userID = discoveredUser.id
    case .UserType(let user):
        userID = user.userID
    }

    var requestParameters: JSONDictionary = [
        "report_type": reason.type
    ]

    switch reason {
    case .Other(let description):
        requestParameters["reason"] = description
    default:
        break
    }

    let parse: JSONDictionary -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/reports", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func reportFeed(feedID: String, forReason reason: ReportReason, failureHandler: FailureHandler?, completion: () -> Void) {
    
    var requestParameters: JSONDictionary = [
        "report_type": reason.type
    ]
    
    switch reason {
    case .Other(let description):
        requestParameters["reason"] = description
    default:
        break
    }
    
    let parse: JSONDictionary -> Void? = { data in
        return
    }
    
    let resource = authJsonResource(path: "/v1/topics/\(feedID)/reports", method: .POST, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Friend Requests

struct FriendRequest {
    enum State: String {
        case None       = "none"
        case Pending    = "pending"
        case Accepted   = "accepted"
        case Rejected   = "rejected"
        case Blocked    = "blocked"
    }
}

func sendFriendRequestToUser(user: User, failureHandler: FailureHandler?, completion: FriendRequest.State -> Void) {

    let requestParameters = [
        "friend_id": user.userID,
    ]

    let parse: JSONDictionary -> FriendRequest.State? = { data in
        //println("sendFriendRequestToUser: \(data)")

        if let state = data["state"] as? String {
            return FriendRequest.State(rawValue: state)
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/friend_requests", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func stateOfFriendRequestWithUser(user: User, failureHandler: FailureHandler?, completion: (isFriend: Bool,receivedFriendRequestSate: FriendRequest.State, receivedFriendRequestID: String, sentFriendRequestState: FriendRequest.State) -> Void) {

    let requestParameters = [
        "user_id": user.userID,
    ]

    let parse: JSONDictionary -> (Bool, FriendRequest.State, String, FriendRequest.State)? = { data in
        println("stateOfFriendRequestWithUser: \(data)")

        var isFriend = false
        var receivedFriendRequestState = FriendRequest.State.None
        var receivedFriendRequestID = ""
        var sentFriendRequestState = FriendRequest.State.None

        if let friend = data["friend"] as? Bool {
            isFriend = friend
        }

        if let
            receivedInfo = data["received"] as? JSONDictionary,
            state = receivedInfo["state"] as? String,
            ID = receivedInfo["id"] as? String {
                if let state = FriendRequest.State(rawValue: state) {
                    receivedFriendRequestState = state
                }

                receivedFriendRequestID = ID
        }

        if let blocked = data["current_user_blocked_by_specified_user"] as? Bool {
            if blocked {
                receivedFriendRequestState = .Blocked
            }
        }

        if let
            sendInfo = data["sent"] as? JSONDictionary,
            state = sendInfo["state"] as? String {
                if let state = FriendRequest.State(rawValue: state) {
                    sentFriendRequestState = state
                }
        }

        if let blocked = data["current_user_blocked_by_specified_user"] as? Bool {
            if blocked {
                sentFriendRequestState = .Blocked
            }
        }

        return (isFriend, receivedFriendRequestState, receivedFriendRequestID, sentFriendRequestState)
    }

    let resource = authJsonResource(path: "/v1/friend_requests/with_user/\(user.userID)", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func acceptFriendRequestWithID(friendRequestID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let requestParameters = [
        "id": friendRequestID,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        println("acceptFriendRequestWithID: \(data)")

        if let state = data["state"] as? String {
            if let state = FriendRequest.State(rawValue: state) {
                if state == .Accepted {
                    return true
                }
            }
        }

        return false
    }

    let resource = authJsonResource(path: "/v1/friend_requests/received/\(friendRequestID)/accept", method: .PATCH, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func rejectFriendRequestWithID(friendRequestID: String, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let requestParameters = [
        "id": friendRequestID,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        println("rejectFriendRequestWithID: \(data)")

        if let state = data["state"] as? String {
            if let state = FriendRequest.State(rawValue: state) {
                if state == .Rejected {
                    return true
                }
            }
        }

        return false
    }

    let resource = authJsonResource(path: "/v1/friend_requests/received/\(friendRequestID)/reject", method: .PATCH, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Friendships

private func headFriendships(failureHandler failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/friendships", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func moreFriendships(inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/friendships", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
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
            return NSLocalizedString("Match", comment: "")
        }
    }

    var nameWithArrow: String {
        return name + " ▾"
    }
}

struct DiscoveredUser: Hashable {

    struct SocialAccountProvider {
        let name: String
        let enabled: Bool
    }

    let id: String
    let username: String?
    let nickname: String
    let introduction: String?
    let avatarURLString: String
    let badge: String?

    let createdUnixTime: NSTimeInterval
    let lastSignInUnixTime: NSTimeInterval

    let longitude: Double
    let latitude: Double
    let distance: Double?

    let masterSkills: [Skill]
    let learningSkills: [Skill]

    let socialAccountProviders: [SocialAccountProvider]
    
    let recently_updated_provider: String?

    var hashValue: Int {
        return id.hashValue
    }

    var isMe: Bool {
        if let myUserID = YepUserDefaults.userID.value {
            return id == myUserID
        }
        
        return false
    }

    static func fromUser(user: User) -> DiscoveredUser {

         return DiscoveredUser(id: user.userID, username: user.username, nickname: user.nickname, introduction: user.introduction, avatarURLString: user.avatarURLString, badge: user.badge, createdUnixTime: user.createdUnixTime, lastSignInUnixTime: user.lastSignInUnixTime, longitude: user.longitude, latitude: user.latitude, distance: 0, masterSkills: [], learningSkills: [], socialAccountProviders: [], recently_updated_provider: nil)
    }
}

func ==(lhs: DiscoveredUser, rhs: DiscoveredUser) -> Bool {
    return lhs.id == rhs.id
}

let parseDiscoveredUser: JSONDictionary -> DiscoveredUser? = { userInfo in
    if let
        id = userInfo["id"] as? String,
        nickname = userInfo["nickname"] as? String,
        avatarInfo = userInfo["avatar"] as? JSONDictionary,
        avatarURLString = avatarInfo["url"] as? String,
        createdUnixTime = userInfo["created_at"] as? NSTimeInterval,
        lastSignInUnixTime = userInfo["last_sign_in_at"] as? NSTimeInterval,
        longitude = userInfo["longitude"] as? Double,
        latitude = userInfo["latitude"] as? Double {

            let username = userInfo["username"] as? String
            let introduction = userInfo["introduction"] as? String
            let badge = userInfo["badge"] as? String
            let distance = userInfo["distance"] as? Double

            var masterSkills: [Skill] = []
            if let masterSkillsData = userInfo["master_skills"] as? [JSONDictionary] {
                masterSkills = skillsFromSkillsData(masterSkillsData)
            }

            var learningSkills: [Skill] = []
            if let learningSkillsData = userInfo["learning_skills"] as? [JSONDictionary] {
                learningSkills = skillsFromSkillsData(learningSkillsData)
            }

            var socialAccountProviders = Array<DiscoveredUser.SocialAccountProvider>()
            if let socialAccountProvidersInfo = userInfo["providers"] as? [String: Bool] {
                for (name, enabled) in socialAccountProvidersInfo {
                    let provider = DiscoveredUser.SocialAccountProvider(name: name, enabled: enabled)

                    socialAccountProviders.append(provider)
                }
            }
            
            var recently_updated_provider: String?
            
            if let updated_provider = userInfo["recently_updated_provider"] as? String{
                recently_updated_provider = updated_provider
            }

            let discoverUser = DiscoveredUser(id: id, username: username, nickname: nickname, introduction: introduction, avatarURLString: avatarURLString, badge: badge, createdUnixTime: createdUnixTime, lastSignInUnixTime: lastSignInUnixTime, longitude: longitude, latitude: latitude, distance: distance, masterSkills: masterSkills, learningSkills: learningSkills, socialAccountProviders: socialAccountProviders, recently_updated_provider: recently_updated_provider)

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

func discoverUsers(masterSkillIDs masterSkillIDs: [String], learningSkillIDs: [String], discoveredUserSortStyle: DiscoveredUserSortStyle, inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: [DiscoveredUser] -> Void) {
    
    let requestParameters: [String: AnyObject] = [
        "master_skills": masterSkillIDs,
        "learning_skills": learningSkillIDs,
        "sort": discoveredUserSortStyle.rawValue,
        "page": page,
        "per_page": perPage,
    ]
    
    //let parse = parseDiscoveredUsers
    let parse: JSONDictionary -> [DiscoveredUser]? = { data in

        // 只离线第一页
        if page == 1 {
            if let realm = try? Realm() {
                if let offlineData = try? NSJSONSerialization.dataWithJSONObject(data, options: []) {

                    let offlineJSON = OfflineJSON(name: OfflineJSONName.DiscoveredUsers.rawValue, data: offlineData)

                    let _ = try? realm.write {
                        realm.add(offlineJSON, update: true)
                    }
                }
            }
        }
        
        return parseDiscoveredUsers(data)
    }
    
    let resource = authJsonResource(path: "/v1/user/discover", method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func discoverUsersWithSkill(skillID: String, ofSkillSet skillSet: SkillSet, inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: [DiscoveredUser] -> Void) {

    let requestParameters: [String: AnyObject] = [
        "page": page,
        "per_page": perPage,
    ]

    let parse = parseDiscoveredUsers

    let resource = authJsonResource(path: "/v1/\(skillSet.serverPath)/\(skillID)/users", method: .GET, requestParameters: requestParameters as JSONDictionary, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func searchUsersByQ(q: String, failureHandler: FailureHandler?, completion: [DiscoveredUser] -> Void) {

    let requestParameters = [
        "q": q
    ]

    let parse = parseDiscoveredUsers

    let resource = authJsonResource(path: "/v1/users/search", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func friendships(failureHandler failureHandler: FailureHandler?, completion: [JSONDictionary] -> Void) {

    headFriendships(failureHandler: failureHandler) { result in

        guard let page1Friendships = result["friendships"] as? [JSONDictionary] else {
            completion([])
            return
        }

        guard let count = result["count"] as? Int, currentPage = result["current_page"] as? Int, perPage = result["per_page"] as? Int else {

            println("friendships not paging info.")

            completion(page1Friendships)
            return
        }

        if count <= currentPage * perPage {
            completion(page1Friendships)

        } else {
            var friendships = [JSONDictionary]()

            friendships += page1Friendships

            // We have more friends

            var allGood = true
            let downloadGroup = dispatch_group_create()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                dispatch_group_enter(downloadGroup)

                moreFriendships(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    allGood = false
                    failureHandler?(reason: reason, errorMessage: errorMessage)
                    dispatch_group_leave(downloadGroup)

                }, completion: { result in
                    if let currentPageFriendships = result["friendships"] as? [JSONDictionary] {
                        friendships += currentPageFriendships
                    }
                    dispatch_group_leave(downloadGroup)
                })
            }

            dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                if allGood {
                    completion(friendships)
                }
            }
        }
    }
}

// MARK: - Groups

func shareURLStringOfGroupWithGroupID(groupID: String, failureHandler: FailureHandler?, completion: String -> Void) {

    let parse: JSONDictionary -> String? = { data in

        if let URLString = data["url"] as? String {
            return URLString
        }

        return nil
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/share", method: .POST, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func groupWithGroupID(groupID groupID: String, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {

    let parse: JSONDictionary -> JSONDictionary? = { data in
       return data
    }

    let resource = authJsonResource(path: "/v1/circles/\(groupID)", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func joinGroup(groupID groupID: String, failureHandler: FailureHandler?, completion: () -> Void) {
    
    let parse: JSONDictionary -> Void? = { data in
        return
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/join", method: .POST, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func leaveGroup(groupID groupID: String, failureHandler: FailureHandler?, completion: () -> Void) {
    
    let parse: JSONDictionary -> Void? = { data in
        return
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/leave", method: .DELETE, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func meIsMemberOfGroup(groupID groupID: String, failureHandler: FailureHandler?, completion: (Bool) -> Void) {

    let parse: JSONDictionary -> Bool? = { data in

        guard let isMember = data["exist"] as? Bool else {
            return nil
        }

        return isMember
    }

    let resource = authJsonResource(path: "/v1/circles/\(groupID)/check_me_exist", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func headGroups(failureHandler failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": 1,
        "per_page": 30,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/circles", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func moreGroups(inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    let requestParameters = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/circles", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func groups(failureHandler failureHandler: FailureHandler?, completion: [JSONDictionary] -> Void) {

    return headGroups(failureHandler: failureHandler, completion: { result in

        guard let page1Groups = result["circles"] as? [JSONDictionary] else {
            completion([])
            return
        }

        guard let count = result["count"] as? Int, currentPage = result["current_page"] as? Int, perPage = result["per_page"] as? Int else {

            println("groups not paging info.")

            completion(page1Groups)
            return
        }

        if count <= currentPage * perPage {
            completion(page1Groups)

        } else {
            var groups = [JSONDictionary]()

            groups += page1Groups

            // We have more groups

            var allGood = true
            let downloadGroup = dispatch_group_create()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                dispatch_group_enter(downloadGroup)

                moreGroups(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    failureHandler?(reason: reason, errorMessage: errorMessage)

                    allGood = false
                    dispatch_group_leave(downloadGroup)

                }, completion: { result in
                    if let currentPageGroups = result["circles"] as? [JSONDictionary] {
                        groups += currentPageGroups
                    }
                    dispatch_group_leave(downloadGroup)
                })
            }

            dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                if allGood {
                    completion(groups)
                }
            }
        }
    })
}

// MARK: - UploadAttachment

struct UploadAttachment {

    enum Type: String {
        case Message = "Message"
        case Feed = "Topic"
    }
    let type: Type

    enum Source {
        case Data(NSData)
        case FilePath(String)
    }
    let source: Source

    let fileExtension: FileExtension

    let metaDataString: String?
}

struct UploadedAttachment {
    let ID: String
    let URLString: String
}

func tryUploadAttachment(uploadAttachment: UploadAttachment, failureHandler: FailureHandler?, completion: UploadedAttachment -> Void) {

    guard let token = YepUserDefaults.v1AccessToken.value else {
        println("uploadAttachment no token")
        return
    }

    let headers: [String: String] = [
        "Authorization": "Token token=\"\(token)\"",
    ]

    var parameters: [String: String] = [
        "attachable_type": uploadAttachment.type.rawValue,
    ]

    if let metaDataString = uploadAttachment.metaDataString {
        parameters["metadata"] = metaDataString
    }

    let name = "file"
    let filename = "file.\(uploadAttachment.fileExtension.rawValue)"
    let mimeType = uploadAttachment.fileExtension.mimeType

    Alamofire.upload(.POST, yepBaseURL.absoluteString + "/v1/attachments", headers: headers, multipartFormData: { multipartFormData in

        for parameter in parameters {
            multipartFormData.appendBodyPart(data: parameter.1.dataUsingEncoding(NSUTF8StringEncoding)!, name: parameter.0)
        }

        switch uploadAttachment.source {

        case .Data(let data):
            multipartFormData.appendBodyPart(data: data, name: name, fileName: filename, mimeType: mimeType)

        case .FilePath(let filePath):
            multipartFormData.appendBodyPart(fileURL: NSURL(fileURLWithPath: filePath), name: name, fileName: filename, mimeType: mimeType)
        }

    }, encodingCompletion: { encodingResult in
        //println("encodingResult: \(encodingResult)")

        switch encodingResult {

        case .Success(let upload, _, _):

            upload.responseJSON(completionHandler: { response in

                guard let
                    data = response.data,
                    json = decodeJSON(data)
                else {
                    failureHandler?(reason: .CouldNotParseJSON, errorMessage: nil)
                    return
                }

                println("tryUploadAttachment json: \(json)")

                guard let
                    attachmentID = json["id"] as? String,
                    fileInfo = json["file"] as? JSONDictionary,
                    attachmentURLString = fileInfo["url"] as? String
                else {
                    failureHandler?(reason: .CouldNotParseJSON, errorMessage: nil)
                    return
                }

                let uploadedAttachment = UploadedAttachment(ID: attachmentID, URLString: attachmentURLString)

                completion(uploadedAttachment)
            })
            
        case .Failure(let encodingError):
            
            failureHandler?(reason: .Other(nil), errorMessage: "\(encodingError)")
        }
    })
}

// MARK: - Messages
struct LastMessageRead {
    let unixTime: NSTimeInterval
    let messageID: String
}

func lastMessageReadByRecipient(recipient: Recipient, failureHandler: FailureHandler?,  completion: (LastMessageRead?) -> Void) {
    
    let parse: JSONDictionary -> (LastMessageRead?)? = { data in

        println("lastMessageReadByRecipient: \(data)")

        guard let lastReadUnixTime = data["last_read_at"] as? NSTimeInterval, lastReadMessageID = data["last_read_id"] as? String else {
            return nil
        }

        return LastMessageRead(unixTime: lastReadUnixTime, messageID: lastReadMessageID)
    }
    
    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForBatchMarkAsRead)/\(recipient.ID)/messages/sent_last_read_at", method: .GET, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func officialMessages(completion completion: Int -> Void) {

    let parse: JSONDictionary -> Int? = { data in

        var messagesCount: Int = 0

        if let messagesData = data["official_messages"] as? [JSONDictionary], senderInfo = data["sender"] as? JSONDictionary, senderID = senderInfo["id"] as? String {

            // 没有消息的话，人就不要加入了

            if messagesData.isEmpty {
                return 0
            }

            // Yep Team

            guard let realm = try? Realm() else {
                return 0
            }

            var sender = userWithUserID(senderID, inRealm: realm)

            if sender == nil {
                let newUser = User()

                newUser.userID = senderID

                newUser.friendState = UserFriendState.Yep.rawValue

                let _ = try? realm.write {
                    realm.add(newUser)
                }

                sender = newUser
            }

            // 确保有 Conversation

            if let sender = sender {

                if sender.conversation == nil {

                    let newConversation = Conversation()

                    newConversation.type = ConversationType.OneToOne.rawValue
                    newConversation.withFriend = sender

                    let _ = try? realm.write {
                        realm.add(newConversation)
                    }
                }
            }

            let _ = try? realm.write {
                updateUserWithUserID(senderID, useUserInfo: senderInfo, inRealm: realm)
            }

            // 存储消息列表

            for messageInfo in messagesData {

                if let messageID = messageInfo["id"] as? String {

                    var message = messageWithMessageID(messageID, inRealm: realm)

                    if message == nil {
                        let newMessage = Message()
                        newMessage.messageID = messageID

                        if let updatedUnixTime = messageInfo["updated_at"] as? NSTimeInterval {
                            newMessage.createdUnixTime = updatedUnixTime
                        }

                        let _ = try? realm.write {
                            realm.add(newMessage)
                        }
                        
                        message = newMessage
                    }

                    if let message = message {
                        let _ = try? realm.write {
                            message.fromFriend = sender
                        }

                        if let conversation = sender?.conversation {
                            let _ = try? realm.write {

                                // 先同步 read 状态
                                if let sender = message.fromFriend where sender.isMe {
                                    message.readed = true

                                } else if let state = messageInfo["state"] as? String where state == "read" {
                                    message.readed = true
                                }

                                // 再设置 conversation，调节 hasUnreadMessages 需要判定 readed
                                message.conversation = conversation

                                // 最后纪录消息余下的 detail 信息（其中设置 mentionedMe 需要 conversation）
                                recordMessageWithMessageID(messageID, detailInfo: messageInfo, inRealm: realm)
                            }

                            messagesCount++
                        }
                    }
                }
            }
        }

        return messagesCount
    }

    let resource = authJsonResource(path: "/v1/official_messages", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
}

func unreadMessages(failureHandler failureHandler: FailureHandler?, completion: [JSONDictionary] -> Void) {

    guard let realm = try? Realm() else { return }

    let latestMessage = realm.objects(Message).sorted("createdUnixTime", ascending: false).first

    unreadMessagesAfterMessageWithID(latestMessage?.messageID, failureHandler: failureHandler, completion: completion)
}

private func headUnreadMessagesAfterMessageWithID(messageID: String?, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {

    var parameters: [String: AnyObject] = [
        "page": 1,
        "per_page": 30,
    ]

    if let messageID = messageID {
        parameters["min_id"] = messageID
    }

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/messages", method: .GET, requestParameters: parameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func moreUnreadMessagesAfterMessageWithID(messageID: String?, inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {

    var parameters: [String: AnyObject] = [
        "page": page,
        "per_page": perPage,
    ]

    if let messageID = messageID {
        parameters["min_id"] = messageID
    }

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/messages", method: .GET, requestParameters: parameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func unreadMessagesAfterMessageWithID(messageID: String?, failureHandler: FailureHandler?, completion: [JSONDictionary] -> Void) {

    headUnreadMessagesAfterMessageWithID(messageID, failureHandler: failureHandler, completion: { result in

        guard let page1UnreadMessagesData = result["messages"] as? [JSONDictionary] else {
            completion([])
            return
        }

        guard let count = result["count"] as? Int, currentPage = result["current_page"] as? Int, perPage = result["per_page"] as? Int else {

            println("unreadMessagesAfterMessageWithID not paging info.")

            completion(page1UnreadMessagesData)
            return
        }

        if count <= currentPage * perPage {
            //println("page1UnreadMessagesData: \(page1UnreadMessagesData)")
            completion(page1UnreadMessagesData)

        } else {
            var unreadMessagesData = [JSONDictionary]()

            unreadMessagesData += page1UnreadMessagesData

            // We have more unreadMessages

            let downloadGroup = dispatch_group_create()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                dispatch_group_enter(downloadGroup)

                moreUnreadMessagesAfterMessageWithID(messageID, inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    failureHandler?(reason: reason, errorMessage: errorMessage)

                    dispatch_group_leave(downloadGroup)

                }, completion: { result in
                    if let currentPageUnreadMessagesData = result["messages"] as? [JSONDictionary] {
                        unreadMessagesData += currentPageUnreadMessagesData
                    }
                    dispatch_group_leave(downloadGroup)
                })
            }

            dispatch_group_notify(downloadGroup, dispatch_get_main_queue()) {
                completion(unreadMessagesData)
            }
        }
    })
}

/*
func unreadMessages(failureHandler failureHandler: ((Reason, String?) -> Void)?, completion: [JSONDictionary] -> Void) {

    let parse: JSONDictionary -> [JSONDictionary]? = { data in

        //println("unreadMessages data: \(data)")

        guard let conversationsData = data["conversations"] as? [JSONDictionary] else {
            return nil
        }

        guard let realm = try? Realm() else {
            return nil
        }

        var messages = [JSONDictionary]()

        for conversationInfo in conversationsData {
            if let type = conversationInfo["conversation_type"] as? String, recipientInfo = conversationInfo["conversation"] as? JSONDictionary, unreadMessagesCount = conversationInfo["count"] as? Int  {

                var recipient: Recipient?
                switch type {
                case ConversationType.OneToOne.nameForServer:
                    if let userID = recipientInfo["id"] as? String {
                        recipient = Recipient(type: .OneToOne, ID: userID)
                    }
                case ConversationType.Group.nameForServer:
                    if let groupID = recipientInfo["id"] as? String {
                        recipient = Recipient(type: .Group, ID: groupID)
                    }
                default:
                    break
                }

                if let recipient = recipient, conversation = recipient.conversationInRealm(realm) {
                    let _ = try? realm.write {
                        conversation.unreadMessagesCount = unreadMessagesCount
                    }
                }
            }

            if let messagesData = conversationInfo["messages"] as? [JSONDictionary] {
                messages += messagesData
            }
        }

        return messages
    }

    let resource = authJsonResource(path: "/v1/messages/unread", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
}
*/

struct Recipient {

    let type: ConversationType
    let ID: String

    func conversationInRealm(realm: Realm) -> Conversation? {

        switch type {

        case .OneToOne:
            if let user = userWithUserID(ID, inRealm: realm) {
                return user.conversation
            }

        case .Group:
            if let group = groupWithGroupID(ID, inRealm: realm) {
                return group.conversation
            }
        }

        return nil
    }
}

enum TimeDirection {

    case Future(minMessageID: String)
    case Past(maxMessageID: String)
    case None

    var messageAge: MessageAge {
        switch self {
        case .Past:
            return .Old
        default:
            return .New
        }
    }
}

func messagesFromRecipient(recipient: Recipient, withTimeDirection timeDirection: TimeDirection, failureHandler: FailureHandler?, completion: (messageIDs: [String]) -> Void) {

    var requestParameters = [
        "recipient_type": recipient.type.nameForServer,
        "recipient_id": recipient.ID,
    ]

    switch timeDirection {
    case .Future(let minMessageID):
        requestParameters["min_id"] = minMessageID
    case .Past(let maxMessageID):
        requestParameters["max_id"] = maxMessageID
    case .None:
        break
    }

    let parse: JSONDictionary -> [String]? = { data in

        //println("messagesFromRecipient: \(data)")

        guard let
            unreadMessagesData = data["messages"] as? [JSONDictionary],
            realm = try? Realm() else {
                return []
        }

        //println("messagesFromRecipient: \(recipient), \(unreadMessagesData.count)")

        var messageIDs = [String]()

        realm.beginWrite()

        for messageInfo in unreadMessagesData {
            syncMessageWithMessageInfo(messageInfo, messageAge: timeDirection.messageAge, inRealm: realm) { _messageIDs in
                messageIDs += _messageIDs
            }
        }

        let _ = try? realm.commitWrite()

        return messageIDs
    }

    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForServer)/\(recipient.ID)/messages", method: .GET, requestParameters: requestParameters, parse: parse )

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func createMessageWithMessageInfo(messageInfo: JSONDictionary, failureHandler: FailureHandler?, completion: (messageID: String) -> Void) {

    println("Message info \(messageInfo)")

    func apiCreateMessageWithMessageInfo(messageInfo: JSONDictionary, failureHandler: ((Reason, String?) -> Void)?, completion: (messageID: String) -> Void) {

        let parse: JSONDictionary -> String? = { data in
            if let messageID = data["id"] as? String {
                return messageID
            }
            return nil
        }

        guard let
            recipientType = messageInfo["recipient_type"] as? String,
            recipientID = messageInfo["recipient_id"] as? String else {
                return
        }

        let resource = authJsonResource(path: "/v1/\(recipientType)/\(recipientID)/messages", method: .POST, requestParameters: messageInfo, parse: parse)

        if let failureHandler = failureHandler {
            apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
        } else {
            apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
        }
    }

    if
        FayeService.sharedManager.client.connected && false, // 暂时不用 Faye 发送消息
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
                            failureHandler(reason: .CouldNotParseJSON, errorMessage: "Faye Created Message Error")
                        } else {
                            defaultFailureHandler(reason: Reason.CouldNotParseJSON, errorMessage: "Faye Created Message Error")
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
                                failureHandler(reason: .CouldNotParseJSON, errorMessage: "Faye Created Message Error")
                            } else {
                                defaultFailureHandler(reason: .CouldNotParseJSON, errorMessage: "Faye Created Message Error")
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

func sendText(text: String, toRecipient recipientID: String, recipientType: String, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {

    let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
        var moreInfo = info
        moreInfo["text_content"] = text
        return moreInfo
    }
    createAndSendMessageWithMediaType(.Text, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendImageInFilePath(filePath: String?, orFileData fileData: NSData?, metaData: String?, toRecipient recipientID: String, recipientType: String, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.Image, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendAudioInFilePath(filePath: String?, orFileData fileData: NSData?, metaData: String?, toRecipient recipientID: String, recipientType: String, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.Audio, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendVideoInFilePath(filePath: String?, orFileData fileData: NSData?, metaData: String?, toRecipient recipientID: String, recipientType: String, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.Video, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

func sendLocationWithLocationInfo(locationInfo: PickLocationViewController.Location.Info, toRecipient recipientID: String, recipientType: String, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {

    let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
        var moreInfo = info
        moreInfo["longitude"] = locationInfo.coordinate.longitude
        moreInfo["latitude"] = locationInfo.coordinate.latitude
        if let locationName = locationInfo.name {
            moreInfo["text_content"] = locationName
        }
        return moreInfo
    }

    createAndSendMessageWithMediaType(.Location, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

let afterCreatedMessageSoundEffect: YepSoundEffect = YepSoundEffect(soundName: "bub3")

func createAndSendMessageWithMediaType(mediaType: MessageMediaType, inFilePath filePath: String?, orFileData fileData: NSData?, metaData: String?, fillMoreInfo: (JSONDictionary -> JSONDictionary)?, toRecipient recipientID: String, recipientType: String, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {
    // 因为 message_id 必须来自远端，线程无法切换，所以这里暂时没用 realmQueue // TOOD: 也许有办法

    guard let realm = try? Realm() else {
        return
    }

    let message = Message()

    println("send newMessage.createdUnixTime: \(message.createdUnixTime)")

    // 确保本地刚创建的消息比任何已有的消息都要新
    if let latestMessage = realm.objects(Message).sorted("createdUnixTime", ascending: true).last {
        if message.createdUnixTime < latestMessage.createdUnixTime {
            message.createdUnixTime = latestMessage.createdUnixTime + YepConfig.Message.localNewerTimeInterval
            println("adjust message.createdUnixTime")
        }
    }

    message.mediaType = mediaType.rawValue
    message.downloadState = MessageDownloadState.Downloaded.rawValue
    message.readed = true // 自己的消息，天然已读

    let _ = try? realm.write {
        realm.add(message)
    }

    // 消息来自于自己

    if let me = tryGetOrCreateMeInRealm(realm) {
        let _ = try? realm.write {
            message.fromFriend = me
        }
    }

    // 消息的 Conversation，没有就创建

    var conversation: Conversation? = nil

    let _ = try? realm.write {

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
            message.conversation = conversation

            tryCreateSectionDateMessageInConversation(conversation, beforeMessage: message, inRealm: realm) { sectionDateMessage in
                realm.add(sectionDateMessage)
            }
        }
    }

    var messageInfo: JSONDictionary = [
        "recipient_id": recipientID,
        "recipient_type": recipientType,
        "media_type": mediaType.description,
    ]

    if let fillMoreInfo = fillMoreInfo {
        messageInfo = fillMoreInfo(messageInfo)
    }

    let _ = try? realm.write {

        if let textContent = messageInfo["text_content"] as? String {
            message.textContent = textContent
        }

        if let
            longitude = messageInfo["longitude"] as? Double,
            latitude = messageInfo["latitude"] as? Double {

                let coordinate = Coordinate()
                coordinate.safeConfigureWithLatitude(latitude, longitude: longitude)
                
                message.coordinate = coordinate
        }
    }

    // 发出之前就显示 Message
    afterCreatedMessage(message)

    // 做个音效
    afterCreatedMessageSoundEffect.play()

    // 下面开始真正的消息发送
    sendMessage(message, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, failureHandler: { (reason, errorMessage) in

        failureHandler?(reason: reason, errorMessage: errorMessage)

        dispatch_async(dispatch_get_main_queue()) {

            let realm = message.realm

            let _ = try? realm?.write {
                message.sendState = MessageSendState.Failed.rawValue
            }

            NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
        }

    }, completion: completion)
}

func sendMessage(message: Message, inFilePath filePath: String?, orFileData fileData: NSData?, metaData: String?, fillMoreInfo: (JSONDictionary -> JSONDictionary)?, toRecipient recipientID: String, recipientType: String, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {

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

            createMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: { messageID in

                dispatch_async(dispatch_get_main_queue()) {
                    let realm = message.realm

                    let _ = try? realm?.write {
                        message.messageID = messageID
                        message.sendState = MessageSendState.Successed.rawValue
                    }

                    //println("new messageID: \(messageID)")

                    completion(success: true)

                    NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                }
            })

        default:

            var source: UploadAttachment.Source! // TODO: refactor
            if let filePath = filePath {
                source = .FilePath(filePath)
            }
            if let fileData = fileData {
                source = .Data(fileData)
            }

            let uploadAttachment = UploadAttachment(type: .Message, source: source, fileExtension: mediaType.fileExtension!, metaDataString: metaData)

            tryUploadAttachment(uploadAttachment, failureHandler: failureHandler, completion: { uploadedAttachment in

                messageInfo["attachment_id"] = uploadedAttachment.ID

                let doCreateMessage = {
                    createMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: { messageID in
                        dispatch_async(dispatch_get_main_queue()) {
                            let realm = message.realm
                            let _ = try? realm?.write {
                                message.messageID = messageID
                                message.sendState = MessageSendState.Successed.rawValue
                            }

                            completion(success: true)

                            NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                        }
                    })
                }

                doCreateMessage()
            })
        }
    }
}

func resendMessage(message: Message, failureHandler: FailureHandler?, completion: (success: Bool) -> Void) {

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

            // before resend, recover MessageSendState

            dispatch_async(dispatch_get_main_queue()) {

                let realm = message.realm

                let _ = try? realm?.write {
                    message.sendState = MessageSendState.NotSend.rawValue
                }

                NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
            }

            // also, if resend failed, we need set MessageSendState

            let resendFailureHandler: FailureHandler = { reason, errorMessage in

                failureHandler?(reason: reason, errorMessage: errorMessage)

                dispatch_async(dispatch_get_main_queue()) {

                    let realm = message.realm

                    let _ = try? realm?.write {
                        message.sendState = MessageSendState.Failed.rawValue
                    }

                    NSNotificationCenter.defaultCenter().postNotificationName(MessageNotification.MessageStateChanged, object: nil)
                }
            }

            switch messageMediaType {

            case .Text:

                let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
                    var moreInfo = info
                    moreInfo["text_content"] = message.textContent
                    return moreInfo
                }

                sendMessage(message, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, failureHandler: resendFailureHandler, completion: completion)

            case .Image:
                let filePath = NSFileManager.yepMessageImageURLWithName(message.localAttachmentName)?.path

                sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.mediaMetaData?.string, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, failureHandler: resendFailureHandler, completion: completion)

            case .Video:
                let filePath = NSFileManager.yepMessageVideoURLWithName(message.localAttachmentName)?.path

                sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.mediaMetaData?.string, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, failureHandler: resendFailureHandler, completion: completion)

            case .Audio:
                let filePath = NSFileManager.yepMessageAudioURLWithName(message.localAttachmentName)?.path

                sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.mediaMetaData?.string, fillMoreInfo: nil, toRecipient: recipientID, recipientType: recipientType, failureHandler: resendFailureHandler, completion: completion)

            case .Location:
                if let coordinate = message.coordinate {
                    let fillMoreInfo: JSONDictionary -> JSONDictionary = { info in
                        var moreInfo = info
                        moreInfo["longitude"] = coordinate.longitude
                        moreInfo["latitude"] = coordinate.latitude
                        return moreInfo
                    }
                    
                    sendMessage(message, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipientID, recipientType: recipientType, failureHandler: resendFailureHandler, completion: completion)
                }
                
            default:
                break
            }
    }
}

func batchMarkAsReadOfMessagesToRecipient(recipient: Recipient, beforeMessage: Message, failureHandler: FailureHandler?, completion: () -> Void) {

    let state = UIApplication.sharedApplication().applicationState
    if state != .Active {
        return
    }

    let requestParameters = [
        "max_id": beforeMessage.messageID
    ]

    let parse: JSONDictionary -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForBatchMarkAsRead)/\(recipient.ID)/messages/batch_mark_as_read", method: .PATCH, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func deleteMessageFromServer(messageID messageID: String, failureHandler: FailureHandler?, completion: () -> Void) {

    let parse: JSONDictionary -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/messages/\(messageID)", method: .DELETE, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func refreshAttachmentWithID(attachmentID: String, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {

    let requestParameters = [
        "ids": [attachmentID],
    ]

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return (data["attachments"] as? [JSONDictionary])?.first
    }

    let resource = authJsonResource(path: "/v1/attachments/refresh_url", method: .PATCH, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Feeds

enum FeedSortStyle: String {

    case Distance = "distance"
    case Time = "time"
    case Match = "default"
    
    var name: String {
        switch self {
        case .Distance:
            return NSLocalizedString("Nearby", comment: "")
        case .Time:
            return NSLocalizedString("Time", comment: "")
        case .Match:
            return NSLocalizedString("Match", comment: "")
        }
    }
    
    var nameWithArrow: String {
        return name + " ▾"
    }
}

struct DiscoveredAttachment {

    //let kind: AttachmentKind
    let metadata: String
    let URLString: String

    var image: UIImage?

    var isTemporary: Bool {
        return image != nil
    }

    var thumbnailImage: UIImage? {

        guard (metadata as NSString).length > 0 else {
            return nil
        }

        if let data = metadata.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let metaDataInfo = decodeJSON(data) {
                if let thumbnailString = metaDataInfo[YepConfig.MetaData.thumbnailString] as? String {
                    if let imageData = NSData(base64EncodedString: thumbnailString, options: NSDataBase64DecodingOptions(rawValue: 0)) {
                        let image = UIImage(data: imageData)
                        return image
                    }
                }
            }
        }

        return nil
    }

    static func fromJSONDictionary(json: JSONDictionary) -> DiscoveredAttachment? {
        guard let
            //kindString = json["kind"] as? String,
            //kind = AttachmentKind(rawValue: kindString),
            metadata = json["metadata"] as? String,
            fileInfo = json["file"] as? JSONDictionary,
            URLString = fileInfo["url"] as? String else {
                return nil
        }

        //return DiscoveredAttachment(kind: kind, metadata: metadata, URLString: URLString)
        return DiscoveredAttachment(metadata: metadata, URLString: URLString, image: nil)
    }
}

func ==(lhs: DiscoveredFeed, rhs: DiscoveredFeed) -> Bool {
    return lhs.id == rhs.id
}

struct DiscoveredFeed: Hashable {
    
    var hashValue: Int {
        return id.hashValue
    }

    let id: String
    let allowComment: Bool
    let kind: FeedKind

    var hasSocialImage: Bool {
        switch kind {
        case .DribbbleShot:
            return true
        default:
            return false
        }
    }

    var hasMapImage: Bool {

        switch kind {
        case .Location:
            return true
        default:
            return false
        }
    }

    let createdUnixTime: NSTimeInterval
    let updatedUnixTime: NSTimeInterval

    let creator: DiscoveredUser
    let body: String

    struct GithubRepo {
        let ID: Int
        let name: String
        let fullName: String
        let description: String
        let URLString: String
        let createdUnixTime: NSTimeInterval

        static func fromJSONDictionary(json: JSONDictionary) -> GithubRepo? {
            guard let
                ID = json["repo_id"] as? Int,
                name = json["name"] as? String,
                fullName = json["full_name"] as? String,
                description = json["description"] as? String,
                URLString = json["url"] as? String,
                createdUnixTime = json["created_at"] as? NSTimeInterval else {
                    return nil
            }

            return GithubRepo(ID: ID, name: name, fullName: fullName, description: description, URLString: URLString, createdUnixTime: createdUnixTime)
        }
    }

    struct DribbbleShot {
        let ID: Int
        let title: String
        let description: String?
        let imageURLString: String
        let htmlURLString: String
        let createdUnixTime: NSTimeInterval

        static func fromJSONDictionary(json: JSONDictionary) -> DribbbleShot? {
            guard let
                ID = json["shot_id"] as? Int,
                title = json["title"] as? String,
                imageURLString = json["media_url"] as? String,
                htmlURLString = json["url"] as? String,
                createdUnixTime = json["created_at"] as? NSTimeInterval else {
                    return nil
            }
            
            let description = json["description"] as? String

            return DribbbleShot(ID: ID, title: title, description: description, imageURLString: imageURLString, htmlURLString: htmlURLString, createdUnixTime: createdUnixTime)
        }
    }

    struct AudioInfo {
        let feedID: String
        let URLString: String
        let metaData: NSData
        let duration: NSTimeInterval
        let sampleValues: [CGFloat]

        static func fromJSONDictionary(json: JSONDictionary, feedID: String) -> AudioInfo? {
            guard let
                fileInfo = json["file"] as? JSONDictionary,
                URLString = fileInfo["url"] as? String,
                metaDataString = json["metadata"] else {
                    return nil
            }

            if let metaData = metaDataString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                if let metaDataInfo = decodeJSON(metaData) {

                    guard let
                        duration = metaDataInfo[YepConfig.MetaData.audioDuration] as? NSTimeInterval,
                        sampleValues = metaDataInfo[YepConfig.MetaData.audioSamples] as? [CGFloat] else {
                            return nil
                    }

                    return AudioInfo(feedID: feedID, URLString: URLString, metaData: metaData, duration: duration, sampleValues: sampleValues)
                }
            }

            return nil
        }
    }

    struct LocationInfo {

        let name: String
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees

        var coordinate: CLLocationCoordinate2D {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        static func fromJSONDictionary(json: JSONDictionary) -> LocationInfo? {
            guard let
                name = json["place"] as? String,
                latitude = json["latitude"] as? CLLocationDegrees,
                longitude = json["longitude"] as? CLLocationDegrees else {
                    return nil
            }

            return LocationInfo(name: name, latitude: latitude, longitude: longitude)
        }
    }

    struct OpenGraphInfo: OpenGraphInfoType {

        let URL: NSURL

        let siteName: String
        let title: String
        let infoDescription: String
        let thumbnailImageURLString: String

        static func fromJSONDictionary(json: JSONDictionary) -> OpenGraphInfo? {
            guard let
                URLString = json["url"] as? String,
                URL = NSURL(string: URLString),
                siteName = json["site_name"] as? String,
                title = json["title"] as? String,
                infoDescription = json["description"] as? String,
                thumbnailImageURLString = json["image_url"] as? String else {
                    return nil
            }

            return OpenGraphInfo(URL: URL, siteName: siteName, title: title, infoDescription: infoDescription, thumbnailImageURLString: thumbnailImageURLString)
        }
    }

    enum Attachment {
        case Images([DiscoveredAttachment])
        case Github(GithubRepo)
        case Dribbble(DribbbleShot)
        case Audio(AudioInfo)
        case Location(LocationInfo)
        case URL(OpenGraphInfo)
    }

    let attachment: Attachment?

    var imageAttachments: [DiscoveredAttachment]? {
        if let attachment = attachment, case let .Images(attachments) = attachment {
            return attachments
        }

        return nil
    }

    var imageAttachmentsCount: Int {
        return imageAttachments?.count ?? 0
    }

    let distance: Double?

    let skill: Skill?
    let groupID: String
    var messagesCount: Int

    var uploadingErrorMessage: String? = nil

    var timeString: String {
        let timeString = "\(NSDate(timeIntervalSince1970: createdUnixTime).timeAgo)"
        return timeString
    }

    var timeAndDistanceString: String {

        let timeString = "\(NSDate(timeIntervalSince1970: createdUnixTime).timeAgo)"

        var distanceString: String?
        if let distance = distance {
            if distance < 1 {
                distanceString = NSLocalizedString("Nearby", comment: "")
            } else {
                distanceString = "\(distance.format(".1")) km"
            }
        }

        if let distanceString = distanceString {
            return timeString + "  ∙  " + distanceString
        } else {
            return timeString
        }
    }

    static func fromFeedInfo(feedInfo: JSONDictionary, groupInfo: JSONDictionary?) -> DiscoveredFeed? {

        //println("feedInfo: \(feedInfo)")

        guard let
            id = feedInfo["id"] as? String,
            allowComment = feedInfo["allow_comment"] as? Bool,
            kindString = feedInfo["kind"] as? String,
            kind = FeedKind(rawValue: kindString),
            createdUnixTime = feedInfo["created_at"] as? NSTimeInterval,
            updatedUnixTime = feedInfo["updated_at"] as? NSTimeInterval,
            creatorInfo = feedInfo["user"] as? JSONDictionary,
            body = feedInfo["body"] as? String,
            messagesCount = feedInfo["message_count"] as? Int else {
                return nil
        }

        var groupInfo = groupInfo

        if groupInfo == nil {
            groupInfo = feedInfo["circle"] as? JSONDictionary
        }

        guard let creator = parseDiscoveredUser(creatorInfo), groupID = groupInfo?["id"] as? String else {
            return nil
        }

        let distance = feedInfo["distance"] as? Double

        var attachment: DiscoveredFeed.Attachment?

        switch kind {

        case .URL:
            if let
                openGraphInfosData = feedInfo["attachments"] as? [JSONDictionary],
                openGraphInfoDict = openGraphInfosData.first,
                openGraphInfo = DiscoveredFeed.OpenGraphInfo.fromJSONDictionary(openGraphInfoDict) {
                    attachment = .URL(openGraphInfo)
            }

        case .Image:

            let attachmentsData = feedInfo["attachments"] as? [JSONDictionary]
            let attachments = attachmentsData?.map({ DiscoveredAttachment.fromJSONDictionary($0) }).flatMap({ $0 }) ?? []

            attachment = .Images(attachments)

        case .GithubRepo:

            if let
                githubReposData = feedInfo["attachments"] as? [JSONDictionary],
                githubRepoInfo = githubReposData.first,
                githubRepo = DiscoveredFeed.GithubRepo.fromJSONDictionary(githubRepoInfo) {
                    attachment = .Github(githubRepo)
            }

        case .DribbbleShot:

            if let
                dribbbleShotsData = feedInfo["attachments"] as? [JSONDictionary],
                dribbbleShotInfo = dribbbleShotsData.first,
                dribbbleShot = DiscoveredFeed.DribbbleShot.fromJSONDictionary(dribbbleShotInfo) {
                    attachment = .Dribbble(dribbbleShot)
            }

        case .Audio:

            if let
                audioInfosData = feedInfo["attachments"] as? [JSONDictionary],
                _audioInfo = audioInfosData.first,
                audioInfo = DiscoveredFeed.AudioInfo.fromJSONDictionary(_audioInfo, feedID: id) {
                    attachment = .Audio(audioInfo)
            }

        case .Location:

            if let
                locationInfosData = feedInfo["attachments"] as? [JSONDictionary],
                _locationInfo = locationInfosData.first,
                locationInfo = DiscoveredFeed.LocationInfo.fromJSONDictionary(_locationInfo) {
                    attachment = .Location(locationInfo)
            }

        default:
            break
        }

        var skill: Skill?
        if let skillInfo = feedInfo["skill"] as? JSONDictionary {
            skill = Skill.fromJSONDictionary(skillInfo)
        }

        return DiscoveredFeed(id: id, allowComment: allowComment, kind: kind, createdUnixTime: createdUnixTime, updatedUnixTime: updatedUnixTime, creator: creator, body: body, attachment: attachment, distance: distance, skill: skill, groupID: groupID, messagesCount: messagesCount, uploadingErrorMessage: nil)
    }
}

let parseFeed: JSONDictionary -> DiscoveredFeed? = { data in
    
    //println("feedsData: \(data)")
    
    if let feedInfo = data["topic"] as? JSONDictionary, groupInfo = data["circle"] as? JSONDictionary {
        return DiscoveredFeed.fromFeedInfo(feedInfo, groupInfo: groupInfo)
    }
    
    return nil
}

let parseFeeds: JSONDictionary -> [DiscoveredFeed]? = { data in

    //println("feedsData: \(data)")

    if let feedsData = data["topics"] as? [JSONDictionary] {
        return feedsData.map({ DiscoveredFeed.fromFeedInfo($0, groupInfo: nil) }).flatMap({ $0 })
    }

    return []
}

func discoverFeedsWithSortStyle(sortStyle: FeedSortStyle, skill: Skill?, pageIndex: Int, perPage: Int, maxFeedID: String?, failureHandler: ((Reason, String?) -> Void)?, completion: [DiscoveredFeed] -> Void) {

    var requestParameters: JSONDictionary = [
        "sort": sortStyle.rawValue,
        "page": pageIndex,
        "per_page": perPage,
    ]

    if let skill = skill {
        requestParameters["skill_id"] = skill.id
    }

    if let maxFeedID = maxFeedID {
        requestParameters["max_id"] = maxFeedID
    }

    let parse: JSONDictionary -> [DiscoveredFeed]? = { data in

        // 只离线第一页，且无 skill
        if pageIndex == 1 && skill == nil {
            if let realm = try? Realm() {
                if let offlineData = try? NSJSONSerialization.dataWithJSONObject(data, options: []) {

                    let offlineJSON = OfflineJSON(name: OfflineJSONName.Feeds.rawValue, data: offlineData)

                    let _ = try? realm.write {
                        realm.add(offlineJSON, update: true)
                    }
                }
            }
        }

        return parseFeeds(data)
    }

    let resource = authJsonResource(path: "/v1/topics/discover", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func feedWithSharedToken(token: String, failureHandler: FailureHandler?, completion: DiscoveredFeed -> Void) {

    let requestParameters: JSONDictionary = [
        "token": token,
    ]

    let parse = parseFeed
    
    let resource = authJsonResource(path: "/v1/circles/shared_messages", method: .GET, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func myFeedsAtPageIndex(pageIndex: Int, perPage: Int, failureHandler: FailureHandler?, completion: [DiscoveredFeed] -> Void) {

    let requestParameters: JSONDictionary = [
        "page": pageIndex,
        "per_page": perPage,
    ]

    let parse = parseFeeds

    let resource = authJsonResource(path: "/v1/topics", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func feedsOfUser(userID: String, pageIndex: Int, perPage: Int, failureHandler: FailureHandler?,completion: [DiscoveredFeed] -> Void) {

    let requestParameters: JSONDictionary = [
        "page": pageIndex,
        "per_page": perPage,
    ]

    let parse = parseFeeds

    let resource = authJsonResource(path: "/v1/users/\(userID)/topics", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

enum FeedKind: String {
    case Text = "text"
    case URL = "web_page"
    case Image = "image"
    case Video = "video"
    case Audio = "audio"
    case Location = "location"

    case AppleMusic = "apple_music"
    case AppleMovie = "apple_movie"
    case AppleEBook = "apple_ebook"

    case GithubRepo = "github"
    case DribbbleShot = "dribbble"
    //case InstagramMedia = "instagram"

    var accountName: String? {
        switch self {
        case .GithubRepo: return "github"
        case .DribbbleShot: return "dribbble"
        //case .InstagramMedia: return "instagram"
        default: return nil
        }
    }

    var needBackgroundUpload: Bool {
        switch self {
        case .Image:
            return true
        case .Audio:
            return true
        default:
            return false
        }
    }

    var needParseOpenGraph: Bool {
        switch self {
        case .Text:
            return true
        default:
            return false
        }
    }
}

func createFeedWithKind(kind: FeedKind, message: String, attachments: [JSONDictionary]?, coordinate: CLLocationCoordinate2D?, skill: Skill?, allowComment: Bool, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {

    var requestParameters: JSONDictionary = [
        "kind": kind.rawValue,
        "body": message,
        "latitude": 0,
        "longitude": 0,
        "allow_comment": allowComment,
    ]

    if let coordinate = coordinate {
        requestParameters["latitude"] = coordinate.latitude
        requestParameters["longitude"] = coordinate.longitude
    }

    if let skill = skill {
        requestParameters["skill_id"] = skill.id
    }

    if let attachments = attachments {
        requestParameters["attachments"] = attachments
    }

    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/topics", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func deleteFeedWithFeedID(feedID: String, failureHandler: FailureHandler?, completion: () -> Void) {

    let parse: JSONDictionary -> ()? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/topics/\(feedID)", method: .DELETE, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Social Work

struct TokensOfSocialAccounts {
    let githubToken: String?
    let dribbbleToken: String?
    let instagramToken: String?
}

func tokensOfSocialAccounts(failureHandler failureHandler: ((Reason, String?) -> Void)?, completion: TokensOfSocialAccounts -> Void) {

    let parse: JSONDictionary -> TokensOfSocialAccounts? = { data in

        //println("tokensOfSocialAccounts data: \(data)")

        let githubToken = data["github"] as? String
        let dribbbleToken = data["dribbble"] as? String
        let instagramToken = data["instagram"] as? String

        return TokensOfSocialAccounts(githubToken: githubToken, dribbbleToken: dribbbleToken, instagramToken: instagramToken)
    }

    let resource = authJsonResource(path: "/v1/user/provider_tokens", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

func authURLRequestWithURL(url: NSURL) -> NSURLRequest {
    
    let request = NSMutableURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 0)
    
    if let token = YepUserDefaults.v1AccessToken.value {
        request.setValue("Token token=\"\(token)\"", forHTTPHeaderField: "Authorization")
    }

    return request
}

func socialAccountWithProvider(provider: String, failureHandler: FailureHandler?, completion: JSONDictionary -> Void) {
    
    let parse: JSONDictionary -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/v1/user/\(provider)", method: .GET, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
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

func githubWorkOfUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: GithubWork -> Void) {

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

            repos.sortInPlace { $0.stargazersCount > $1.stargazersCount }

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

    let resource = authJsonResource(path: "/v1/users/\(userID)/github", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

struct DribbbleWork {

    struct Shot {

        struct Images {
            let hidpi: String?
            let normal: String
            let teaser: String
        }

        let title: String
        let description: String?
        let htmlURLString: String
        let images: Images
        let likesCount: Int
        let commentsCount: Int
    }
    let shots: [Shot]

    let username: String
    let userURLString: String
}

func dribbbleWorkOfUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: DribbbleWork -> Void) {

    let parse: JSONDictionary -> DribbbleWork? = { data in

        //println("dribbbleData:\(data)")

        if let
            shotsData = data["shots"] as? [JSONDictionary],
            userInfo = data["user"] as? JSONDictionary,
            username = userInfo["username"] as? String,
            userURLString = userInfo["html_url"] as? String {

                var shots = Array<DribbbleWork.Shot>()

                for shotInfo in shotsData {
                    if let
                        title = shotInfo["title"] as? String,
                        htmlURLString = shotInfo["html_url"] as? String,
                        imagesInfo = shotInfo["images"] as? JSONDictionary,
                        likesCount = shotInfo["likes_count"] as? Int,
                        commentsCount = shotInfo["comments_count"] as? Int {
                            if let
                                normal = imagesInfo["normal"] as? String,
                                teaser = imagesInfo["teaser"] as? String {
                                    
                                    let hidpi = imagesInfo["hidpi"] as? String
                                    
                                    let description = shotInfo["description"] as? String

                                    let images = DribbbleWork.Shot.Images(hidpi: hidpi, normal: normal, teaser: teaser)

                                    let shot = DribbbleWork.Shot(title: title, description: description, htmlURLString: htmlURLString, images: images, likesCount: likesCount, commentsCount: commentsCount)

                                    shots.append(shot)
                            }
                    }
                }

                return DribbbleWork(shots: shots, username: username, userURLString: userURLString)
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/dribbble", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

struct InstagramWork {

    struct Media {

        let ID: String
        let linkURLString: String

        struct Images {
            let lowResolution: String
            let standardResolution: String
            let thumbnail: String
        }
        let images: Images

        let likesCount: Int
        let commentsCount: Int

        let username: String
    }

    let medias: [Media]
}

func instagramWorkOfUserWithUserID(userID: String, failureHandler: FailureHandler?, completion: InstagramWork -> Void) {

    let parse: JSONDictionary -> InstagramWork? = { data in
        //println("instagramData:\(data)")

        if let mediaData = data["media"] as? [JSONDictionary] {

            var medias = Array<InstagramWork.Media>()

            for mediaInfo in mediaData {
                if let
                    ID = mediaInfo["id"] as? String,
                    linkURLString = mediaInfo["link"] as? String,
                    imagesInfo = mediaInfo["images"] as? JSONDictionary,
                    likesInfo = mediaInfo["likes"] as? JSONDictionary,
                    commentsInfo = mediaInfo["comments"] as? JSONDictionary,
                    userInfo = mediaInfo["user"] as? JSONDictionary {
                        if let
                            lowResolutionInfo = imagesInfo["low_resolution"] as? JSONDictionary,
                            standardResolutionInfo = imagesInfo["standard_resolution"] as? JSONDictionary,
                            thumbnailInfo = imagesInfo["thumbnail"] as? JSONDictionary,

                            lowResolution = lowResolutionInfo["url"] as? String,
                            standardResolution = standardResolutionInfo["url"] as? String,
                            thumbnail = thumbnailInfo["url"] as? String,

                            likesCount = likesInfo["count"] as? Int,
                            commentsCount = commentsInfo["count"] as? Int,

                            username = userInfo["username"] as? String {

                                let images = InstagramWork.Media.Images(lowResolution: lowResolution, standardResolution: standardResolution, thumbnail: thumbnail)

                                let media = InstagramWork.Media(ID: ID, linkURLString: linkURLString, images: images, likesCount: likesCount, commentsCount: commentsCount, username: username)

                                medias.append(media)
                        }
                }
            }

            return InstagramWork(medias: medias)
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/instagram", method: .GET, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

enum SocialWork {
    case Dribbble(DribbbleWork)
    case Instagram(InstagramWork)
}

// MARK: - Feedback

struct Feedback {
    let content: String
    let deviceInfo: String
}

func sendFeedback(feedback: Feedback, failureHandler: FailureHandler?, completion: Bool -> Void) {

    let requestParameters = [
        "content": feedback.content,
        "device_info": feedback.deviceInfo,
    ]

    let parse: JSONDictionary -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/feedbacks", method: .POST, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: Places

struct FoursquareVenue {
    let name: String

    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

func foursquareVenuesNearby(coordinate coordinate: CLLocationCoordinate2D, failureHandler: FailureHandler?, completion: [FoursquareVenue] -> Void) {

    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    let dateString = dateFormatter.stringFromDate(NSDate())

    let requestParameters = [
        "client_id": "NFMF2UV2X5BCADG2T5FE3BIORDPEDJA5JZVDWF0XXAZUX2AS",
        "client_secret": "UOGE0SCBWHV2JFXD5AFAIHOVTUSBQ3ERH4ALHU3WU3BSR4CN",
        "v": dateString,
        "ll": "\(coordinate.latitude),\(coordinate.longitude)"
    ]

    let parse: JSONDictionary -> [FoursquareVenue]? = { data in
        //println("foursquarePlacesNearby: \(data)")

        if let
            response = data["response"] as? JSONDictionary,
            venuesData = response["venues"] as? [JSONDictionary] {

                var venues = [FoursquareVenue]()

                for venueInfo in venuesData {
                    if let
                        name = venueInfo["name"] as? String,
                        locationInfo = venueInfo["location"] as? JSONDictionary,
                        latitude = locationInfo["lat"] as? CLLocationDegrees,
                        longitude = locationInfo["lng"] as? CLLocationDegrees {
                            let venue = FoursquareVenue(name: name, latitude: latitude, longitude: longitude)
                            venues.append(venue)
                    }
                }

                return venues
        }

        return []
    }

    let resource = jsonResource(path: "/v2/venues/search", method: .GET, requestParameters: requestParameters, parse: parse)

    let foursquareBaseURL = NSURL(string: "https://api.foursquare.com")!

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: foursquareBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: foursquareBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

// MARK: Mention

struct UsernamePrefixMatchedUser {
    let userID: String
    let username: String
    let nickname: String
    let avatarURLString: String?

    var mentionUsername: String {
        return "@" + username
    }
}

func usersMatchWithUsernamePrefix(usernamePrefix: String, failureHandler: FailureHandler?, completion: ([UsernamePrefixMatchedUser]) -> Void) {

    let requestParameters = [
        "q": usernamePrefix,
    ]

    let parse: JSONDictionary -> [UsernamePrefixMatchedUser]? = { data in
        println("usersMatchWithUsernamePrefix: \(data)")

        if let usersData = data["users"] as? [JSONDictionary] {
            let users: [UsernamePrefixMatchedUser] = usersData.map({ userInfo in
                guard let
                    userID = userInfo["id"] as? String,
                    username = userInfo["username"] as? String,
                    nickname = userInfo["nickname"] as? String,
                    avatarInfo = userInfo["avatar"] as? JSONDictionary
                    //avatarURLString = avatarInfo["thumb_url"] as? String
                else {
                    return nil
                }

                let avatarURLString = avatarInfo["thumb_url"] as? String

                return UsernamePrefixMatchedUser(userID: userID, username: username, nickname: nickname, avatarURLString: avatarURLString)
            }).flatMap({ $0 })

            return users
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/users/typeahead", method: .GET, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}


//
//  YepService.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import Foundation
import CoreLocation
import YepNetworking
import RealmSwift
import Alamofire

#if STAGING
public let yepHost = "park-staging.catchchatchina.com"
public let yepBaseURL = URL(string: "https://park-staging.catchchatchina.com/api")!
public let fayeBaseURL = URL(string: "wss://faye-staging.catchchatchina.com/faye")!
#else
public let yepHost = "soyep.com"
public let yepBaseURL = URL(string: "https://api.soyep.com")!
public let fayeBaseURL = URL(string: "wss://faye.catchchatchina.com/faye")!
#endif

func println(_ item: @autoclosure () -> Any) {
    #if DEBUG
        Swift.print(item())
    #endif
}

// Models

public struct LoginUser: CustomStringConvertible {

    public let accessToken: String
    public let userID: String
    public let username: String?
    public let nickname: String
    public let avatarURLString: String?
    public let pusherID: String

    public var description: String {
        return "LoginUser(accessToken: \(accessToken), userID: \(userID), username: \(username), nickname: \(nickname), avatarURLString: \(avatarURLString), pusherID: \(pusherID))"
    }

    static func fromJSONDictionary(_ data: JSONDictionary) -> LoginUser? {

        guard let accessToken = data["access_token"] as? String else { return nil }

        guard let user = data["user"] as? JSONDictionary else { return nil }
        guard let userID = user["id"] as? String else { return nil }
        guard let nickname = user["nickname"] as? String else { return nil }
        guard let pusherID = user["pusher_id"] as? String else { return nil }

        let username = user["username"] as? String
        let avatarURLString = user["avatar_url"] as? String

        return LoginUser(accessToken: accessToken, userID: userID, username: username, nickname: nickname, avatarURLString: avatarURLString, pusherID: pusherID)
    }
}

public func saveTokenAndUserInfoOfLoginUser(_ loginUser: LoginUser) {

    YepUserDefaults.userID.value = loginUser.userID
    YepUserDefaults.nickname.value = loginUser.nickname
    YepUserDefaults.avatarURLString.value = loginUser.avatarURLString
    YepUserDefaults.pusherID.value = loginUser.pusherID

    // NOTICE: 因为一些操作依赖于 accessToken 做检测，又可能依赖上面其他值，所以要放在最后赋值
    YepUserDefaults.v1AccessToken.value = loginUser.accessToken
}

public struct MobilePhone {

    public let areaCode: String
    public let number: String

    public var fullNumber: String {
        return "+" + areaCode + " " + number
    }

    public init(areaCode: String, number: String) {
        self.areaCode = areaCode
        self.number = number
    }
}

// MARK: - Register

public func validateMobilePhone(_ mobilePhone: MobilePhone, failureHandler: FailureHandler?, completion: @escaping ((Bool, String)) -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
    ]

    let parse: (JSONDictionary) -> (Bool, String)? = { data in
        println("validateMobilePhone: \(data)")
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

    let resource = jsonResource(path: "/v1/users/mobile_validate", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func registerMobilePhone(_ mobilePhone: MobilePhone, nickname: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "nickname": nickname,
        // 注册时不好提示用户访问位置，或许设置技能或用户利用位置查找好友时再提示并更新位置信息
        "longitude": YepUserDefaults.userCoordinateLongitude.value ?? 0,
        "latitude": YepUserDefaults.userCoordinateLatitude.value ?? 0,
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        if let state = data["state"] as? String {
            if state == "blocked" {
                return true
            }
        }

        return false
    }

    let resource = jsonResource(path: "/v1/registration/create", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func verifyMobilePhone(_ mobilePhone: MobilePhone, verifyCode: String, failureHandler: FailureHandler?, completion: @escaping (LoginUser) -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "token": verifyCode,
        "client": Config.clientType,
        "expiring": 0, // 永不过期
    ]

    let parse: (JSONDictionary) -> LoginUser? = { data in
        return LoginUser.fromJSONDictionary(data)
    }

    let resource = jsonResource(path: "/v1/registration/update", method: .put, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Skills

public struct SkillCategory {
    public let id: String
    public let name: String
    public let localName: String

    public let skills: [Skill]
}

public struct Skill: Hashable {

    public let category: SkillCategory?

    public var skillCategory: SkillCellSkill.Category? {
        if let category = category {
            return SkillCellSkill.Category(rawValue: category.name)
        }
        return nil
    }

    public let id: String
    public let name: String
    public let localName: String
    public let coverURLString: String?

    public init(category: SkillCategory?, id: String, name: String, localName: String, coverURLString: String?) {
        self.category = category
        self.id = id
        self.name = name
        self.localName = localName
        self.coverURLString = coverURLString
    }

    public var hashValue: Int {
        return id.hashValue
    }

    public static func fromJSONDictionary(_ skillInfo: JSONDictionary) -> Skill? {
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

public func ==(lhs: Skill, rhs: Skill) -> Bool {
    return lhs.id == rhs.id
}

public func skillsFromSkillsData(_ skillsData: [JSONDictionary]) -> [Skill] {
    var skills = [Skill]()

    for skillInfo in skillsData {

        if let skill = Skill.fromJSONDictionary(skillInfo) {
            skills.append(skill)
        }
    }

    return skills
}

public func allSkillCategories(failureHandler: FailureHandler?, completion: @escaping ([SkillCategory]) -> Void) {

    let parse: (JSONDictionary) -> [SkillCategory]? = { data in

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

    let resource = authJsonResource(path: "/v1/skill_categories", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public enum SkillSet: Int {
    case master
    case learning

    public var serverPath: String {
        switch self {
        case .master:
            return "master_skills"
        case .learning:
            return "learning_skills"
        }
    }

    public var name: String {
        switch self {
        case .master:
            return String.trans_titleMaster
        case .learning:
            return String.trans_titleLearning
        }
    }

    public var annotationText: String {
        switch self {
        case .master:
            return NSLocalizedString("What are you good at?", comment: "")
        case .learning:
            return NSLocalizedString("What are you learning?", comment: "")
        }
    }

    public var failedSelectSkillMessage: String {
        switch self {
        case .master:
            return NSLocalizedString("This skill already in another learning skills set!", comment: "")
        case .learning:
            return NSLocalizedString("This skill already in another master skills set!", comment: "")
        }
    }
}

public func addSkillWithSkillID(_ skillID: String, toSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "skill_id": skillID,
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        println("addSkill \(skillID)")
        return true
    }

    let resource = authJsonResource(path: "/v1/\(skillSet.serverPath)", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func addSkill(_ skill: Skill, toSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    addSkillWithSkillID(skill.id, toSkillSet: skillSet, failureHandler: failureHandler, completion: completion)
}

public func deleteSkillWithID(_ skillID: String, fromSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/\(skillSet.serverPath)/\(skillID)", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func deleteSkill(_ skill: Skill, fromSkillSet skillSet: SkillSet, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    deleteSkillWithID(skill.id, fromSkillSet: skillSet, failureHandler: failureHandler, completion: completion)
}

public func updateCoverOfSkillWithSkillID(_ skillID: String, coverURLString: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "cover_url": coverURLString,
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/skills/\(skillID)", method: .patch, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - User

public func userInfoOfUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {
    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func discoverUserByUsername(_ username: String, failureHandler: FailureHandler?, completion: @escaping (DiscoveredUser) -> Void) {

    let parse: (JSONDictionary) -> DiscoveredUser? = { data in

        return parseDiscoveredUser(data)
    }

    let resource = authJsonResource(path: "/v1/users/\(username)/profile", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// 自己的信息
public func userInfo(failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {
    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/user", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func updateMyselfWithInfo(_ info: JSONDictionary, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    // nickname
    // avatar_url
    // username
    // latitude
    // longitude

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/v1/user", method: .patch, requestParameters: info, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func updateAvatarWithImageData(_ imageData: Data, failureHandler: FailureHandler?, completion: @escaping (String) -> Void) {

    guard let token = YepUserDefaults.v1AccessToken.value else {
        println("updateAvatarWithImageData no token")
        return
    }

    let headers: [String: String] = [
        "Authorization": "Token token=\"\(token)\"",
    ]

    let filename = "avatar.jpg"
    let url = URL(string: yepBaseURL.absoluteString + "/v1/user/set_avatar")!

    Alamofire.upload(multipartFormData: { multipartFormData in

        multipartFormData.append(imageData, withName: "avatar", fileName: filename, mimeType: "image/jpeg")

    }, to: url, method: .patch, headers: headers, encodingCompletion: { encodingResult in

        switch encodingResult {

        case .success(let upload, _, _):

            upload.responseJSON(completionHandler: { response in

                guard
                    let data = response.data,
                    let json = decodeJSON(data),
                    let avatarInfo = json["avatar"] as? JSONDictionary,
                    let avatarURLString = avatarInfo["url"] as? String else {
                        failureHandler?(.couldNotParseJSON, "failed parse JSON in updateAvatarWithImageData")
                        return
                }

                completion(avatarURLString)
            })

        case .failure(let encodingError):

            let failureHandler: FailureHandler = { (reason, errorMessage) in
                defaultFailureHandler(reason, errorMessage)
                failureHandler?(reason, errorMessage)
            }
            failureHandler(.other(nil), "\(encodingError)")
        }
    })
}

public enum VerifyCodeMethod: String {
    case sms = "sms"
    case call = "call"
}

public func requestSendVerifyCodeOfMobilePhone(_ mobilePhone: MobilePhone, useMethod method: VerifyCodeMethod, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "method": method.rawValue,
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }

    let resource = jsonResource(path: "/v1/sms_verification_codes", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func requestSendVerifyCodeOfNewMobilePhone(_ mobilePhone: MobilePhone, useMethod method: VerifyCodeMethod, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "method": method.rawValue,
    ]

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/user/send_update_mobile_code", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func confirmNewMobilePhone(_ mobilePhone: MobilePhone, withVerifyCode verifyCode: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "token": verifyCode,
    ]

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/user/update_mobile", method: .patch, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func loginByMobilePhone(_ mobilePhone: MobilePhone, withVerifyCode verifyCode: String, failureHandler: FailureHandler?, completion: @escaping (LoginUser) -> Void) {

    println("User login type is \(Config.clientType)")
    
    let requestParameters: JSONDictionary = [
        "phone_code": mobilePhone.areaCode,
        "mobile": mobilePhone.number,
        "verify_code": verifyCode,
        "client": Config.clientType,
        "expiring": 0, // 永不过期
    ]

    let parse: (JSONDictionary) -> LoginUser? = { data in
        return LoginUser.fromJSONDictionary(data)
    }

    let resource = jsonResource(path: "/v1/auth/token_by_mobile", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func logout(failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/auth/logout", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func disableNotificationFromUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/dnd", method: .post, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func enableNotificationFromUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/dnd", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func disableNotificationFromCircleWithCircleID(_ circleID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {
    
    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(circleID)/dnd", method: .post, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func enableNotificationFromCircleWithCircleID(_ circleID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {
    
    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(circleID)/dnd", method: .delete, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func headBlockedUsers(failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/blocked_users", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func moreBlockedUsers(inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/blocked_users", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func blockedUsersByMe(failureHandler: FailureHandler?, completion: @escaping ([DiscoveredUser]) -> Void) {

    let parse: ([JSONDictionary]) -> [DiscoveredUser] = { blockedUsersData in

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

        guard let count = result["count"] as? Int, let currentPage = result["current_page"] as? Int, let perPage = result["per_page"] as? Int else {

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

            let downloadGroup = DispatchGroup()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                downloadGroup.enter()

                moreBlockedUsers(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    failureHandler?(reason, errorMessage)

                    downloadGroup.leave()

                    }, completion: { result in
                        if let currentPageBlockedUsers = result["blocked_users"] as? [JSONDictionary] {
                            blockedUsers += currentPageBlockedUsers
                        }
                        downloadGroup.leave()
                })
            }

            downloadGroup.notify(queue: DispatchQueue.main) {
                completion(parse(blockedUsers))
            }
        }
    })
}

public func blockUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "user_id": userID
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/blocked_users", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func unblockUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let parse: (JSONDictionary) -> Bool? = { data in
        return true
    }

    let resource = authJsonResource(path: "/v1/blocked_users/\(userID)", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func settingsForUser(userID: String, failureHandler: FailureHandler?, completion: @escaping (_ blocked: Bool, _ doNotDisturb: Bool) -> Void) {

    let parse: (JSONDictionary) -> (Bool, Bool)? = { data in

        if let
            blocked = data["blocked"] as? Bool,
            let doNotDisturb = data["dnd"] as? Bool {
                return (blocked, doNotDisturb)
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/settings_with_current_user", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func settingsForGroup(groupID: String, failureHandler: FailureHandler?, completion: @escaping (_ doNotDisturb: Bool) -> Void) {
    
    let parse: (JSONDictionary) -> (Bool)? = { data in
        
        if let
            doNotDisturb = data["dnd"] as? Bool {
                return doNotDisturb
        }
        
        return nil
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/dnd", method: .get, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Conversations

public func myConversations(maxMessageID: String?, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    var requestParameters: JSONDictionary = [
        "per_page": 30,
    ]

    if let maxMessageID = maxMessageID {
        requestParameters["max_id"] = maxMessageID
    }

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/conversations", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func clearHistoryOfConversationWithRecipient(_ recipient: Recipient, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForServer)/\(recipient.ID)/messages/clear_history", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func deleteConversationWithRecipient(_ recipient: Recipient, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForServer)/\(recipient.ID)/messages/delete_conversation", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Contacts

public func searchUsersByMobile(_ mobile: String, failureHandler: FailureHandler?, completion: @escaping ([JSONDictionary]) -> Void) {
    
    let requestParameters: JSONDictionary = [
        "q": mobile
    ]
    
    let parse: (JSONDictionary) -> [JSONDictionary]? = { data in
        if let users = data["users"] as? [JSONDictionary] {
            return users
        }
        return []
    }
    
    let resource = authJsonResource(path: "/v1/users/search", method: .get, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public typealias UploadContact = [String: String]

public func friendsInContacts(_ contacts: [UploadContact], failureHandler: FailureHandler?, completion: @escaping ([DiscoveredUser]) -> Void) {

    if
        let contactsData = try? JSONSerialization.data(withJSONObject: contacts, options: .prettyPrinted),
        let contactsString = String(data: contactsData, encoding: .utf8) {

            let requestParameters: JSONDictionary = [
                "contacts": contactsString
            ]

            let parse: (JSONDictionary) -> [DiscoveredUser]? = { data in
                if let registeredContacts = data["registered_users"] as? [JSONDictionary] {

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

            let resource = authJsonResource(path: "/v1/contacts/upload", method: .post, requestParameters: requestParameters, parse: parse)
            
            apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)

    } else {
        completion([])
    }
}

public enum ReportReason {

    case porno
    case advertising
    case scams
    case other(String)
}

extension ReportReason {

    var type: Int {
        switch self {
        case .porno:
            return 0
        case .advertising:
            return 1
        case .scams:
            return 2
        case .other:
            return 3
        }
    }
}

public func reportProfileUser(_ profileUser: ProfileUser, forReason reason: ReportReason, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let userID: String

    switch profileUser {
    case .discoveredUserType(let discoveredUser):
        userID = discoveredUser.id
    case .userType(let user):
        userID = user.userID
    }

    var requestParameters: JSONDictionary = [
        "report_type": reason.type
    ]

    switch reason {
    case .other(let description):
        requestParameters["reason"] = description
    default:
        break
    }

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/reports", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Report

public func reportFeedWithFeedID(_ feedID: String, forReason reason: ReportReason, failureHandler: FailureHandler?, completion: @escaping () -> Void) {
    
    var requestParameters: JSONDictionary = [
        "report_type": reason.type
    ]
    
    switch reason {
    case .other(let description):
        requestParameters["reason"] = description
    default:
        break
    }
    
    let parse: (JSONDictionary) -> Void? = { data in
        return
    }
    
    let resource = authJsonResource(path: "/v1/topics/\(feedID)/reports", method: .post, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func reportMessageWithMessageID(_ messageID: String, forReason reason: ReportReason, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    var requestParameters: JSONDictionary = [
        "report_type": reason.type
    ]

    switch reason {
    case .other(let description):
        requestParameters["reason"] = description
    default:
        break
    }

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/messages/\(messageID)/reports", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Friend Requests

public struct FriendRequest {

    public enum State: String {
        case none       = "none"
        case pending    = "pending"
        case accepted   = "accepted"
        case rejected   = "rejected"
        case blocked    = "blocked"
    }
}

public func sendFriendRequestToUser(_ user: User, failureHandler: FailureHandler?, completion: @escaping (FriendRequest.State) -> Void) {

    let requestParameters: JSONDictionary = [
        "friend_id": user.userID,
    ]

    let parse: (JSONDictionary) -> FriendRequest.State? = { data in

        if let state = data["state"] as? String {
            return FriendRequest.State(rawValue: state)
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/friend_requests", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func stateOfFriendRequestWithUser(_ user: User, failureHandler: FailureHandler?, completion: @escaping (_ isFriend: Bool,_ receivedFriendRequestSate: FriendRequest.State, _ receivedFriendRequestID: String, _ sentFriendRequestState: FriendRequest.State) -> Void) {

    let requestParameters: JSONDictionary = [
        "user_id": user.userID,
    ]

    let parse: (JSONDictionary) -> (Bool, FriendRequest.State, String, FriendRequest.State)? = { data in
        println("stateOfFriendRequestWithUser: \(data)")

        var isFriend = false
        var receivedFriendRequestState = FriendRequest.State.none
        var receivedFriendRequestID = ""
        var sentFriendRequestState = FriendRequest.State.none

        if let friend = data["friend"] as? Bool {
            isFriend = friend
        }

        if let
            receivedInfo = data["received"] as? JSONDictionary,
            let state = receivedInfo["state"] as? String,
            let ID = receivedInfo["id"] as? String {
                if let state = FriendRequest.State(rawValue: state) {
                    receivedFriendRequestState = state
                }

                receivedFriendRequestID = ID
        }

        if let blocked = data["current_user_blocked_by_specified_user"] as? Bool {
            if blocked {
                receivedFriendRequestState = .blocked
            }
        }

        if let
            sendInfo = data["sent"] as? JSONDictionary,
            let state = sendInfo["state"] as? String {
                if let state = FriendRequest.State(rawValue: state) {
                    sentFriendRequestState = state
                }
        }

        if let blocked = data["current_user_blocked_by_specified_user"] as? Bool {
            if blocked {
                sentFriendRequestState = .blocked
            }
        }

        return (isFriend, receivedFriendRequestState, receivedFriendRequestID, sentFriendRequestState)
    }

    let resource = authJsonResource(path: "/v1/friend_requests/with_user/\(user.userID)", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func acceptFriendRequestWithID(_ friendRequestID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "id": friendRequestID,
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        println("acceptFriendRequestWithID: \(data)")

        if let state = data["state"] as? String {
            if let state = FriendRequest.State(rawValue: state) {
                if state == .accepted {
                    return true
                }
            }
        }

        return false
    }

    let resource = authJsonResource(path: "/v1/friend_requests/received/\(friendRequestID)/accept", method: .patch, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func rejectFriendRequestWithID(_ friendRequestID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "id": friendRequestID,
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        println("rejectFriendRequestWithID: \(data)")

        if let state = data["state"] as? String {
            if let state = FriendRequest.State(rawValue: state) {
                if state == .rejected {
                    return true
                }
            }
        }

        return false
    }

    let resource = authJsonResource(path: "/v1/friend_requests/received/\(friendRequestID)/reject", method: .patch, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Friendships

private func headFriendships(failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": 1,
        "per_page": 100,
    ]

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/friendships", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func moreFriendships(inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/friendships", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public enum DiscoveredUserSortStyle: String {
    case distance   = "distance"
    case lastSignIn = "last_sign_in_at"
    case `default`  = "default"

    public var name: String {
        switch self {
        case .distance:
            return String.trans_titleNearby
        case .lastSignIn:
            return NSLocalizedString("Time", comment: "")
        case .default:
            return String.trans_titleMatch
        }
    }

    public var nameWithArrow: String {
        return name.yep_appendArrow()
    }
}

public struct DiscoveredUser: Hashable {

    public struct SocialAccountProvider {
        public let name: String
        public let enabled: Bool
    }

    public let id: String
    public let username: String?
    public let nickname: String
    public let introduction: String?
    public let avatarURLString: String
    public let badge: String?
    public let blogURLString: String?
    public let blogTitle: String?

    public let createdUnixTime: TimeInterval
    public let lastSignInUnixTime: TimeInterval

    public let longitude: Double
    public let latitude: Double
    public let distance: Double?

    public let masterSkills: [Skill]
    public let learningSkills: [Skill]

    public let socialAccountProviders: [SocialAccountProvider]
    
    public let recently_updated_provider: String?

    public var hashValue: Int {
        return id.hashValue
    }

    public var mentionedUsername: String? {
        if let username = username, !username.isEmpty {
            return "@\(username)"
        } else {
            return nil
        }
    }

    public var compositedName: String {
        if let username = username {
            return "\(nickname) @\(username)"
        } else {
            return nickname
        }
    }

    public var isMe: Bool {
        if let myUserID = YepUserDefaults.userID.value {
            return id == myUserID
        }
        
        return false
    }

    public static func fromUser(_ user: User) -> DiscoveredUser {

        return DiscoveredUser(id: user.userID, username: user.username, nickname: user.nickname, introduction: user.introduction, avatarURLString: user.avatarURLString, badge: user.badge, blogURLString: user.blogURLString, blogTitle: user.blogTitle, createdUnixTime: user.createdUnixTime, lastSignInUnixTime: user.lastSignInUnixTime, longitude: user.longitude, latitude: user.latitude, distance: 0, masterSkills: [], learningSkills: [], socialAccountProviders: [], recently_updated_provider: nil)
    }
}

public func ==(lhs: DiscoveredUser, rhs: DiscoveredUser) -> Bool {
    return lhs.id == rhs.id
}

public let parseDiscoveredUser: (JSONDictionary) -> DiscoveredUser? = { userInfo in

    if let
        id = userInfo["id"] as? String,
        let nickname = userInfo["nickname"] as? String,
        let avatarInfo = userInfo["avatar"] as? JSONDictionary,
        let avatarURLString = avatarInfo["url"] as? String,
        let createdUnixTime = userInfo["created_at"] as? TimeInterval,
        let lastSignInUnixTime = userInfo["last_sign_in_at"] as? TimeInterval,
        let longitude = userInfo["longitude"] as? Double,
        let latitude = userInfo["latitude"] as? Double {

            let username = userInfo["username"] as? String
            let introduction = userInfo["introduction"] as? String
            let badge = userInfo["badge"] as? String
            let blogURLString = userInfo["website_url"] as? String
            let blogTitle = userInfo["website_title"] as? String
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

        let discoverUser = DiscoveredUser(id: id, username: username, nickname: nickname, introduction: introduction, avatarURLString: avatarURLString, badge: badge, blogURLString: blogURLString, blogTitle: blogTitle, createdUnixTime: createdUnixTime, lastSignInUnixTime: lastSignInUnixTime, longitude: longitude, latitude: latitude, distance: distance, masterSkills: masterSkills, learningSkills: learningSkills, socialAccountProviders: socialAccountProviders, recently_updated_provider: recently_updated_provider)

            return discoverUser
    }

    println("failed parseDiscoveredUser userInfo: \(userInfo)")
    return nil
}

public let parseDiscoveredUsers: (JSONDictionary) -> [DiscoveredUser]? = { data in

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

public func discoverUsers(masterSkillIDs: [String], learningSkillIDs: [String], discoveredUserSortStyle: DiscoveredUserSortStyle, inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: @escaping ([DiscoveredUser]) -> Void) {
    
    let requestParameters: JSONDictionary = [
        "master_skills": masterSkillIDs,
        "learning_skills": learningSkillIDs,
        "sort": discoveredUserSortStyle.rawValue,
        "page": page,
        "per_page": perPage,
    ]
    
    //let parse = parseDiscoveredUsers
    let parse: (JSONDictionary) -> [DiscoveredUser]? = { data in

        // 只离线第一页
        if page == 1 {
            if let realm = try? Realm() {
                if let offlineData = try? JSONSerialization.data(withJSONObject: data, options: []) {

                    let offlineJSON = OfflineJSON(name: OfflineJSONName.discoveredUsers.rawValue, data: offlineData)

                    let _ = try? realm.write {
                        realm.add(offlineJSON, update: true)
                    }
                }
            }
        }
        
        return parseDiscoveredUsers(data)
    }
    
    let resource = authJsonResource(path: "/v1/user/discover", method: .get, requestParameters: requestParameters as JSONDictionary, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func discoverUsersWithSkill(_ skillID: String, ofSkillSet skillSet: SkillSet, inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: @escaping ([DiscoveredUser]) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": page,
        "per_page": perPage,
    ]

    let parse = parseDiscoveredUsers

    let resource = authJsonResource(path: "/v1/\(skillSet.serverPath)/\(skillID)/users", method: .get, requestParameters: requestParameters as JSONDictionary, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func searchUsersByQ(_ q: String, failureHandler: FailureHandler?, completion: @escaping ([DiscoveredUser]) -> Void) {

    let requestParameters: JSONDictionary = [
        "q": q
    ]

    let parse = parseDiscoveredUsers

    let resource = authJsonResource(path: "/v1/users/search", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func friendships(failureHandler: FailureHandler?, completion: @escaping ([JSONDictionary]) -> Void) {

    headFriendships(failureHandler: failureHandler) { result in

        guard let page1Friendships = result["friendships"] as? [JSONDictionary] else {
            completion([])
            return
        }

        guard let count = result["count"] as? Int, let currentPage = result["current_page"] as? Int, let perPage = result["per_page"] as? Int else {

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
            let downloadGroup = DispatchGroup()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                downloadGroup.enter()

                moreFriendships(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    allGood = false
                    failureHandler?(reason, errorMessage)
                    downloadGroup.leave()

                }, completion: { result in
                    if let currentPageFriendships = result["friendships"] as? [JSONDictionary] {
                        friendships += currentPageFriendships
                    }
                    downloadGroup.leave()
                })
            }

            downloadGroup.notify(queue: DispatchQueue.main) {
                if allGood {
                    completion(friendships)
                }
            }
        }
    }
}

public func unfriend(withUserID userID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let requestParameters: JSONDictionary = [
        "friend_id": userID,
    ]

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/unfriend_requests", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Groups

public func shareURLStringOfGroupWithGroupID(_ groupID: String, failureHandler: FailureHandler?, completion: @escaping (String) -> Void) {

    let parse: (JSONDictionary) -> String? = { data in

        if let URLString = data["url"] as? String {
            return URLString
        }

        return nil
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/share", method: .post, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func groupWithGroupID(groupID: String, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
       return data
    }

    let resource = authJsonResource(path: "/v1/circles/\(groupID)", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func joinGroup(groupID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {
    
    let parse: (JSONDictionary) -> Void? = { data in
        return
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/join", method: .post, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func leaveGroup(groupID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {
    
    let parse: (JSONDictionary) -> Void? = { data in
        return
    }
    
    let resource = authJsonResource(path: "/v1/circles/\(groupID)/leave", method: .delete, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func meIsMemberOfGroup(groupID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let parse: (JSONDictionary) -> Bool? = { data in

        guard let isMember = data["exist"] as? Bool else {
            return nil
        }

        return isMember
    }

    let resource = authJsonResource(path: "/v1/circles/\(groupID)/check_me_exist", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - UploadAttachment

public struct UploadAttachment {

    public enum `Type`: String {
        case message = "Message"
        case feed = "Topic"
    }
    public let type: Type

    public enum Source {
        case data(Data)
        case filePath(String)
    }
    public let source: Source

    public let fileExtension: FileExtension

    public let metaDataString: String?

    public init(type: Type, source: Source, fileExtension: FileExtension, metaDataString: String?) {
        self.type = type
        self.source = source
        self.fileExtension = fileExtension
        self.metaDataString = metaDataString
    }
}

public struct UploadedAttachment {
    public let ID: String
    public let URLString: String
}

public func tryUploadAttachment(_ uploadAttachment: UploadAttachment, failureHandler: FailureHandler?, completion: @escaping (UploadedAttachment) -> Void) {

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

    let url = URL(string: yepBaseURL.absoluteString + "/v1/attachments")!

    Alamofire.upload(multipartFormData: { multipartFormData in

        for (key, value) in parameters {
            multipartFormData.append(value.data(using: .utf8)!, withName: key)
        }

        switch uploadAttachment.source {

        case .data(let data):
            multipartFormData.append(data, withName: name, fileName: filename, mimeType: mimeType)

        case .filePath(let filePath):
            multipartFormData.append(URL(fileURLWithPath: filePath), withName: name, fileName: filename, mimeType: mimeType)
        }

    }, to: url, method: .post, headers: headers, encodingCompletion: { encodingResult in

        switch encodingResult {

        case .success(let upload, _, _):

            upload.responseJSON(completionHandler: { response in

                guard
                    let data = response.data,
                    let json = decodeJSON(data) else {
                        failureHandler?(.couldNotParseJSON, nil)
                        return
                }

                println("tryUploadAttachment json: \(json)")

                guard
                    let attachmentID = json["id"] as? String,
                    let fileInfo = json["file"] as? JSONDictionary,
                    let attachmentURLString = fileInfo["url"] as? String else {
                        failureHandler?(.couldNotParseJSON, nil)
                        return
                }

                let uploadedAttachment = UploadedAttachment(ID: attachmentID, URLString: attachmentURLString)
                
                completion(uploadedAttachment)
            })
            
        case .failure(let encodingError):
            
            failureHandler?(.other(nil), "\(encodingError)")
        }
    })
}

// MARK: - Messages
public struct LastMessageRead {
    public let unixTime: TimeInterval
    public let messageID: String
}

public func lastMessageReadByRecipient(_ recipient: Recipient, failureHandler: FailureHandler?,  completion: @escaping (LastMessageRead?) -> Void) {
    
    let parse: (JSONDictionary) -> (LastMessageRead?)? = { data in

        println("lastMessageReadByRecipient: \(data)")

        guard let lastReadUnixTime = data["last_read_at"] as? TimeInterval, let lastReadMessageID = data["last_read_id"] as? String else {
            return nil
        }

        return LastMessageRead(unixTime: lastReadUnixTime, messageID: lastReadMessageID)
    }
    
    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForBatchMarkAsRead)/\(recipient.ID)/messages/sent_last_read_at", method: .get, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func officialMessages(completion: @escaping (Int) -> Void) {

    let parse: (JSONDictionary) -> Int? = { data in

        var messagesCount: Int = 0

        if let messagesData = data["official_messages"] as? [JSONDictionary], let senderInfo = data["sender"] as? JSONDictionary, let senderID = senderInfo["id"] as? String {

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

                newUser.friendState = UserFriendState.yep.rawValue

                let _ = try? realm.write {
                    realm.add(newUser)
                }

                sender = newUser
            }

            // 确保有 Conversation

            if let sender = sender {

                if sender.conversation == nil {

                    let newConversation = Conversation()

                    newConversation.type = ConversationType.oneToOne.rawValue
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

                        if let createdUnixTime = messageInfo["created_at"] as? TimeInterval {
                            newMessage.createdUnixTime = createdUnixTime
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
                                if let sender = message.fromFriend, sender.isMe {
                                    message.readed = true

                                } else if let state = messageInfo["state"] as? String, state == "read" {
                                    message.readed = true
                                }

                                // 再设置 conversation，调节 hasUnreadMessages 需要判定 readed
                                if !conversation.hasUnreadMessages {
                                    if message.conversation == nil && message.readed == false && message.createdUnixTime > conversation.olderUpdatedUnixTime {
                                        conversation.hasUnreadMessages = true
                                        conversation.updatedUnixTime = message.createdUnixTime
                                    }
                                }
                                message.conversation = conversation

                                // 最后纪录消息余下的 detail 信息（其中设置 mentionedMe 需要 conversation）
                                recordMessageWithMessageID(messageID, detailInfo: messageInfo, inRealm: realm)
                            }

                            messagesCount += 1
                        }
                    }
                }
            }
        }

        return messagesCount
    }

    let resource = authJsonResource(path: "/v1/official_messages", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
}

public func unreadMessages(failureHandler: FailureHandler?, completion: @escaping ([JSONDictionary]) -> Void) {

    guard let realm = try? Realm() else { return }

    let latestMessage = latestValidMessageInRealm(realm)

    /*
    let _latestMessage = realm.objects(Message).sorted("createdUnixTime", ascending: false).first

    println("_latestMessage: \(_latestMessage?.messageID), \(_latestMessage?.createdUnixTime)")
    println("+latestMessage: \(latestMessage?.messageID), \(latestMessage?.createdUnixTime)")
    println("*now: \(NSDate().timeIntervalSince1970)")
     */

    unreadMessagesAfterMessageWithID(latestMessage?.messageID, failureHandler: failureHandler, completion: completion)
}

private func headUnreadMessagesAfterMessageWithID(_ messageID: String?, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    var parameters: JSONDictionary = [
        "page": 1,
        "per_page": 30,
    ]

    if let messageID = messageID {
        parameters["min_id"] = messageID
    }

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/messages", method: .get, requestParameters: parameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func moreUnreadMessagesAfterMessageWithID(_ messageID: String?, inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    var parameters: JSONDictionary = [
        "page": page,
        "per_page": perPage,
    ]

    if let messageID = messageID {
        parameters["min_id"] = messageID
    }

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/messages", method: .get, requestParameters: parameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func unreadMessagesAfterMessageWithID(_ messageID: String?, failureHandler: FailureHandler?, completion: @escaping ([JSONDictionary]) -> Void) {

    headUnreadMessagesAfterMessageWithID(messageID, failureHandler: failureHandler, completion: { result in

        guard let page1UnreadMessagesData = result["messages"] as? [JSONDictionary] else {
            completion([])
            return
        }

        guard let count = result["count"] as? Int, let currentPage = result["current_page"] as? Int, let perPage = result["per_page"] as? Int else {

            println("unreadMessagesAfterMessageWithID not paging info.")

            completion(page1UnreadMessagesData)
            return
        }

        if count <= currentPage * perPage {
            completion(page1UnreadMessagesData)

        } else {
            var unreadMessagesData = [JSONDictionary]()

            unreadMessagesData += page1UnreadMessagesData

            // We have more unreadMessages

            let downloadGroup = DispatchGroup()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                downloadGroup.enter()

                moreUnreadMessagesAfterMessageWithID(messageID, inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    failureHandler?(reason, errorMessage)

                    downloadGroup.leave()

                }, completion: { result in
                    if let currentPageUnreadMessagesData = result["messages"] as? [JSONDictionary] {
                        unreadMessagesData += currentPageUnreadMessagesData
                    }
                    downloadGroup.leave()
                })
            }

            downloadGroup.notify(queue: DispatchQueue.main) {
                completion(unreadMessagesData)
            }
        }
    })
}

public func ==(lhs: Recipient, rhs: Recipient) -> Bool {
    return lhs.ID == rhs.ID && lhs.type == rhs.type
}

public struct Recipient: Equatable {

    public let type: ConversationType
    public let ID: String

    public init(type: ConversationType, ID: String) {
        self.type = type
        self.ID = ID
    }

    public init?(info: JSONDictionary) {
        guard let typeNameForServer = info["recipient_type"] as? String else {
            return nil
        }
        guard let conversationType = ConversationType(nameForServer: typeNameForServer) else {
            return nil
        }
        guard let ID = info["recipient_id"] as? String else {
            return nil
        }
        self.type = conversationType
        self.ID = ID
    }

    public func conversationInRealm(_ realm: Realm) -> Conversation? {

        switch type {

        case .oneToOne:
            if let user = userWithUserID(ID, inRealm: realm) {
                return user.conversation
            }

        case .group:
            if let group = groupWithGroupID(ID, inRealm: realm) {
                return group.conversation
            }
        }

        return nil
    }
}

public enum TimeDirection {

    case future(minMessageID: String)
    case past(maxMessageID: String)
    case none

    public var messageAge: MessageAge {
        switch self {
        case .past:
            return .old
        default:
            return .new
        }
    }
}

public func messagesFromRecipient(_ recipient: Recipient, withTimeDirection timeDirection: TimeDirection, failureHandler: FailureHandler?, completion: @escaping (_ messageIDs: [String], _ noMore: Bool) -> Void) {

    var requestParameters: JSONDictionary = [
        "recipient_type": recipient.type.nameForServer,
        "recipient_id": recipient.ID,
    ]

    switch timeDirection {
    case .future(let minMessageID):
        requestParameters["min_id"] = minMessageID
    case .past(let maxMessageID):
        requestParameters["max_id"] = maxMessageID
    case .none:
        break
    }

    let parse: (JSONDictionary) -> ([String], Bool)? = { data in

        guard let
            unreadMessagesData = data["messages"] as? [JSONDictionary],
            let realm = try? Realm() else {
                return ([], true)
        }

        let count = unreadMessagesData.count
        let perPage = (data["per_page"] as? Int) ?? 100
        let noMore = (count == 0) || (count < perPage)

        println("messagesFromRecipient: \(recipient), \(unreadMessagesData.count)")

        var messageIDs = [String]()

        realm.beginWrite()

        for messageInfo in unreadMessagesData {
            syncMessageWithMessageInfo(messageInfo, messageAge: timeDirection.messageAge, inRealm: realm) { _messageIDs in
                messageIDs += _messageIDs
            }
        }

        let _ = try? realm.commitWrite()

        return (messageIDs, noMore)
    }

    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForServer)/\(recipient.ID)/messages", method: .get, requestParameters: requestParameters, parse: parse )

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func createMessageWithMessageInfo(_ messageInfo: JSONDictionary, failureHandler: FailureHandler?, completion: @escaping (_ messageID: String) -> Void) {

    println("Message info \(messageInfo)")

    func apiCreateMessageWithMessageInfo(_ messageInfo: JSONDictionary, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping (_ messageID: String) -> Void) {

        let parse: (JSONDictionary) -> String? = { data in
            if let messageID = data["id"] as? String {
                return messageID
            }
            return nil
        }

        guard let
            recipientType = messageInfo["recipient_type"] as? String,
            let recipientID = messageInfo["recipient_id"] as? String else {
                return
        }

        let resource = authJsonResource(path: "/v1/\(recipientType)/\(recipientID)/messages", method: .post, requestParameters: messageInfo, parse: parse)

        apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
    }

    apiCreateMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: completion)

    /*
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
    */
}

public func sendText(_ text: String, toRecipient recipient: Recipient, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {

    let fillMoreInfo: (JSONDictionary) -> JSONDictionary = { info in
        var moreInfo = info
        moreInfo["text_content"] = text
        return moreInfo
    }
    createAndSendMessageWithMediaType(.text, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipient, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

public func sendImageInFilePath(_ filePath: String?, orFileData fileData: Data?, metaData: String?, toRecipient recipient: Recipient, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.image, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipient, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

public func sendAudioInFilePath(_ filePath: String?, orFileData fileData: Data?, metaData: String?, toRecipient recipient: Recipient, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.audio, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipient, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

public func sendVideoInFilePath(_ filePath: String?, orFileData fileData: Data?, metaData: String?, toRecipient recipient: Recipient, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {

    createAndSendMessageWithMediaType(.video, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: nil, toRecipient: recipient, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

public func sendLocationWithLocationInfo(_ locationInfo: PickLocationViewControllerLocation.Info, toRecipient recipient: Recipient, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {

    let fillMoreInfo: (JSONDictionary) -> JSONDictionary = { info in
        var moreInfo = info
        moreInfo["longitude"] = locationInfo.coordinate.longitude
        moreInfo["latitude"] = locationInfo.coordinate.latitude
        if let locationName = locationInfo.name {
            moreInfo["text_content"] = locationName
        }
        return moreInfo
    }

    createAndSendMessageWithMediaType(.location, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipient, afterCreatedMessage: afterCreatedMessage, failureHandler: failureHandler, completion: completion)
}

public func createAndSendMessageWithMediaType(_ mediaType: MessageMediaType, inFilePath filePath: String?, orFileData fileData: Data?, metaData: String?, fillMoreInfo: ((JSONDictionary) -> JSONDictionary)?, toRecipient recipient: Recipient, afterCreatedMessage: (Message) -> Void, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {
    // 因为 message_id 必须来自远端，线程无法切换，所以这里暂时没用 realmQueue // TOOD: 也许有办法

    guard let realm = try? Realm() else {
        return
    }

    let message = Message()

    println("send newMessage.createdUnixTime: \(message.createdUnixTime)")

    // 确保本地刚创建的消息比任何已有的消息都要新
    if let latestMessage = realm.objects(Message.self).sorted(byProperty: "createdUnixTime", ascending: true).last {
        if message.createdUnixTime < latestMessage.createdUnixTime {
            message.createdUnixTime = latestMessage.createdUnixTime + Config.Message.localNewerTimeInterval
            println("adjust message.createdUnixTime")
        }
    }

    message.mediaType = mediaType.rawValue
    message.downloadState = MessageDownloadState.downloaded.rawValue
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

        switch recipient.type {
        case .oneToOne:
            if let withFriend = userWithUserID(recipient.ID, inRealm: realm) {
                conversation = withFriend.conversation
            }
        case .group:
            if let withGroup = groupWithGroupID(recipient.ID, inRealm: realm) {
                conversation = withGroup.conversation
            }
        }

        if conversation == nil {
            let newConversation = Conversation()

            newConversation.type = recipient.type.rawValue

            switch recipient.type {
            case .oneToOne:
                if let withFriend = userWithUserID(recipient.ID, inRealm: realm) {
                    newConversation.withFriend = withFriend
                }
            case .group:
                if let withGroup = groupWithGroupID(recipient.ID, inRealm: realm) {
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

            conversation.updatedUnixTime = NSDate().timeIntervalSince1970

            SafeDispatch.async {
                NotificationCenter.default.post(name: Config.NotificationName.changedFeedConversation, object: nil)
            }
        }
    }

    var messageInfo: JSONDictionary = [
        "recipient_id": recipient.ID,
        "recipient_type": recipient.type.nameForServer,
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
            let latitude = messageInfo["latitude"] as? Double {

                let coordinate = Coordinate()
                coordinate.safeConfigureWithLatitude(latitude, longitude: longitude)
                
                message.coordinate = coordinate
        }
    }

    // 发出之前就显示 Message
    afterCreatedMessage(message)

    // 做个音效
    Config.sentMessageSoundEffectAction?()

    // 下面开始真正的消息发送
    sendMessage(message, inFilePath: filePath, orFileData: fileData, metaData: metaData, fillMoreInfo: fillMoreInfo, toRecipient: recipient, failureHandler: { (reason, errorMessage) in

        failureHandler?(reason, errorMessage)

        SafeDispatch.async {

            let realm = message.realm

            let _ = try? realm?.write {
                message.sendState = MessageSendState.failed.rawValue
            }

            NotificationCenter.default.post(name: Config.NotificationName.messageStateChanged, object: nil)
        }

    }, completion: completion)
}

public func sendMessage(_ message: Message, inFilePath filePath: String?, orFileData fileData: Data?, metaData: String?, fillMoreInfo: ((JSONDictionary) -> JSONDictionary)?, toRecipient recipient: Recipient, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {

    guard let mediaType = MessageMediaType(rawValue: message.mediaType) else {
        return
    }

    let tempMessageID = UUID().uuidString
    SendingMessagesPool.addMessage(with: tempMessageID)

    var messageInfo: JSONDictionary = [
        "recipient_id": recipient.ID,
        "recipient_type": recipient.type.nameForServer,
        "media_type": mediaType.description,
        "random_id": tempMessageID,
    ]

    if let fillMoreInfo = fillMoreInfo {
        messageInfo = fillMoreInfo(messageInfo)
    }

    switch mediaType {

    case .text, .location:

        createMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: { messageID in

            println("send messageID: \(messageID), \(Date().timeIntervalSince1970)")

            SafeDispatch.async {
                let realm = message.realm

                let _ = try? realm?.write {
                    message.messageID = messageID
                    message.sendState = MessageSendState.successed.rawValue
                }

                completion(true)

                NotificationCenter.default.post(name: Config.NotificationName.messageStateChanged, object: nil)
            }
        })

    default:

        var source: UploadAttachment.Source! // TODO: refactor
        if let filePath = filePath {
            source = .filePath(filePath)
        }
        if let fileData = fileData {
            source = .data(fileData)
        }

        let uploadAttachment = UploadAttachment(type: .message, source: source, fileExtension: mediaType.fileExtension!, metaDataString: metaData)

        tryUploadAttachment(uploadAttachment, failureHandler: failureHandler, completion: { uploadedAttachment in

            messageInfo["attachment_id"] = uploadedAttachment.ID

            let doCreateMessage = {
                createMessageWithMessageInfo(messageInfo, failureHandler: failureHandler, completion: { messageID in
                    SafeDispatch.async {
                        let realm = message.realm
                        let _ = try? realm?.write {
                            message.messageID = messageID
                            message.sendState = MessageSendState.successed.rawValue
                        }

                        completion(true)

                        NotificationCenter.default.post(name: Config.NotificationName.messageStateChanged, object: nil)
                    }
                })
            }

            doCreateMessage()
        })
    }
}

public func resendMessage(_ message: Message, failureHandler: FailureHandler?, completion: @escaping (_ success: Bool) -> Void) {

    guard let conversation = message.conversation else {
        return
    }

    guard let recipient = conversation.recipient else {
        return
    }

    guard let messageMediaType = MessageMediaType(rawValue: message.mediaType) else {
        return
    }

    // before resend, recover MessageSendState

    SafeDispatch.async {

        let realm = message.realm

        let _ = try? realm?.write {
            message.sendState = MessageSendState.notSend.rawValue
        }

        NotificationCenter.default.post(name: Config.NotificationName.messageStateChanged, object: nil)
    }

    // also, if resend failed, we need set MessageSendState

    let resendFailureHandler: FailureHandler = { reason, errorMessage in

        failureHandler?(reason, errorMessage)

        SafeDispatch.async {

            let realm = message.realm

            let _ = try? realm?.write {
                message.sendState = MessageSendState.failed.rawValue
            }

            NotificationCenter.default.post(name: Config.NotificationName.messageStateChanged, object: nil)
        }
    }

    switch messageMediaType {

    case .text:

        let fillMoreInfo: (JSONDictionary) -> JSONDictionary = { info in
            var moreInfo = info
            moreInfo["text_content"] = message.textContent
            return moreInfo
        }

        sendMessage(message, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipient, failureHandler: resendFailureHandler, completion: completion)

    case .image:
        let filePath = message.imageFileURL?.path

        sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.mediaMetaData?.string, fillMoreInfo: nil, toRecipient: recipient, failureHandler: resendFailureHandler, completion: completion)

    case .video:
        let filePath = message.videoFileURL?.path

        sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.mediaMetaData?.string, fillMoreInfo: nil, toRecipient: recipient, failureHandler: resendFailureHandler, completion: completion)

    case .audio:
        let filePath = message.audioFileURL?.path

        sendMessage(message, inFilePath: filePath, orFileData: nil, metaData: message.mediaMetaData?.string, fillMoreInfo: nil, toRecipient: recipient, failureHandler: resendFailureHandler, completion: completion)

    case .location:
        if let coordinate = message.coordinate {
            let fillMoreInfo: (JSONDictionary) -> JSONDictionary = { info in
                var moreInfo = info
                moreInfo["longitude"] = coordinate.longitude
                moreInfo["latitude"] = coordinate.latitude
                return moreInfo
            }
            
            sendMessage(message, inFilePath: nil, orFileData: nil, metaData: nil, fillMoreInfo: fillMoreInfo, toRecipient: recipient, failureHandler: resendFailureHandler, completion: completion)
        }
        
    default:
        break
    }
}

public func batchMarkAsReadOfMessagesToRecipient(_ recipient: Recipient, beforeMessage: Message, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    guard Config.isAppActive?() ?? false else {
        return
    }

    let requestParameters: JSONDictionary = [
        "max_id": beforeMessage.messageID
    ]

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/\(recipient.type.nameForBatchMarkAsRead)/\(recipient.ID)/messages/batch_mark_as_read", method: .patch, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func deleteMessageFromServer(messageID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/messages/\(messageID)", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func refreshAttachmentWithID(_ attachmentID: String, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let requestParameters: JSONDictionary = [
        "ids": [attachmentID],
    ]

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return (data["attachments"] as? [JSONDictionary])?.first
    }

    let resource = authJsonResource(path: "/v1/attachments/refresh_url", method: .patch, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Feeds

public enum FeedSortStyle: String {

    case distance = "distance"
    case time = "time"
    case match = "default"
    case recommended = "recommended"
    
    public var name: String {
        switch self {
        case .distance:
            return String.trans_titleNearby
        case .time:
            return NSLocalizedString("Time", comment: "")
        case .match:
            return String.trans_titleMatch
        case .recommended:
            return NSLocalizedString("Recommended", comment: "")
        }
    }
    
    public var nameWithArrow: String {
        return name.yep_appendArrow()
    }

    public var needPageFeedID: Bool {
        switch self {
        case .distance:
            return true
        case .time:
            return true
        case .match:
            return false
        case .recommended:
            return true
        }
    }
}

public struct DiscoveredAttachment {

    //let kind: AttachmentKind
    public let metadata: String
    public let URLString: String

    public var image: UIImage?

    public init(metadata: String, URLString: String, image: UIImage?) {
        self.metadata = metadata
        self.URLString = URLString
        self.image = image
    }

    public var isTemporary: Bool {
        return image != nil
    }

    public var thumbnailImageData: Data? {

        guard (metadata as NSString).length > 0 else {
            return nil
        }

        if let data = metadata.data(using: .utf8, allowLossyConversion: false) {
            if let metaDataInfo = decodeJSON(data) {
                if let thumbnailString = metaDataInfo[Config.MetaData.thumbnailString] as? String {
                    let imageData = Data(base64Encoded: thumbnailString, options: NSData.Base64DecodingOptions(rawValue: 0))
                    return imageData
                }
            }
        }

        return nil
    }

    public var thumbnailImage: UIImage? {

        if let imageData = thumbnailImageData {
            let image = UIImage(data: imageData)
            return image
        }

        return nil
    }

    public static func fromJSONDictionary(_ json: JSONDictionary) -> DiscoveredAttachment? {
        guard let
            //kindString = json["kind"] as? String,
            //kind = AttachmentKind(rawValue: kindString),
            metadata = json["metadata"] as? String,
            let fileInfo = json["file"] as? JSONDictionary,
            let URLString = fileInfo["url"] as? String else {
                return nil
        }

        //return DiscoveredAttachment(kind: kind, metadata: metadata, URLString: URLString)
        return DiscoveredAttachment(metadata: metadata, URLString: URLString, image: nil)
    }
}

public func ==(lhs: DiscoveredFeed, rhs: DiscoveredFeed) -> Bool {
    return lhs.id == rhs.id
}

public struct DiscoveredFeed: Hashable {
    
    public var hashValue: Int {
        return id.hashValue
    }

    public let id: String
    public let allowComment: Bool
    public let kind: FeedKind

    public var hasSocialImage: Bool {
        switch kind {
        case .dribbbleShot:
            return true
        default:
            return false
        }
    }

    public var hasMapImage: Bool {

        switch kind {
        case .location:
            return true
        default:
            return false
        }
    }

    public let createdUnixTime: TimeInterval
    public let updatedUnixTime: TimeInterval

    public let creator: DiscoveredUser
    public let body: String
    public let highlightedKeywordsBody: String?

    public struct GithubRepo {
        public let ID: Int
        public let name: String
        public let fullName: String
        public let description: String
        public let URLString: String
        public let createdUnixTime: TimeInterval

        public static func fromJSONDictionary(_ json: JSONDictionary) -> GithubRepo? {
            guard let
                ID = json["repo_id"] as? Int,
                let name = json["name"] as? String,
                let fullName = json["full_name"] as? String,
                let description = json["description"] as? String,
                let URLString = json["url"] as? String,
                let createdUnixTime = json["created_at"] as? TimeInterval else {
                    return nil
            }

            return GithubRepo(ID: ID, name: name, fullName: fullName, description: description, URLString: URLString, createdUnixTime: createdUnixTime)
        }
    }

    public struct DribbbleShot {
        public let ID: Int
        public let title: String
        public let description: String?
        public let imageURLString: String
        public let htmlURLString: String
        public let createdUnixTime: TimeInterval

        public static func fromJSONDictionary(_ json: JSONDictionary) -> DribbbleShot? {
            guard let
                ID = json["shot_id"] as? Int,
                let title = json["title"] as? String,
                let imageURLString = json["media_url"] as? String,
                let htmlURLString = json["url"] as? String,
                let createdUnixTime = json["created_at"] as? TimeInterval else {
                    return nil
            }
            
            let description = json["description"] as? String

            return DribbbleShot(ID: ID, title: title, description: description, imageURLString: imageURLString, htmlURLString: htmlURLString, createdUnixTime: createdUnixTime)
        }
    }

    public struct AudioInfo {
        public let feedID: String
        public let URLString: String
        public let metaData: Data
        public let duration: TimeInterval
        public let sampleValues: [CGFloat]

        public init(feedID: String, URLString: String, metaData: Data, duration: TimeInterval, sampleValues: [CGFloat]) {
            self.feedID = feedID
            self.URLString = URLString
            self.metaData = metaData
            self.duration = duration
            self.sampleValues = sampleValues
        }

        public static func fromJSONDictionary(_ json: JSONDictionary, feedID: String) -> AudioInfo? {
            guard
                let fileInfo = json["file"] as? JSONDictionary,
                let URLString = fileInfo["url"] as? String,
                let metaDataString = json["metadata"] as? String else {
                    return nil
            }

            if let metaData = metaDataString.data(using: .utf8, allowLossyConversion: false) {
                if let metaDataInfo = decodeJSON(metaData) {

                    guard let
                        duration = metaDataInfo[Config.MetaData.audioDuration] as? TimeInterval,
                        let sampleValues = metaDataInfo[Config.MetaData.audioSamples] as? [CGFloat] else {
                            return nil
                    }

                    return AudioInfo(feedID: feedID, URLString: URLString, metaData: metaData, duration: duration, sampleValues: sampleValues)
                }
            }

            return nil
        }
    }

    public struct LocationInfo {

        public let name: String
        public let latitude: CLLocationDegrees
        public let longitude: CLLocationDegrees

        public var coordinate: CLLocationCoordinate2D {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        public static func fromJSONDictionary(_ json: JSONDictionary) -> LocationInfo? {
            guard let
                name = json["place"] as? String,
                let latitude = json["latitude"] as? CLLocationDegrees,
                let longitude = json["longitude"] as? CLLocationDegrees else {
                    return nil
            }

            return LocationInfo(name: name, latitude: latitude, longitude: longitude)
        }
    }

    public struct OpenGraphInfo: OpenGraphInfoType {

        public let url: URL

        public let siteName: String
        public let title: String
        public let infoDescription: String
        public let thumbnailImageURLString: String

        public static func fromJSONDictionary(_ json: JSONDictionary) -> OpenGraphInfo? {
            guard let
                URLString = json["url"] as? String,
                let url = URL(string: URLString),
                let siteName = json["site_name"] as? String,
                let title = json["title"] as? String,
                let infoDescription = json["description"] as? String,
                let thumbnailImageURLString = json["image_url"] as? String else {
                    return nil
            }

            return OpenGraphInfo(url: url, siteName: siteName, title: title, infoDescription: infoDescription, thumbnailImageURLString: thumbnailImageURLString)
        }
    }

    public enum Attachment {
        case images([DiscoveredAttachment])
        case github(GithubRepo)
        case dribbble(DribbbleShot)
        case audio(AudioInfo)
        case location(LocationInfo)
        case url(OpenGraphInfo)
    }

    public let attachment: Attachment?

    public var imageAttachments: [DiscoveredAttachment]? {
        if let attachment = attachment, case let .images(attachments) = attachment {
            return attachments
        }

        return nil
    }

    public var imageAttachmentsCount: Int {
        return imageAttachments?.count ?? 0
    }

    public let distance: Double?

    public let skill: Skill?
    public let groupID: String
    public var messagesCount: Int
    public var recommended: Bool

    public var uploadingErrorMessage: String? = nil

    public var timeString: String {

        let date = Date(timeIntervalSince1970: createdUnixTime)
        let timeString = Config.timeAgoAction?(date) ?? ""
        return timeString
    }

    public var timeAndDistanceString: String {

        var distanceString: String?
        if let distance = distance {
            if distance < 1 {
                distanceString = String.trans_titleNearby
            } else {
                distanceString = "\(distance.yep_format(".1")) km"
            }
        }

        if let distanceString = distanceString {
            return timeString + "  ∙  " + distanceString
        } else {
            return timeString
        }
    }

    public init(id: String, allowComment: Bool, kind: FeedKind, createdUnixTime: TimeInterval, updatedUnixTime: TimeInterval, creator: DiscoveredUser, body: String, highlightedKeywordsBody: String?, attachment: Attachment?, distance: Double?, skill: Skill?, groupID: String, messagesCount: Int, recommended: Bool, uploadingErrorMessage: String?) {

        self.id = id
        self.allowComment = allowComment
        self.kind = kind
        self.createdUnixTime = createdUnixTime
        self.updatedUnixTime = updatedUnixTime
        self.creator = creator
        self.body = body
        self.highlightedKeywordsBody = highlightedKeywordsBody
        self.attachment = attachment
        self.distance = distance
        self.skill = skill
        self.groupID = groupID
        self.messagesCount = messagesCount
        self.recommended = recommended
        self.uploadingErrorMessage = uploadingErrorMessage
    }

    public static func fromFeedInfo(_ feedInfo: JSONDictionary, groupInfo: JSONDictionary?) -> DiscoveredFeed? {

        guard let
            id = feedInfo["id"] as? String,
            let allowComment = feedInfo["allow_comment"] as? Bool,
            let kindString = feedInfo["kind"] as? String,
            let kind = FeedKind(rawValue: kindString),
            let createdUnixTime = feedInfo["created_at"] as? TimeInterval,
            let updatedUnixTime = feedInfo["updated_at"] as? TimeInterval,
            let creatorInfo = feedInfo["user"] as? JSONDictionary,
            let body = feedInfo["body"] as? String,
            let messagesCount = feedInfo["message_count"] as? Int else {
                return nil
        }

        let recommended = (feedInfo["recommended"] as? Bool) ?? false

        let highlightedKeywordsBody = feedInfo["highlight"] as? String

        var groupInfo = groupInfo

        if groupInfo == nil {
            groupInfo = feedInfo["circle"] as? JSONDictionary
        }

        guard let creator = parseDiscoveredUser(creatorInfo), let groupID = groupInfo?["id"] as? String else {
            return nil
        }

        let distance = feedInfo["distance"] as? Double

        var attachment: DiscoveredFeed.Attachment?

        switch kind {

        case .url:
            if let
                openGraphInfosData = feedInfo["attachments"] as? [JSONDictionary],
                let openGraphInfoDict = openGraphInfosData.first,
                let openGraphInfo = DiscoveredFeed.OpenGraphInfo.fromJSONDictionary(openGraphInfoDict) {
                    attachment = .url(openGraphInfo)
            }

        case .image:

            let attachmentsData = feedInfo["attachments"] as? [JSONDictionary]
            let attachments = attachmentsData?.map({ DiscoveredAttachment.fromJSONDictionary($0) }).flatMap({ $0 }) ?? []

            attachment = .images(attachments)

        case .githubRepo:

            if let
                githubReposData = feedInfo["attachments"] as? [JSONDictionary],
                let githubRepoInfo = githubReposData.first,
                let githubRepo = DiscoveredFeed.GithubRepo.fromJSONDictionary(githubRepoInfo) {
                    attachment = .github(githubRepo)
            }

        case .dribbbleShot:

            if let
                dribbbleShotsData = feedInfo["attachments"] as? [JSONDictionary],
                let dribbbleShotInfo = dribbbleShotsData.first,
                let dribbbleShot = DiscoveredFeed.DribbbleShot.fromJSONDictionary(dribbbleShotInfo) {
                    attachment = .dribbble(dribbbleShot)
            }

        case .audio:

            if let
                audioInfosData = feedInfo["attachments"] as? [JSONDictionary],
                let _audioInfo = audioInfosData.first,
                let audioInfo = DiscoveredFeed.AudioInfo.fromJSONDictionary(_audioInfo, feedID: id) {
                    attachment = .audio(audioInfo)
            }

        case .location:

            if let
                locationInfosData = feedInfo["attachments"] as? [JSONDictionary],
                let _locationInfo = locationInfosData.first,
                let locationInfo = DiscoveredFeed.LocationInfo.fromJSONDictionary(_locationInfo) {
                    attachment = .location(locationInfo)
            }

        default:
            break
        }

        var skill: Skill?
        if let skillInfo = feedInfo["skill"] as? JSONDictionary {
            skill = Skill.fromJSONDictionary(skillInfo)
        }

        return DiscoveredFeed(id: id, allowComment: allowComment, kind: kind, createdUnixTime: createdUnixTime, updatedUnixTime: updatedUnixTime, creator: creator, body: body, highlightedKeywordsBody: highlightedKeywordsBody, attachment: attachment, distance: distance, skill: skill, groupID: groupID, messagesCount: messagesCount, recommended: recommended, uploadingErrorMessage: nil)
    }
}

public let parseFeed: (JSONDictionary) -> DiscoveredFeed? = { data in

    if let feedInfo = data["topic"] as? JSONDictionary {
        return DiscoveredFeed.fromFeedInfo(feedInfo, groupInfo: data)
    }

    return nil
}

public let parseFeeds: (JSONDictionary) -> [DiscoveredFeed?]? = { data in

    if let feedsData = data["topics"] as? [JSONDictionary] {
        return feedsData.map({ DiscoveredFeed.fromFeedInfo($0, groupInfo: nil) })
    }

    return nil
}

public func discoverFeedsWithSortStyle(_ sortStyle: FeedSortStyle, skill: Skill?, pageIndex: Int, perPage: Int, maxFeedID: String?, failureHandler: ((Reason, String?) -> Void)?, completion: @escaping (_ feeds: [DiscoveredFeed?]) -> Void) {

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

    let parse: (JSONDictionary) -> ([DiscoveredFeed?])? = { data in

        // 只离线第一页，且无 skill
        if pageIndex == 1 && skill == nil {
            if let realm = try? Realm() {
                if let offlineData = try? JSONSerialization.data(withJSONObject: data, options: []) {

                    let offlineJSON = OfflineJSON(name: OfflineJSONName.feeds.rawValue, data: offlineData)

                    let _ = try? realm.write {
                        realm.add(offlineJSON, update: true)
                        println("offline feeds \(sortStyle)")
                    }
                }
            }
        }

        return parseFeeds(data)
    }

    let resource = authJsonResource(path: "/v1/topics/discover", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func feedsWithKeyword(_ keyword: String, skillID: String?, userID: String?, pageIndex: Int, perPage: Int, failureHandler: FailureHandler?, completion: @escaping (_ feeds: [DiscoveredFeed?]) -> Void) {

    guard !keyword.isEmpty else {
        completion([])
        return
    }

    var requestParameters: JSONDictionary = [
        "q": keyword,
        "page": pageIndex,
        "per_page": perPage,
    ]

    if let skillID = skillID {
        requestParameters["skill_id"] = skillID
    }

    if let userID = userID {
        requestParameters["user_id"] = userID
    }

    let parse: (JSONDictionary) -> [DiscoveredFeed?]? = { data in
        return parseFeeds(data)
    }

    let resource = authJsonResource(path: "/v1/topics/search", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func hotWordsOfSearchFeeds(failureHandler: FailureHandler?, completion: @escaping ([String]) -> Void) {

    let parse: (JSONDictionary) -> [String]? = { data in
        let hotWords = data["hot_words"] as? [String]
        return hotWords
    }

    let resource = authJsonResource(path: "/v1/hot_words", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func feedWithSharedToken(_ token: String, failureHandler: FailureHandler?, completion: @escaping (DiscoveredFeed) -> Void) {

    let requestParameters: JSONDictionary = [
        "token": token,
    ]

    let parse = parseFeed
    
    let resource = authJsonResource(path: "/v1/circles/show_by_token", method: .get, requestParameters: requestParameters, parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func myFeedsAtPageIndex(_ pageIndex: Int, perPage: Int, failureHandler: FailureHandler?, completion: @escaping (_ feeds: [DiscoveredFeed?]) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": pageIndex,
        "per_page": perPage,
    ]

    let parse = parseFeeds

    let resource = authJsonResource(path: "/v1/topics", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func feedsOfUser(_ userID: String, pageIndex: Int, perPage: Int, failureHandler: FailureHandler?, completion: @escaping (_ feeds: [DiscoveredFeed?]) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": pageIndex,
        "per_page": perPage,
    ]

    let parse = parseFeeds

    let resource = authJsonResource(path: "/v1/users/\(userID)/topics", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public enum FeedKind: String {
    case text = "text"
    case url = "web_page"
    case image = "image"
    case video = "video"
    case audio = "audio"
    case location = "location"

    case appleMusic = "apple_music"
    case appleMovie = "apple_movie"
    case appleEBook = "apple_ebook"

    case githubRepo = "github"
    case dribbbleShot = "dribbble"
    //case instagramMedia = "instagram"

    public var accountName: String? {
        switch self {
        case .githubRepo: return "github"
        case .dribbbleShot: return "dribbble"
        //case .instagramMedia: return "instagram"
        default: return nil
        }
    }

    public var needBackgroundUpload: Bool {
        switch self {
        case .image:
            return true
        case .audio:
            return true
        default:
            return false
        }
    }

    public var needParseOpenGraph: Bool {
        switch self {
        case .text:
            return true
        default:
            return false
        }
    }
}

public func createFeedWithKind(_ kind: FeedKind, message: String, attachments: [JSONDictionary]?, coordinate: CLLocationCoordinate2D?, skill: Skill?, allowComment: Bool, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

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

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/topics", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func deleteFeedWithFeedID(_ feedID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parse: (JSONDictionary) -> ()? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/topics/\(feedID)", method: .delete, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func recommendFeedWithFeedID(_ feedID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parse: (JSONDictionary) -> ()? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/admin/topics/\(feedID)/recommend", method: .patch, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func cancelRecommendedFeedWithFeedID(_ feedID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let parse: (JSONDictionary) -> ()? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/admin/topics/\(feedID)/cancel_recommended", method: .patch, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func headCreatorsOfBlockedFeeds(failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": 1,
        "per_page": 30,
    ]

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/blocked_topic_creators", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

private func moreCreatorsOfBlockedFeeds(inPage page: Int, withPerPage perPage: Int, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {

    let requestParameters: JSONDictionary = [
        "page": page,
        "per_page": perPage,
    ]

    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }

    let resource = authJsonResource(path: "/v1/blocked_topic_creators", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func creatorsOfBlockedFeeds(failureHandler: FailureHandler?, completion: @escaping ([DiscoveredUser]) -> Void) {

    headCreatorsOfBlockedFeeds(failureHandler: failureHandler) { result in

        guard let page1CreatorInfos = result["blocked_topic_creators"] as? [JSONDictionary] else {
            completion([])
            return
        }

        let page1Creators = page1CreatorInfos.map({ parseDiscoveredUser($0) }).flatMap({ $0 })

        guard let count = result["count"] as? Int, let currentPage = result["current_page"] as? Int, let perPage = result["per_page"] as? Int else {

            println("creatorsOfBlockedFeeds not paging info.")

            completion(page1Creators)
            return
        }

        if count <= currentPage * perPage {
            completion(page1Creators)

        } else {
            var creators = [DiscoveredUser]()

            creators += page1Creators

            // We have more creators

            var allGood = true
            let downloadGroup = DispatchGroup()

            for page in 2..<((count / perPage) + ((count % perPage) > 0 ? 2 : 1)) {
                downloadGroup.enter()

                moreCreatorsOfBlockedFeeds(inPage: page, withPerPage: perPage, failureHandler: { (reason, errorMessage) in
                    allGood = false
                    failureHandler?(reason, errorMessage)
                    downloadGroup.leave()

                }, completion: { result in
                    if let currentCreatorInfos = result["blocked_topic_creators"] as? [JSONDictionary] {
                        let currentCreators = currentCreatorInfos.map({ parseDiscoveredUser($0) }).flatMap({ $0 })
                        creators += currentCreators
                    }
                    downloadGroup.leave()
                })
            }

            downloadGroup.notify(queue: DispatchQueue.main) {
                if allGood {
                    completion(creators)
                }
            }
        }
    }
}

public func amIBlockedFeedsFromCreator(userID: String, failureHandler: FailureHandler?, completion: @escaping (Bool) -> Void) {

    let requestParameters: JSONDictionary = [
        "id": userID,
    ]

    let parse: (JSONDictionary) -> Bool? = { data in
        let blocked = data["hide_topics"] as? Bool
        return blocked
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/hide_topics_setting", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func blockFeedsFromCreator(userID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let requestParameters: JSONDictionary = [
        "user_id": userID,
    ]

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/blocked_topic_creators", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func unblockFeedsFromCreator(userID: String, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let requestParameters: JSONDictionary = [
        "user_id": userID,
    ]

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/blocked_topic_creators/\(userID)", method: .delete, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - Social Work

public struct TokensOfSocialAccounts {
    public let githubToken: String?
    public let dribbbleToken: String?
    public let instagramToken: String?
}

public func tokensOfSocialAccounts(failureHandler: ((Reason, String?) -> Void)?, completion: @escaping (TokensOfSocialAccounts) -> Void) {

    let parse: (JSONDictionary) -> TokensOfSocialAccounts? = { data in

        let githubToken = data["github"] as? String
        let dribbbleToken = data["dribbble"] as? String
        let instagramToken = data["instagram"] as? String

        return TokensOfSocialAccounts(githubToken: githubToken, dribbbleToken: dribbbleToken, instagramToken: instagramToken)
    }

    let resource = authJsonResource(path: "/v1/user/provider_tokens", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public func authURLRequestWithURL(_ url: URL) -> URLRequest {
    
    let request = NSMutableURLRequest(url: url, cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 0)
    
    if let token = YepUserDefaults.v1AccessToken.value {
        request.setValue("Token token=\"\(token)\"", forHTTPHeaderField: "Authorization")
    }

    return request as URLRequest
}

public func socialAccountWithProvider(_ provider: String, failureHandler: FailureHandler?, completion: @escaping (JSONDictionary) -> Void) {
    
    let parse: (JSONDictionary) -> JSONDictionary? = { data in
        return data
    }
    
    let resource = authJsonResource(path: "/v1/user/\(provider)", method: .get, requestParameters: [:], parse: parse)
    
    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public struct GithubWork {

    public struct Repo {
        public let name: String
        public let language: String?
        public let description: String
        public let stargazersCount: Int
        public let htmlURLString: String
    }

    public struct User {
        public let loginName: String
        public let avatarURLString: String
        public let htmlURLString: String
        public let publicReposCount: Int
        public let followersCount: Int
        public let followingCount: Int
    }

    public let repos: [Repo]
    public let user: User
}

public func githubWorkOfUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (GithubWork) -> Void) {

    let parse: (JSONDictionary) -> GithubWork? = { data in

        if let reposData = data["repos"] as? [JSONDictionary], let userInfo = data["user"] as? JSONDictionary {

            var repos = Array<GithubWork.Repo>()

            for repoInfo in reposData {
                if let
                    name = repoInfo["name"] as? String,
                    let description = repoInfo["description"] as? String,
                    let stargazersCount = repoInfo["stargazers_count"] as? Int,
                    let htmlURLString = repoInfo["html_url"] as? String {

                        let language = repoInfo["language"] as? String
                        let repo = GithubWork.Repo(name: name, language: language, description: description, stargazersCount: stargazersCount, htmlURLString: htmlURLString)

                        repos.append(repo)
                }
            }

            repos.sort { $0.stargazersCount > $1.stargazersCount }

            if let
                loginName = userInfo["login"] as? String,
                let avatarURLString = userInfo["avatar_url"] as? String,
                let htmlURLString = userInfo["html_url"] as? String,
                let publicReposCount = userInfo["public_repos"] as? Int,
                let followersCount = userInfo["followers"] as? Int,
                let followingCount = userInfo["following"] as? Int {

                    let user = GithubWork.User(loginName: loginName, avatarURLString: avatarURLString, htmlURLString: htmlURLString, publicReposCount: publicReposCount, followersCount: followersCount, followingCount: followingCount)

                    let githubWork = GithubWork(repos: repos, user: user)

                    return githubWork
            }
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/users/\(userID)/github", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public struct DribbbleWork {

    public struct Shot {

        public struct Images {
            public let hidpi: String?
            public let normal: String
            public let teaser: String
        }

        public let title: String
        public let description: String?
        public let htmlURLString: String
        public let images: Images
        public let likesCount: Int
        public let commentsCount: Int
    }
    public let shots: [Shot]

    public let username: String
    public let userURLString: String
}

public func dribbbleWorkOfUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (DribbbleWork) -> Void) {

    let parse: (JSONDictionary) -> DribbbleWork? = { data in

        if let
            shotsData = data["shots"] as? [JSONDictionary],
            let userInfo = data["user"] as? JSONDictionary,
            let username = userInfo["username"] as? String,
            let userURLString = userInfo["html_url"] as? String {

                var shots = Array<DribbbleWork.Shot>()

                for shotInfo in shotsData {
                    if let
                        title = shotInfo["title"] as? String,
                        let htmlURLString = shotInfo["html_url"] as? String,
                        let imagesInfo = shotInfo["images"] as? JSONDictionary,
                        let likesCount = shotInfo["likes_count"] as? Int,
                        let commentsCount = shotInfo["comments_count"] as? Int {
                            if let
                                normal = imagesInfo["normal"] as? String,
                                let teaser = imagesInfo["teaser"] as? String {
                                    
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

    let resource = authJsonResource(path: "/v1/users/\(userID)/dribbble", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public struct InstagramWork {

    public struct Media {

        public let ID: String
        public let linkURLString: String

        public struct Images {
            public let lowResolution: String
            public let standardResolution: String
            public let thumbnail: String
        }
        public let images: Images

        public let likesCount: Int
        public let commentsCount: Int

        public let username: String
    }

    public let medias: [Media]
}

public func instagramWorkOfUserWithUserID(_ userID: String, failureHandler: FailureHandler?, completion: @escaping (InstagramWork) -> Void) {

    let parse: (JSONDictionary) -> InstagramWork? = { data in

        if let mediaData = data["media"] as? [JSONDictionary] {

            var medias = Array<InstagramWork.Media>()

            for mediaInfo in mediaData {
                if let
                    ID = mediaInfo["id"] as? String,
                    let linkURLString = mediaInfo["link"] as? String,
                    let imagesInfo = mediaInfo["images"] as? JSONDictionary,
                    let likesInfo = mediaInfo["likes"] as? JSONDictionary,
                    let commentsInfo = mediaInfo["comments"] as? JSONDictionary,
                    let userInfo = mediaInfo["user"] as? JSONDictionary {
                        if let
                            lowResolutionInfo = imagesInfo["low_resolution"] as? JSONDictionary,
                            let standardResolutionInfo = imagesInfo["standard_resolution"] as? JSONDictionary,
                            let thumbnailInfo = imagesInfo["thumbnail"] as? JSONDictionary,

                            let lowResolution = lowResolutionInfo["url"] as? String,
                            let standardResolution = standardResolutionInfo["url"] as? String,
                            let thumbnail = thumbnailInfo["url"] as? String,

                            let likesCount = likesInfo["count"] as? Int,
                            let commentsCount = commentsInfo["count"] as? Int,

                            let username = userInfo["username"] as? String {

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

    let resource = authJsonResource(path: "/v1/users/\(userID)/instagram", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public enum SocialWork {
    case dribbble(DribbbleWork)
    case instagram(InstagramWork)
}

// MARK: - Feedback

public struct Feedback {
    public let content: String
    public let deviceInfo: String

    public init(content: String, deviceInfo: String) {
        self.content = content
        self.deviceInfo = deviceInfo
    }
}

public func sendFeedback(_ feedback: Feedback, failureHandler: FailureHandler?, completion: @escaping () -> Void) {

    let requestParameters: JSONDictionary = [
        "content": feedback.content,
        "device_info": feedback.deviceInfo,
    ]

    let parse: (JSONDictionary) -> Void? = { data in
        return
    }

    let resource = authJsonResource(path: "/v1/feedbacks", method: .post, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: Places

public struct FoursquareVenue {
    public let name: String

    public let latitude: CLLocationDegrees
    public let longitude: CLLocationDegrees

    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

public func foursquareVenuesNearby(coordinate: CLLocationCoordinate2D, failureHandler: FailureHandler?, completion: @escaping ([FoursquareVenue]) -> Void) {

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd"
    let dateString = dateFormatter.string(from: Date())

    let requestParameters: JSONDictionary = [
        "client_id": "NFMF2UV2X5BCADG2T5FE3BIORDPEDJA5JZVDWF0XXAZUX2AS",
        "client_secret": "UOGE0SCBWHV2JFXD5AFAIHOVTUSBQ3ERH4ALHU3WU3BSR4CN",
        "v": dateString,
        "ll": "\(coordinate.latitude),\(coordinate.longitude)"
    ]

    let parse: (JSONDictionary) -> [FoursquareVenue]? = { data in

        if let
            response = data["response"] as? JSONDictionary,
            let venuesData = response["venues"] as? [JSONDictionary] {

                var venues = [FoursquareVenue]()

                for venueInfo in venuesData {
                    if let
                        name = venueInfo["name"] as? String,
                        let locationInfo = venueInfo["location"] as? JSONDictionary,
                        let latitude = locationInfo["lat"] as? CLLocationDegrees,
                        let longitude = locationInfo["lng"] as? CLLocationDegrees {
                            let venue = FoursquareVenue(name: name, latitude: latitude, longitude: longitude)
                            venues.append(venue)
                    }
                }

                return venues
        }

        return []
    }

    let resource = jsonResource(path: "/v2/venues/search", method: .get, requestParameters: requestParameters, parse: parse)

    let foursquareBaseURL = URL(string: "https://api.foursquare.com")!

    apiRequest({_ in}, baseURL: foursquareBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: Mention

public func ==(lhs: UsernamePrefixMatchedUser, rhs: UsernamePrefixMatchedUser) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

public struct UsernamePrefixMatchedUser {
    public let userID: String
    public let username: String
    public let nickname: String
    public let avatarURLString: String?
    public let lastSignInUnixTime: TimeInterval

    public var mentionUsername: String {
        return "@" + username
    }
}

extension UsernamePrefixMatchedUser: Hashable {

    public var hashValue: Int {
        return userID.hashValue
    }
}

public func usersMatchWithUsernamePrefix(_ usernamePrefix: String, failureHandler: FailureHandler?, completion: @escaping ([UsernamePrefixMatchedUser]) -> Void) {

    let requestParameters: JSONDictionary = [
        "q": usernamePrefix,
    ]

    let parse: (JSONDictionary) -> [UsernamePrefixMatchedUser]? = { data in

        if let usersData = data["users"] as? [JSONDictionary] {
            let users: [UsernamePrefixMatchedUser] = usersData.map({ userInfo in
                guard let
                    userID = userInfo["id"] as? String,
                    let username = userInfo["username"] as? String,
                    let nickname = userInfo["nickname"] as? String,
                    let avatarInfo = userInfo["avatar"] as? JSONDictionary
                else {
                    return nil
                }

                let avatarURLString = avatarInfo["thumb_url"] as? String

                return UsernamePrefixMatchedUser(userID: userID, username: username, nickname: nickname, avatarURLString: avatarURLString, lastSignInUnixTime: 0)
            }).flatMap({ $0 })

            return users
        }

        return nil
    }

    let resource = authJsonResource(path: "/v1/users/typeahead", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

// MARK: - GeniusInterview

public struct GeniusInterview {

    public let user: DiscoveredUser

    public let number: Int
    public let title: String
    public let detail: String
    public let url: URL

    public init?(_ info: JSONDictionary) {

        guard let
            userInfo = info["user"] as? JSONDictionary,
            let number = info["no"] as? Int,
            let title = info["title"] as? String,
            let detail = info["description"] as? String,
            let urlString = info["link"] as? String else {
            return nil
        }

        guard let user = parseDiscoveredUser(userInfo) else {
            return nil
        }

        guard let url = URL(string: urlString) else {
            return nil
        }

        self.user = user
        self.number = number
        self.title = title
        self.detail = detail
        self.url = url
    }
}

public func geniusInterviewsWithCount(_ count: Int, afterNumber number: Int?, failureHandler: FailureHandler?, completion: @escaping ([GeniusInterview]) -> Void) {

    var requestParameters: JSONDictionary = [
        "count": count,
    ]
    if let number = number {
        requestParameters["max_no"] = number
    }

    let parse: (JSONDictionary) -> [GeniusInterview]? = { data in

        if number == nil {
            if let realm = try? Realm() {
                if let offlineData = try? JSONSerialization.data(withJSONObject: data, options: []) {

                    let offlineJSON = OfflineJSON(name: OfflineJSONName.geniusInterviews.rawValue, data: offlineData)

                    let _ = try? realm.write {
                        realm.add(offlineJSON, update: true)
                        println("offline geniusInterviews")
                    }
                }
            }
        }

        if let geniusInterviewsData = data["genius_interviews"] as? [JSONDictionary] {

            let geniusInterviews: [GeniusInterview] = geniusInterviewsData.map({ GeniusInterview($0) }).flatMap({ $0 })
            return geniusInterviews
        }
        
        return nil
    }

    let resource = authJsonResource(path: "/v1/genius_interviews", method: .get, requestParameters: requestParameters, parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}

public struct GeniusInterviewBanner {

    public let user: DiscoveredUser
    public let imageURL: URL
    public let linkURL: URL

    public init?(_ info: JSONDictionary) {

        guard let
            userInfo = info["user"] as? JSONDictionary,
            let imageURLString = info["url"] as? String,
            let linkURLString = info["link"] as? String else {
            return nil
        }

        guard let user = parseDiscoveredUser(userInfo) else {
            return nil
        }

        guard let imageURL = URL(string: imageURLString) else {
            return nil
        }

        guard let linkURL = URL(string: linkURLString) else {
            return nil
        }

        self.user = user
        self.imageURL = imageURL
        self.linkURL = linkURL
    }
}

public func latestGeniusInterviewBanner(failureHandler: FailureHandler?, completion: @escaping (GeniusInterviewBanner) -> Void) {

    let parse: (JSONDictionary) -> GeniusInterviewBanner? = { data in

        if let realm = try? Realm() {
            if let offlineData = try? JSONSerialization.data(withJSONObject: data, options: []) {
                let offlineJSON = OfflineJSON(name: OfflineJSONName.geniusInterviewBanner.rawValue, data: offlineData)
                let _ = try? realm.write {
                    realm.add(offlineJSON, update: true)
                    println("offline geniusInterviewBanner")
                }
            }
        }

        let banner = GeniusInterviewBanner(data)
        return banner
    }

    let resource = authJsonResource(path: "/v1/genius_interview_banners/current", method: .get, requestParameters: [:], parse: parse)

    apiRequest({_ in}, baseURL: yepBaseURL, resource: resource, failure: failureHandler, completion: completion)
}


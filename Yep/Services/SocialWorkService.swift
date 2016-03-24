//
//  SocialWorkService.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation
import RealmSwift

private let githubBaseURL = NSURL(string: "https://api.github.com")!
private let dribbbleBaseURL = NSURL(string: "https://api.dribbble.com")!
private let instagramBaseURL = NSURL(string: "https://api.instagram.com")!

private func githubResource<A>(token token: String, path: String, method: Method, requestParameters: JSONDictionary, parse: JSONDictionary -> A?) -> Resource<A> {

    let jsonParse: NSData -> A? = { data in
        if let json = decodeJSON(data) {
            return parse(json)
        }
        return nil
    }

    let jsonBody = encodeJSON(requestParameters)
    var headers = [
        "Content-Type": "application/json",
    ]

    headers["Authorization"] = "token \(token)"

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

private func dribbbleResource<A>(token token: String, path: String, method: Method, requestParameters: JSONDictionary, parse: JSONDictionary -> A?) -> Resource<A> {

    let jsonParse: NSData -> A? = { data in
        if let json = decodeJSON(data) {
            return parse(json)
        }
        return nil
    }

    let jsonBody = encodeJSON(requestParameters)
    var headers = [
        "Content-Type": "application/json",
    ]

    headers["Authorization"] = "Bearer \(token)"

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

private func instagramResource<A>(token token: String, path: String, method: Method, requestParameters: JSONDictionary, parse: JSONDictionary -> A?) -> Resource<A> {

    let jsonParse: NSData -> A? = { data in
        if let json = decodeJSON(data) {
            return parse(json)
        }
        return nil
    }

    let jsonBody = encodeJSON(requestParameters)
    let headers = [
        "Content-Type": "application/json",
    ]

    return Resource(path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

enum SocialWorkPiece {
    case Github(GithubRepo)
    case Dribbble(DribbbleShot)
    case Instagram(InstagramMedia)

    var messageSocialWorkType: MessageSocialWorkType {
        switch self {
        case .Github:
            return MessageSocialWorkType.GithubRepo
        case .Dribbble:
            return MessageSocialWorkType.DribbbleShot
        case .Instagram:
            return MessageSocialWorkType.InstagramMedia
        }
    }

    var messageID: String {
        switch self {
        case .Github(let repo):
            return "github_repo_\(repo.ID)"
        case .Dribbble(let shot):
            return "dribbble_shot_\(shot.ID)"
        case .Instagram(let media):
            return "instagram_media_\(media.ID)"
        }
    }
}

// MARK: Github Repo

struct GithubRepo {
    let ID: Int
    let name: String
    let fullName: String
    let URLString: String
    let description: String

    let createdAt: NSDate
}

// ref https://developer.github.com/v3/

func githubReposWithToken(token: String, failureHandler: ((Reason, String?) -> Void)?, completion: [GithubRepo] -> Void) {

    let requestParameters = [
        "type": "owner",
        "sort": "created",
    ]

    let parse: JSONDictionary -> [GithubRepo]? = { data in

        //println("githubReposWithToken data: \(data)")

        guard let reposData = data["data"] as? [JSONDictionary] else {
            return nil
        }

        var repos = [GithubRepo]()

        for repoInfo in reposData {

            guard let
                ID = repoInfo["id"] as? Int,
                name = repoInfo["name"] as? String,
                fullName = repoInfo["full_name"] as? String,
                URLString = repoInfo["html_url"] as? String,
                description = repoInfo["description"] as? String,
                createdAtString = repoInfo["created_at"] as? String,
                isPrivate = repoInfo["private"] as? Bool,
                isFork = repoInfo["fork"] as? Bool
            else {
                continue
            }

            guard !isPrivate else {
                continue
            }

            guard !isFork else {
                continue
            }

            let createdAt = NSDate.dateWithISO08601String(createdAtString)

            let repo = GithubRepo(ID: ID, name: name, fullName: fullName, URLString: URLString, description: description, createdAt: createdAt)

            repos.append(repo)
        }

        return repos
    }

    let resource = githubResource(token: token, path: "/user/repos", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: githubBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: githubBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

// MARK: Dribbble Shot

struct DribbbleShot {
    let ID: Int
    let title: String
    let description: String?
    let htmlURLString: String

    struct Images {
        let hidpi: String?
        let normal: String
        let teaser: String
    }
    let images: Images

    let likesCount: Int
    let commentsCount: Int

    let createdAt: NSDate
}

// ref http://developer.dribbble.com/v1/

func dribbbleShotsWithToken(token: String, failureHandler: ((Reason, String?) -> Void)?, completion: [DribbbleShot] -> Void) {

    let requestParameters = [
        "timeframe": "month",
        "sort": "recent",
    ]

    let parse: JSONDictionary -> [DribbbleShot]? = { data in

        //println("dribbbleShotsWithToken data: \(data)")

        guard let shotsData = data["data"] as? [JSONDictionary] else {
            return nil
        }

        var shots = [DribbbleShot]()

        for shotInfo in shotsData {
            if let
                ID = shotInfo["id"] as? Int,
                title = shotInfo["title"] as? String,
                htmlURLString = shotInfo["html_url"] as? String,
                imagesInfo = shotInfo["images"] as? JSONDictionary,
                likesCount = shotInfo["likes_count"] as? Int,
                commentsCount = shotInfo["comments_count"] as? Int,
                createdAtString = shotInfo["created_at"] as? String {

                    let createdAt = NSDate.dateWithISO08601String(createdAtString)

                    if let
                        normal = imagesInfo["normal"] as? String,
                        teaser = imagesInfo["teaser"] as? String {
                            
                            let hidpi = imagesInfo["hidpi"] as? String
                            
                            let description = shotInfo["description"] as? String

                            let images = DribbbleShot.Images(hidpi: hidpi, normal: normal, teaser: teaser)

                            let shot = DribbbleShot(ID: ID, title: title, description: description, htmlURLString: htmlURLString, images: images, likesCount: likesCount, commentsCount: commentsCount, createdAt: createdAt)

                            shots.append(shot)
                    }
            }
        }

        return shots
    }

    let resource = dribbbleResource(token: token, path: "/v1/user/shots", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: dribbbleBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: dribbbleBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

// MARK: Instagram Media

struct InstagramMedia {
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

    let createdAt: NSDate
}

// ref https://instagram.com/developer/endpoints/users/

func instagramMediasWithToken(token: String, failureHandler: ((Reason, String?) -> Void)?, completion: [InstagramMedia] -> Void) {

    let requestParameters = [
        "access_token": token,
    ]

    let parse: JSONDictionary -> [InstagramMedia]? = { data in

        //println("instagramMediasWithToken data: \(data)")

        guard let mediasData = data["data"] as? [JSONDictionary] else {
            return nil
        }

        var medias = [InstagramMedia]()

        for mediaInfo in mediasData {
            if let
                ID = mediaInfo["id"] as? String,
                linkURLString = mediaInfo["link"] as? String,
                imagesInfo = mediaInfo["images"] as? JSONDictionary,
                likesInfo = mediaInfo["likes"] as? JSONDictionary,
                commentsInfo = mediaInfo["comments"] as? JSONDictionary,
                userInfo = mediaInfo["user"] as? JSONDictionary,
                createdAtString = mediaInfo["created_time"] as? String {

                    let createdAt = NSDate(timeIntervalSince1970: (createdAtString as NSString).doubleValue)

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

                            let images = InstagramMedia.Images(lowResolution: lowResolution, standardResolution: standardResolution, thumbnail: thumbnail)

                            let media = InstagramMedia(ID: ID, linkURLString: linkURLString, images: images, likesCount: likesCount, commentsCount: commentsCount, username: username, createdAt: createdAt)

                            medias.append(media)
                    }
            }
        }

        return medias
    }

    let resource = instagramResource(token: token, path: "/v1/users/self/feed", method: .GET, requestParameters: requestParameters, parse: parse)

    if let failureHandler = failureHandler {
        apiRequest({_ in}, baseURL: instagramBaseURL, resource: resource, failure: failureHandler, completion: completion)
    } else {
        apiRequest({_ in}, baseURL: instagramBaseURL, resource: resource, failure: defaultFailureHandler, completion: completion)
    }
}

// MARK: Sync

func syncSocialWorksToMessagesForYepTeam() {

    tokensOfSocialAccounts(failureHandler: nil, completion: { tokensOfSocialAccounts in
        //println("tokensOfSocialAccounts: \(tokensOfSocialAccounts)")

        dispatch_async(dispatch_get_main_queue()) {

            guard let realm = try? Realm() else {
                return
            }

            func messageIDsFromSyncSocialWorkPiece(socialWorkPiece: SocialWorkPiece, yepTeam: User, inRealm realm: Realm) -> [String] {

                let messageID = socialWorkPiece.messageID

                var message = messageWithMessageID(messageID, inRealm: realm)

                guard message == nil else {
                    return []
                }

                if message == nil {
                    let newMessage = Message()
                    newMessage.messageID = messageID
                    newMessage.mediaType = MessageMediaType.SocialWork.rawValue

                    let socialWork = MessageSocialWork()
                    socialWork.type = socialWorkPiece.messageSocialWorkType.rawValue

                    switch socialWorkPiece {
                    case .Github(let repo):

                        let repoID = repo.ID
                        var socialWorkGithubRepo = SocialWorkGithubRepo.getWithRepoID(repoID, inRealm: realm)

                        if socialWorkGithubRepo == nil {
                            let newSocialWorkGithubRepo = SocialWorkGithubRepo()
                            newSocialWorkGithubRepo.fillWithGithubRepo(repo)

                            realm.add(newSocialWorkGithubRepo)

                            socialWorkGithubRepo = newSocialWorkGithubRepo
                        }

                        socialWork.githubRepo = socialWorkGithubRepo

                    case .Dribbble(let shot):

                        let shotID = shot.ID
                        var socialWorkDribbbleShot = SocialWorkDribbbleShot.getWithShotID(shotID, inRealm: realm)

                        if socialWorkDribbbleShot == nil {
                            let newSocialWorkDribbbleShot = SocialWorkDribbbleShot()
                            newSocialWorkDribbbleShot.fillWithDribbbleShot(shot)

                            realm.add(newSocialWorkDribbbleShot)

                            socialWorkDribbbleShot = newSocialWorkDribbbleShot
                        }

                        socialWork.dribbbleShot = socialWorkDribbbleShot

                    case .Instagram:
                        break
                    }

                    newMessage.socialWork = socialWork

                    realm.add(newMessage)

                    message = newMessage
                }

                if let message = message {

                    message.fromFriend = yepTeam

                    var conversation = yepTeam.conversation

                    if conversation == nil {
                        let newConversation = Conversation()

                        newConversation.type = ConversationType.OneToOne.rawValue
                        newConversation.withFriend = yepTeam

                        realm.add(newConversation)

                        conversation = newConversation
                    }

                    if let conversation = conversation {

                        message.conversation = conversation

                        var sectionDateMessageID: String?
                        tryCreateSectionDateMessageInConversation(conversation, beforeMessage: message, inRealm: realm) { sectionDateMessage in
                            realm.add(sectionDateMessage)
                            sectionDateMessageID = sectionDateMessage.messageID
                        }

                        var messageIDs = [String]()
                        if let sectionDateMessageID = sectionDateMessageID {
                            messageIDs.append(sectionDateMessageID)
                        }
                        messageIDs.append(message.messageID)

                        return messageIDs

                    } else {
                        message.deleteInRealm(realm)
                    }
                }

                return []
            }

            let yepTeamUsername = "yep_team"

            func yepTeamFromDiscoveredUser(discoveredUser: DiscoveredUser, inRealm realm: Realm) -> User? {

                var yepTeam = userWithUsername(yepTeamUsername, inRealm: realm)

                if yepTeam == nil {
                    let newYepTeam = User()
                    newYepTeam.userID = discoveredUser.id
                    newYepTeam.username = discoveredUser.username ?? ""
                    newYepTeam.nickname = discoveredUser.nickname
                    newYepTeam.introduction = discoveredUser.introduction ?? ""
                    newYepTeam.avatarURLString = discoveredUser.avatarURLString
                    newYepTeam.badge = discoveredUser.badge ?? ""

                    newYepTeam.friendState = UserFriendState.Yep.rawValue

                    realm.add(newYepTeam)

                    yepTeam = newYepTeam
                }

                return yepTeam
            }

            if let githubToken = tokensOfSocialAccounts.githubToken {

                githubReposWithToken(githubToken, failureHandler: nil, completion: { githubRepos in
                    println("githubRepos count: \(githubRepos.count)")

                    dispatch_async(dispatch_get_main_queue()) {

                        guard let realm = try? Realm() else {
                            return
                        }

                        var messageIDs = [String]()

                        realm.beginWrite()

                        // 同步最新的几个
                        var i = 0
                        for repo in githubRepos {
                            if i++ >= 3 {
                                break
                            }

                            if let yepTeam = userWithUsername(yepTeamUsername, inRealm: realm) {
                                messageIDs += messageIDsFromSyncSocialWorkPiece(SocialWorkPiece.Github(repo), yepTeam: yepTeam, inRealm: realm)

                            } else {
                                discoverUserByUsername(yepTeamUsername, failureHandler: nil, completion: { discoveredUser in
                                    dispatch_async(dispatch_get_main_queue()) {

                                        guard let realm = try? Realm() else {
                                            return
                                        }

                                        var messageIDs = [String]()

                                        realm.beginWrite()

                                        if let yepTeam = yepTeamFromDiscoveredUser(discoveredUser, inRealm: realm) {
                                            messageIDs += messageIDsFromSyncSocialWorkPiece(SocialWorkPiece.Github(repo), yepTeam: yepTeam, inRealm: realm)
                                        }

                                        let _ = try? realm.commitWrite()

                                        // 通知更新 UI
                                        tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: .New)
                                    }
                                })
                            }
                        }

                        let _ = try? realm.commitWrite()

                        // 通知更新 UI
                        tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: .New)
                    }
                })
            }

            if let dribbbleToken = tokensOfSocialAccounts.dribbbleToken {

                dribbbleShotsWithToken(dribbbleToken, failureHandler: nil, completion: { dribbbleShots in
                    println("dribbbleShots count: \(dribbbleShots.count)")

                    dispatch_async(dispatch_get_main_queue()) {

                        guard let realm = try? Realm() else {
                            return
                        }

                        var messageIDs = [String]()

                        realm.beginWrite()

                        // 同步最新的几个
                        var i = 0
                        for shot in dribbbleShots {
                            if i++ >= 3 {
                                break
                            }

                            if let yepTeam = userWithUsername(yepTeamUsername, inRealm: realm) {
                                messageIDs += messageIDsFromSyncSocialWorkPiece(SocialWorkPiece.Dribbble(shot), yepTeam: yepTeam, inRealm: realm)

                            } else {
                                discoverUserByUsername(yepTeamUsername, failureHandler: nil, completion: { discoveredUser in
                                    dispatch_async(dispatch_get_main_queue()) {

                                        guard let realm = try? Realm() else {
                                            return
                                        }

                                        var messageIDs = [String]()

                                        realm.beginWrite()

                                        if let yepTeam = yepTeamFromDiscoveredUser(discoveredUser, inRealm: realm) {
                                            messageIDs += messageIDsFromSyncSocialWorkPiece(SocialWorkPiece.Dribbble(shot), yepTeam: yepTeam, inRealm: realm)
                                        }

                                        let _ = try? realm.commitWrite()

                                        // 通知更新 UI
                                        tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: .New)
                                    }
                                })
                            }
                        }

                        let _ = try? realm.commitWrite()

                        // 通知更新 UI
                        tryPostNewMessagesReceivedNotificationWithMessageIDs(messageIDs, messageAge: .New)
                    }
               })
            }

            /*
            if let instagramToken = tokensOfSocialAccounts.instagramToken {

                instagramMediasWithToken(instagramToken, failureHandler: nil, completion: { instagramMedias in
                    println("instagramMedias count: \(instagramMedias.count)")
                })
            }
            */
        }
    })
}


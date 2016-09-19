//
//  SocialWorkService.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation
import YepNetworking
import RealmSwift

private let githubBaseURL = URL(string: "https://api.github.com")!
private let dribbbleBaseURL = URL(string: "https://api.dribbble.com")!
private let instagramBaseURL = URL(string: "https://api.instagram.com")!

private func githubResource<A>(token: String, path: String, method: YepNetworking.Method, requestParameters: JSONDictionary, parse: (JSONDictionary) -> A?) -> Resource<A> {

    let jsonParse: (Data) -> A? = { data in
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

private func dribbbleResource<A>(token: String, path: String, method: YepNetworking.Method, requestParameters: JSONDictionary, parse: (JSONDictionary) -> A?) -> Resource<A> {

    let jsonParse: (Data) -> A? = { data in
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

private func instagramResource<A>(token: String, path: String, method: YepNetworking.Method, requestParameters: JSONDictionary, parse: (JSONDictionary) -> A?) -> Resource<A> {

    let jsonParse: (Data) -> A? = { data in
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

public enum SocialWorkPiece {
    case github(GithubRepo)
    case dribbble(DribbbleShot)
    case instagram(InstagramMedia)

    public var messageSocialWorkType: MessageSocialWorkType {
        switch self {
        case .github:
            return MessageSocialWorkType.githubRepo
        case .dribbble:
            return MessageSocialWorkType.dribbbleShot
        case .instagram:
            return MessageSocialWorkType.instagramMedia
        }
    }

    public var messageID: String {
        switch self {
        case .github(let repo):
            return "github_repo_\(repo.ID)"
        case .dribbble(let shot):
            return "dribbble_shot_\(shot.ID)"
        case .instagram(let media):
            return "instagram_media_\(media.ID)"
        }
    }
}

// MARK: Github Repo

public struct GithubRepo {
    public let ID: Int
    public let name: String
    public let fullName: String
    public let URLString: String
    public let description: String

    public let createdAt: Date
}

// ref https://developer.github.com/v3/

public func githubReposWithToken(_ token: String, failureHandler: ((Reason, String?) -> Void)?, completion: ([GithubRepo]) -> Void) {

    let requestParameters = [
        "type": "owner",
        "sort": "created",
    ]

    let parse: (JSONDictionary) -> [GithubRepo]? = { data in

        //println("githubReposWithToken data: \(data)")

        guard let reposData = data["data"] as? [JSONDictionary] else {
            return nil
        }

        var repos = [GithubRepo]()

        for repoInfo in reposData {

            guard let
                ID = repoInfo["id"] as? Int,
                let name = repoInfo["name"] as? String,
                let fullName = repoInfo["full_name"] as? String,
                let URLString = repoInfo["html_url"] as? String,
                let description = repoInfo["description"] as? String,
                let createdAtString = repoInfo["created_at"] as? String,
                let isPrivate = repoInfo["private"] as? Bool,
                let isFork = repoInfo["fork"] as? Bool
            else {
                continue
            }

            guard !isPrivate else {
                continue
            }

            guard !isFork else {
                continue
            }

            let createdAt = Date.dateWithISO08601String(createdAtString)

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

public struct DribbbleShot {
    public let ID: Int
    public let title: String
    public let description: String?
    public let htmlURLString: String

    public struct Images {
        public let hidpi: String?
        public let normal: String
        public let teaser: String
    }
    public let images: Images

    public let likesCount: Int
    public let commentsCount: Int

    public let createdAt: Date
}

// ref http://developer.dribbble.com/v1/

public func dribbbleShotsWithToken(_ token: String, failureHandler: ((Reason, String?) -> Void)?, completion: ([DribbbleShot]) -> Void) {

    let requestParameters = [
        "timeframe": "month",
        "sort": "recent",
    ]

    let parse: (JSONDictionary) -> [DribbbleShot]? = { data in

        //println("dribbbleShotsWithToken data: \(data)")

        guard let shotsData = data["data"] as? [JSONDictionary] else {
            return nil
        }

        var shots = [DribbbleShot]()

        for shotInfo in shotsData {
            if let
                ID = shotInfo["id"] as? Int,
                let title = shotInfo["title"] as? String,
                let htmlURLString = shotInfo["html_url"] as? String,
                let imagesInfo = shotInfo["images"] as? JSONDictionary,
                let likesCount = shotInfo["likes_count"] as? Int,
                let commentsCount = shotInfo["comments_count"] as? Int,
                let createdAtString = shotInfo["created_at"] as? String {

                    let createdAt = Date.dateWithISO08601String(createdAtString)

                    if let
                        normal = imagesInfo["normal"] as? String,
                        let teaser = imagesInfo["teaser"] as? String {
                            
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

public struct InstagramMedia {
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

    public let createdAt: Date
}

// ref https://instagram.com/developer/endpoints/users/

public func instagramMediasWithToken(_ token: String, failureHandler: ((Reason, String?) -> Void)?, completion: ([InstagramMedia]) -> Void) {

    let requestParameters = [
        "access_token": token,
    ]

    let parse: (JSONDictionary) -> [InstagramMedia]? = { data in

        //println("instagramMediasWithToken data: \(data)")

        guard let mediasData = data["data"] as? [JSONDictionary] else {
            return nil
        }

        var medias = [InstagramMedia]()

        for mediaInfo in mediasData {
            if let
                ID = mediaInfo["id"] as? String,
                let linkURLString = mediaInfo["link"] as? String,
                let imagesInfo = mediaInfo["images"] as? JSONDictionary,
                let likesInfo = mediaInfo["likes"] as? JSONDictionary,
                let commentsInfo = mediaInfo["comments"] as? JSONDictionary,
                let userInfo = mediaInfo["user"] as? JSONDictionary,
                let createdAtString = mediaInfo["created_time"] as? String {

                    let createdAt = Date(timeIntervalSince1970: (createdAtString as NSString).doubleValue)

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

public func syncSocialWorksToMessagesForYepTeam() {

    tokensOfSocialAccounts(failureHandler: nil, completion: { tokensOfSocialAccounts in
        //println("tokensOfSocialAccounts: \(tokensOfSocialAccounts)")

        SafeDispatch.async {

            guard let realm = try? Realm() else {
                return
            }

            func messageIDsFromSyncSocialWorkPiece(_ socialWorkPiece: SocialWorkPiece, yepTeam: User, inRealm realm: Realm) -> [String] {

                let messageID = socialWorkPiece.messageID

                var message = messageWithMessageID(messageID, inRealm: realm)

                guard message == nil else {
                    return []
                }

                if message == nil {
                    let newMessage = Message()
                    newMessage.messageID = messageID
                    newMessage.mediaType = MessageMediaType.socialWork.rawValue

                    let socialWork = MessageSocialWork()
                    socialWork.type = socialWorkPiece.messageSocialWorkType.rawValue

                    switch socialWorkPiece {

                    case .github(let repo):

                        let repoID = repo.ID
                        var socialWorkGithubRepo = SocialWorkGithubRepo.getWithRepoID(repoID, inRealm: realm)

                        if socialWorkGithubRepo == nil {
                            let newSocialWorkGithubRepo = SocialWorkGithubRepo()
                            newSocialWorkGithubRepo.fillWithGithubRepo(repo)

                            realm.add(newSocialWorkGithubRepo)

                            socialWorkGithubRepo = newSocialWorkGithubRepo
                        }

                        socialWork.githubRepo = socialWorkGithubRepo

                    case .dribbble(let shot):

                        let shotID = shot.ID
                        var socialWorkDribbbleShot = SocialWorkDribbbleShot.getWithShotID(shotID, inRealm: realm)

                        if socialWorkDribbbleShot == nil {
                            let newSocialWorkDribbbleShot = SocialWorkDribbbleShot()
                            newSocialWorkDribbbleShot.fillWithDribbbleShot(shot)

                            realm.add(newSocialWorkDribbbleShot)

                            socialWorkDribbbleShot = newSocialWorkDribbbleShot
                        }

                        socialWork.dribbbleShot = socialWorkDribbbleShot

                    case .instagram:
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

                        newConversation.type = ConversationType.oneToOne.rawValue
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

            func yepTeamFromDiscoveredUser(_ discoveredUser: DiscoveredUser, inRealm realm: Realm) -> User? {

                var yepTeam = userWithUsername(yepTeamUsername, inRealm: realm)

                if yepTeam == nil {
                    let newYepTeam = User()
                    newYepTeam.userID = discoveredUser.id
                    newYepTeam.username = discoveredUser.username ?? ""
                    newYepTeam.nickname = discoveredUser.nickname
                    newYepTeam.introduction = discoveredUser.introduction ?? ""
                    newYepTeam.avatarURLString = discoveredUser.avatarURLString
                    newYepTeam.badge = discoveredUser.badge ?? ""

                    newYepTeam.friendState = UserFriendState.yep.rawValue

                    realm.add(newYepTeam)

                    yepTeam = newYepTeam
                }

                return yepTeam
            }

            if let githubToken = tokensOfSocialAccounts.githubToken {

                githubReposWithToken(githubToken, failureHandler: nil, completion: { githubRepos in
                    println("githubRepos count: \(githubRepos.count)")

                    SafeDispatch.async {

                        guard let realm = try? Realm() else {
                            return
                        }

                        var messageIDs = [String]()

                        realm.beginWrite()

                        // 同步最新的几个
                        for repo in githubRepos.head(to: Config.SocialWork.syncCountMax) {

                            if let yepTeam = userWithUsername(yepTeamUsername, inRealm: realm) {
                                messageIDs += messageIDsFromSyncSocialWorkPiece(SocialWorkPiece.Github(repo), yepTeam: yepTeam, inRealm: realm)

                            } else {
                                discoverUserByUsername(yepTeamUsername, failureHandler: nil, completion: { discoveredUser in
                                    SafeDispatch.async {

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

                    SafeDispatch.async {

                        guard let realm = try? Realm() else {
                            return
                        }

                        var messageIDs = [String]()

                        realm.beginWrite()

                        // 同步最新的几个
                        for shot in dribbbleShots.head(to: Config.SocialWork.syncCountMax) {

                            if let yepTeam = userWithUsername(yepTeamUsername, inRealm: realm) {
                                messageIDs += messageIDsFromSyncSocialWorkPiece(SocialWorkPiece.Dribbble(shot), yepTeam: yepTeam, inRealm: realm)

                            } else {
                                discoverUserByUsername(yepTeamUsername, failureHandler: nil, completion: { discoveredUser in
                                    SafeDispatch.async {

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


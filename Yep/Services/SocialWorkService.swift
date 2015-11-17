//
//  SocialWorkService.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation

private let githubBaseURL = NSURL(string: "https://api.github.com")!
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

struct GithubRepo {
    let ID: Int
    let name: String
    let fullName: String
    let URLString: String
    let description: String

    //let createdAt: NSDate
}

func githubReposWithToken(token: String, failureHandler: ((Reason, String?) -> Void)?, completion: [GithubRepo] -> Void) {

    let requestParameters = [
        "type": "public",
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
                description = repoInfo["description"] as? String

            else {
                continue
            }

            let repo = GithubRepo(ID: ID, name: name, fullName: fullName, URLString: URLString, description: description)

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

    //let createdAt: NSDate
}

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

                            let images = InstagramMedia.Images(lowResolution: lowResolution, standardResolution: standardResolution, thumbnail: thumbnail)

                            let media = InstagramMedia(ID: ID, linkURLString: linkURLString, images: images, likesCount: likesCount, commentsCount: commentsCount, username: username)

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


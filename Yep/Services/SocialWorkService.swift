//
//  SocialWorkService.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import Foundation

private let githubBaseURL = NSURL(string: "https://api.github.com")!

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


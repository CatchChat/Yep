//
//  Service.swift
//  Yep
//
//  Created by NIX on 16/5/20.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import CoreLocation
import YepNetworking

#if STAGING
let yepBaseURL = NSURL(string: "https://park-staging.catchchatchina.com/api")!
#else
let yepBaseURL = NSURL(string: "https://api.soyep.com")!
#endif

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

struct Skill {

    let id: String
    let name: String
    let localName: String
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


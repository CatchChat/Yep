//
//  ConversationFeed.swift
//  Yep
//
//  Created by NIX on 16/6/28.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import CoreLocation
import YepKit
import RealmSwift

enum ConversationFeed {

    case DiscoveredFeedType(DiscoveredFeed)
    case FeedType(Feed)

    var feedID: String? {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.id

        case .FeedType(let feed):
            guard !feed.invalidated else {
                return nil
            }
            return feed.feedID
        }
    }

    var body: String {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.body

        case .FeedType(let feed):
            return feed.body
        }
    }

    var creator: User? {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            guard let realm = try? Realm() else {
                return nil
            }
            realm.beginWrite()
            let user = getOrCreateUserWithDiscoverUser(discoveredFeed.creator, inRealm: realm)
            let _ = try? realm.commitWrite()

            return user

        case .FeedType(let feed):
            return feed.creator
        }
    }

    var distance: Double? {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.distance

        case .FeedType(let feed):
            return feed.distance
        }
    }

    var kind: FeedKind? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.kind
        case .FeedType(let feed):
            return FeedKind(rawValue: feed.kind)
        }
    }

    var hasSocialImage: Bool {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.hasSocialImage
        case .FeedType(let feed):
            if let _ = feed.socialWork?.dribbbleShot?.imageURLString {
                return true
            }
        }

        return false
    }

    var hasMapImage: Bool {

        if let kind = kind {
            switch kind {
            case .Location:
                return true
            default:
                return false
            }
        }

        return false
    }

    var hasAttachment: Bool {

        guard let kind = kind else {
            return false
        }

        return kind != .Text
    }

    var githubRepoName: String? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Github(githubRepo) = attachment {
                    return githubRepo.name
                }
            }
        case .FeedType(let feed):
            return feed.socialWork?.githubRepo?.name
        }

        return nil
    }

    var githubRepoDescription: String? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Github(githubRepo) = attachment {
                    return githubRepo.description
                }
            }
        case .FeedType(let feed):
            return feed.socialWork?.githubRepo?.repoDescription
        }

        return nil
    }

    var githubRepoURL: NSURL? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Github(githubRepo) = attachment {
                    return NSURL(string: githubRepo.URLString)
                }
            }
        case .FeedType(let feed):
            if let URLString = feed.socialWork?.githubRepo?.URLString {
                return NSURL(string: URLString)
            }
        }

        return nil
    }

    var dribbbleShotImageURL: NSURL? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Dribbble(dribbbleShot) = attachment {
                    return NSURL(string: dribbbleShot.imageURLString)
                }
            }
        case .FeedType(let feed):
            if let imageURLString = feed.socialWork?.dribbbleShot?.imageURLString {
                return NSURL(string: imageURLString)
            }
        }

        return nil
    }

    var dribbbleShotURL: NSURL? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Dribbble(dribbbleShot) = attachment {
                    return NSURL(string: dribbbleShot.htmlURLString)
                }
            }
        case .FeedType(let feed):
            if let htmlURLString = feed.socialWork?.dribbbleShot?.htmlURLString {
                return NSURL(string: htmlURLString)
            }
        }

        return nil
    }

    var audioMetaInfo: (duration: NSTimeInterval, samples: [CGFloat])? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Audio(audioInfo) = attachment {
                    return (audioInfo.duration, audioInfo.sampleValues)
                }
            }
        case .FeedType(let feed):
            if let audioMetaInfo = feed.audio?.audioMetaInfo {
                return audioMetaInfo
            }
        }

        return nil
    }
    
    var locationName: String? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Location(locationInfo) = attachment {
                    return locationInfo.name
                }
            }
        case .FeedType(let feed):
            if let location = feed.location {
                return location.name
            }
        }

        return nil
    }

    var locationCoordinate: CLLocationCoordinate2D? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .Location(locationInfo) = attachment {
                    return locationInfo.coordinate
                }
            }
        case .FeedType(let feed):
            if let location = feed.location {
                return location.coordinate?.locationCoordinate
            }
        }

        return nil
    }

    var openGraphInfo: OpenGraphInfoType? {

        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .URL(openGraphInfo) = attachment {
                    return openGraphInfo
                }
            }
        case .FeedType(let feed):
            if let openGraphInfo = feed.openGraphInfo {
                return openGraphInfo
            }
        }

        return nil
    }

    var attachments: [Attachment] {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):

            if let attachment = discoveredFeed.attachment {
                if case let .Images(attachments) = attachment {
                    return attachmentFromDiscoveredAttachment(attachments)
                }
            }

            return []

        case .FeedType(let feed):
            return Array(feed.attachments)
        }
    }

    var createdUnixTime: NSTimeInterval {
        switch self {
        case .DiscoveredFeedType(let discoveredFeed):
            return discoveredFeed.createdUnixTime

        case .FeedType(let feed):
            return feed.createdUnixTime
        }
    }
}


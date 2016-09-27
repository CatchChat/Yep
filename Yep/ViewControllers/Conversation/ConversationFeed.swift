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

    case discoveredFeedType(DiscoveredFeed)
    case feedType(Feed)

    var feedID: String? {
        switch self {
        case .discoveredFeedType(let discoveredFeed):
            return discoveredFeed.id

        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            return feed.feedID
        }
    }

    var body: String {
        switch self {
        case .discoveredFeedType(let discoveredFeed):
            return discoveredFeed.body

        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return ""
            }
            return feed.body
        }
    }

    var creator: User? {
        switch self {
        case .discoveredFeedType(let discoveredFeed):
            guard let realm = try? Realm() else {
                return nil
            }
            realm.beginWrite()
            let user = getOrCreateUserWithDiscoverUser(discoveredFeed.creator, inRealm: realm)
            let _ = try? realm.commitWrite()

            return user

        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            return feed.creator
        }
    }

    var distance: Double? {
        switch self {
        case .discoveredFeedType(let discoveredFeed):
            return discoveredFeed.distance

        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            return feed.distance
        }
    }

    var kind: FeedKind? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            return discoveredFeed.kind
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            return FeedKind(rawValue: feed.kind)
        }
    }

    var hasSocialImage: Bool {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            return discoveredFeed.hasSocialImage
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return false
            }
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
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .github(githubRepo) = attachment {
                    return githubRepo.name
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            return feed.socialWork?.githubRepo?.name
        }

        return nil
    }

    var githubRepoDescription: String? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .github(githubRepo) = attachment {
                    return githubRepo.description
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            return feed.socialWork?.githubRepo?.repoDescription
        }

        return nil
    }

    var githubRepoURL: URL? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .github(githubRepo) = attachment {
                    return URL(string: githubRepo.URLString)
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            if let URLString = feed.socialWork?.githubRepo?.URLString {
                return URL(string: URLString)
            }
        }

        return nil
    }

    var dribbbleShotImageURL: URL? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .dribbble(dribbbleShot) = attachment {
                    return URL(string: dribbbleShot.imageURLString)
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            if let imageURLString = feed.socialWork?.dribbbleShot?.imageURLString {
                return URL(string: imageURLString)
            }
        }

        return nil
    }

    var dribbbleShotURL: URL? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .dribbble(dribbbleShot) = attachment {
                    return URL(string: dribbbleShot.htmlURLString)
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            if let htmlURLString = feed.socialWork?.dribbbleShot?.htmlURLString {
                return URL(string: htmlURLString)
            }
        }

        return nil
    }

    var audioMetaInfo: (duration: TimeInterval, samples: [CGFloat])? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .audio(audioInfo) = attachment {
                    return (audioInfo.duration, audioInfo.sampleValues)
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            if let audioMetaInfo = feed.audio?.audioMetaInfo {
                return audioMetaInfo
            }
        }

        return nil
    }
    
    var locationName: String? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .location(locationInfo) = attachment {
                    return locationInfo.name
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            if let location = feed.location {
                return location.name
            }
        }

        return nil
    }

    var locationCoordinate: CLLocationCoordinate2D? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .location(locationInfo) = attachment {
                    return locationInfo.coordinate
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            if let location = feed.location {
                return location.coordinate?.locationCoordinate
            }
        }

        return nil
    }

    var openGraphInfo: OpenGraphInfoType? {

        switch self {
        case .discoveredFeedType(let discoveredFeed):
            if let attachment = discoveredFeed.attachment {
                if case let .url(openGraphInfo) = attachment {
                    return openGraphInfo
                }
            }
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return nil
            }
            if let openGraphInfo = feed.openGraphInfo {
                return openGraphInfo
            }
        }

        return nil
    }

    var attachments: [Attachment] {
        switch self {
        case .discoveredFeedType(let discoveredFeed):

            if let attachment = discoveredFeed.attachment {
                if case let .images(attachments) = attachment {
                    return attachmentFromDiscoveredAttachment(attachments)
                }
            }

            return []

        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return []
            }
            return Array(feed.attachments)
        }
    }

    var createdUnixTime: TimeInterval {
        switch self {
        case .discoveredFeedType(let discoveredFeed):
            return discoveredFeed.createdUnixTime
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return Date().timeIntervalSince1970
            }
            return feed.createdUnixTime
        }
    }

    var timeString: String {
        switch self {
        case .discoveredFeedType(let discoveredFeed):
            return discoveredFeed.timeString
        case .feedType(let feed):
            guard !feed.isInvalidated else {
                return ""
            }
            let date = Date(timeIntervalSince1970: feed.createdUnixTime)
            let timeString = Config.timeAgoAction?(date) ?? ""
            return timeString
        }
    }
}


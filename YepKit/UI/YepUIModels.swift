//
//  YepUIModels.swift
//  Yep
//
//  Created by NIX on 16/5/23.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import Foundation
import CoreLocation

public enum MessageToolbarState: Int, CustomStringConvertible {

    case `default`
    case beginTextInput
    case textInputing
    case voiceRecord

    public var description: String {
        switch self {
        case .default:
            return "Default"
        case .beginTextInput:
            return "BeginTextInput"
        case .textInputing:
            return "TextInputing"
        case .voiceRecord:
            return "VoiceRecord"
        }
    }

    public var isAtBottom: Bool {
        switch self {
        case .default:
            return true
        case .beginTextInput, .textInputing:
            return false
        case .voiceRecord:
            return true
        }
    }
}

open class SkillCellSkill: NSObject {

    open let ID: String
    open let localName: String
    open let coverURLString: String?

    public enum Category: String {
        case art = "Art"
        case technology = "Technology"
        case sport = "Sport"
        case lifeStyle = "Life Style"

        var gradientImage: UIImage? {
            switch self {
            case .art:
                return UIImage(named: "gradient_art")
            case .technology:
                return UIImage(named: "gradient_tech")
            case .sport:
                return UIImage(named: "gradient_sport")
            case .lifeStyle:
                return UIImage(named: "gradient_life")
            }
        }
    }
    open let category: Category

    public init(ID: String, localName: String, coverURLString: String?, category: Category?) {
        self.ID = ID
        self.localName = localName
        self.coverURLString = coverURLString
        self.category = category ?? .art
    }
}

public enum SocialAccount: String {

    case Dribbble = "dribbble"
    case Github = "github"
    case Instagram = "instagram"
    case Behance = "behance"
    
    public var name: String {
        
        switch self {
        case .Dribbble:
            return "Dribbble"
        case .Github:
            return "GitHub"
        case .Behance:
            return "Behance"
        case .Instagram:
            return "Instagram"
        }
    }

    public var segue: String {

        switch self {
        case .Dribbble:
            return "Dribbble"
        case .Github:
            return "Github"
        case .Behance:
            return "Behance"
        case .Instagram:
            return "Instagram"
        }
    }
    
    public var tintColor: UIColor {
        
        switch self {
        case .Dribbble:
            return UIColor(red:0.91, green:0.28, blue:0.5, alpha:1)
        case .Github:
            return UIColor.black
        case .Behance:
            return UIColor(red:0, green:0.46, blue:1, alpha:1)
        case .Instagram:
            return UIColor(red:0.15, green:0.36, blue:0.54, alpha:1)
        }
    }

    public static let disabledColor: UIColor = UIColor.lightGray
    
    public var iconName: String {
        
        switch self {
        case .Dribbble:
            return "icon_dribbble"
        case .Github:
            return "icon_github"
        case .Behance:
            return "icon_behance"
        case .Instagram:
            return "icon_instagram"
        }
    }
    
    public var authURL: URL {
        
        switch self {
        case .Dribbble:
            return URL(string: "\(yepBaseURL.absoluteString)/auth/dribbble")!
        case .Github:
            return URL(string: "\(yepBaseURL.absoluteString)/auth/github")!
        case .Behance:
            return URL(string: "\(yepBaseURL.absoluteString)/auth/behance")!
        case .Instagram:
            return URL(string: "\(yepBaseURL.absoluteString)/auth/instagram")!
        }
    }
}

public enum ProfileUser {

    case discoveredUserType(DiscoveredUser)
    case userType(User)

    public var userID: String {

        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.id
        case .userType(let user):
            return user.userID
        }
    }

    public var username: String? {

        var username: String? = nil
        switch self {
        case .discoveredUserType(let discoveredUser):
            username = discoveredUser.username
        case .userType(let user):
            if !user.username.isEmpty {
                username = user.username
            }
        }

        return username
    }

    public var nickname: String {

        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.nickname
        case .userType(let user):
            return user.nickname
        }
    }

    public var avatarURLString: String? {

        var avatarURLString: String? = nil
        switch self {
        case .discoveredUserType(let discoveredUser):
            avatarURLString = discoveredUser.avatarURLString
        case .userType(let user):
            if !user.avatarURLString.isEmpty {
                avatarURLString = user.avatarURLString
            }
        }
        
        return avatarURLString
    }

    public var blogURL: URL? {

        var blogURLString: String? = nil
        switch self {
        case .discoveredUserType(let discoveredUser):
            blogURLString = discoveredUser.blogURLString
        case .userType(let user):
            if !user.blogURLString.isEmpty {
                blogURLString = user.blogURLString
            }
        }

        return blogURLString.flatMap({ URL(string: $0) })
    }

    public var blogTitle: String? {

        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.blogTitle
        case .userType(let user):
            if !user.blogTitle.isEmpty {
                return user.blogTitle
            }
        }

        return nil
    }

    public var isMe: Bool {

        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.isMe
        case .userType(let user):
            return user.isMe
        }
    }

    public func enabledSocialAccount(_ socialAccount: SocialAccount) -> Bool {
        var accountEnabled = false

        let providerName = socialAccount.rawValue

        switch self {

        case .discoveredUserType(let discoveredUser):
            for provider in discoveredUser.socialAccountProviders {
                if (provider.name == providerName) && provider.enabled {

                    accountEnabled = true

                    break
                }
            }

        case .userType(let user):
            for provider in user.socialAccountProviders {
                if (provider.name == providerName) && provider.enabled {

                    accountEnabled = true

                    break
                }
            }
        }

        return accountEnabled
    }

    public var masterSkillsCount: Int {

        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.masterSkills.count
        case .userType(let user):
            return Int(user.masterSkills.count)
        }
    }

    public var learningSkillsCount: Int {

        switch self {
        case .discoveredUserType(let discoveredUser):
            return discoveredUser.learningSkills.count
        case .userType(let user):
            return Int(user.learningSkills.count)
        }
    }

    public var providersCount: Int {

        switch self {

        case .discoveredUserType(let discoveredUser):
            return discoveredUser.socialAccountProviders.filter({ $0.enabled }).count

        case .userType(let user):

            if user.friendState == UserFriendState.me.rawValue {
                return user.socialAccountProviders.count

            } else {
                return user.socialAccountProviders.filter("enabled = true").count
            }
        }
    }

    public func cellSkillInSkillSet(_ skillSet: SkillSet, atIndexPath indexPath: IndexPath)  -> SkillCellSkill? {

        switch self {

        case .discoveredUserType(let discoveredUser):

            let skill: Skill?
            switch skillSet {
            case .master:
                skill = discoveredUser.masterSkills[safe: indexPath.item]
            case .learning:
                skill = discoveredUser.learningSkills[safe: indexPath.item]
            }

            if let skill = skill {
                return SkillCellSkill(ID: skill.id, localName: skill.localName, coverURLString: skill.coverURLString, category: skill.skillCategory)
            }

        case .userType(let user):

            let userSkill: UserSkill?
            switch skillSet {
            case .master:
                userSkill = user.masterSkills[safe: indexPath.item]
            case .learning:
                userSkill = user.learningSkills[safe: indexPath.item]
            }

            if let userSkill = userSkill {
                return SkillCellSkill(ID: userSkill.skillID, localName: userSkill.localName, coverURLString: userSkill.coverURLString, category: userSkill.skillCategory)
            }
        }

        return nil
    }

    public func providerNameWithIndex(_ index: Int) -> String? {

        var providerName: String?

        switch self {

        case .discoveredUserType(let discoveredUser):
            if let provider = discoveredUser.socialAccountProviders.filter({ $0.enabled })[safe: index] {
                providerName = provider.name
            }

        case .userType(let user):

            if user.friendState == UserFriendState.me.rawValue {
                if let provider = user.socialAccountProviders[safe: index] {
                    providerName = provider.name
                }

            } else {
                if let provider = user.socialAccountProviders.filter("enabled = true")[safe: index] {
                    providerName = provider.name
                }
            }
        }

        return providerName
    }
}

public enum PickLocationViewControllerLocation {

    public struct Info {
        public let coordinate: CLLocationCoordinate2D
        public var name: String?

        public init(coordinate: CLLocationCoordinate2D, name: String?) {
            self.coordinate = coordinate
            self.name = name
        }
    }

    case `default`(info: Info)
    case picked(info: Info)
    case selected(info: Info)

    public var info: Info {
        switch self {
        case .default(let locationInfo):
            return locationInfo
        case .picked(let locationInfo):
            return locationInfo
        case .selected(let locationInfo):
            return locationInfo
        }
    }

    public var isPicked: Bool {
        switch self {
        case .picked:
            return true
        default:
            return false
        }
    }
}


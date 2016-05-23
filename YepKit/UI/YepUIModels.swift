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

    case Default
    case BeginTextInput
    case TextInputing
    case VoiceRecord

    public var description: String {
        switch self {
        case .Default:
            return "Default"
        case .BeginTextInput:
            return "BeginTextInput"
        case .TextInputing:
            return "TextInputing"
        case .VoiceRecord:
            return "VoiceRecord"
        }
    }

    public var isAtBottom: Bool {
        switch self {
        case .Default:
            return true
        case .BeginTextInput, .TextInputing:
            return false
        case .VoiceRecord:
            return true
        }
    }
}

public class SkillCellSkill: NSObject {

    public let ID: String
    public let localName: String
    public let coverURLString: String?

    public enum Category: String {
        case Art = "Art"
        case Technology = "Technology"
        case Sport = "Sport"
        case LifeStyle = "Life Style"

        var gradientImage: UIImage? {
            switch self {
            case .Art:
                return UIImage(named: "gradient_art")
            case .Technology:
                return UIImage(named: "gradient_tech")
            case .Sport:
                return UIImage(named: "gradient_sport")
            case .LifeStyle:
                return UIImage(named: "gradient_life")
            }
        }
    }
    public let category: Category

    public init(ID: String, localName: String, coverURLString: String?, category: Category?) {
        self.ID = ID
        self.localName = localName
        self.coverURLString = coverURLString
        self.category = category ?? .Art
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
            return UIColor.blackColor()
        case .Behance:
            return UIColor(red:0, green:0.46, blue:1, alpha:1)
        case .Instagram:
            return UIColor(red:0.15, green:0.36, blue:0.54, alpha:1)
        }
    }

    public static let disabledColor: UIColor = UIColor.lightGrayColor()
    
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
    
    public var authURL: NSURL {
        
        switch self {
        case .Dribbble:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/dribbble")!
        case .Github:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/github")!
        case .Behance:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/behance")!
        case .Instagram:
            return NSURL(string: "\(yepBaseURL.absoluteString)/auth/instagram")!
        }
    }
}

public enum ProfileUser {
    case DiscoveredUserType(DiscoveredUser)
    case UserType(User)

    public var userID: String {
        switch self {
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.id

        case .UserType(let user):
            return user.userID
        }
    }

    public var username: String? {

        var username: String? = nil

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            username = discoveredUser.username

        case .UserType(let user):
            if !user.username.isEmpty {
                username = user.username
            }
        }

        return username
    }

    public var nickname: String {
        switch self {
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.nickname

        case .UserType(let user):
            return user.nickname
        }
    }

    public var avatarURLString: String? {

        var avatarURLString: String? = nil

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            avatarURLString = discoveredUser.avatarURLString

        case .UserType(let user):
            if !user.avatarURLString.isEmpty {
                avatarURLString = user.avatarURLString
            }
        }
        
        return avatarURLString
    }

    public var blogURL: NSURL? {

        var blogURLString: String? = nil

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            blogURLString = discoveredUser.blogURLString

        case .UserType(let user):
            if !user.blogURLString.isEmpty {
                blogURLString = user.blogURLString
            }
        }

        if let blogURLString = blogURLString {
            return NSURL(string: blogURLString)
        }

        return nil
    }

    public var blogTitle: String? {

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.blogTitle

        case .UserType(let user):
            if !user.blogTitle.isEmpty {
                return user.blogTitle
            }
        }

        return nil
    }

    public var isMe: Bool {

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.isMe

        case .UserType(let user):
            return user.isMe
        }
    }

    public func enabledSocialAccount(socialAccount: SocialAccount) -> Bool {
        var accountEnabled = false

        let providerName = socialAccount.rawValue

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            for provider in discoveredUser.socialAccountProviders {
                if (provider.name == providerName) && provider.enabled {

                    accountEnabled = true

                    break
                }
            }

        case .UserType(let user):
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
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.masterSkills.count
        case .UserType(let user):
            return Int(user.masterSkills.count)
        }
    }

    public var learningSkillsCount: Int {
        switch self {
        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.learningSkills.count
        case .UserType(let user):
            return Int(user.learningSkills.count)
        }
    }

    public var providersCount: Int {

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            return discoveredUser.socialAccountProviders.filter({ $0.enabled }).count

        case .UserType(let user):

            if user.friendState == UserFriendState.Me.rawValue {
                return user.socialAccountProviders.count

            } else {
                return user.socialAccountProviders.filter("enabled = true").count
            }
        }
    }

    public func cellSkillInSkillSet(skillSet: SkillSet, atIndexPath indexPath: NSIndexPath)  -> SkillCellSkill? {

        switch self {

        case .DiscoveredUserType(let discoveredUser):

            let skill: Skill?
            switch skillSet {
            case .Master:
                skill = discoveredUser.masterSkills[safe: indexPath.item]
            case .Learning:
                skill = discoveredUser.learningSkills[safe: indexPath.item]
            }

            if let skill = skill {
                return SkillCellSkill(ID: skill.id, localName: skill.localName, coverURLString: skill.coverURLString, category: skill.skillCategory)
            }

        case .UserType(let user):

            let userSkill: UserSkill?
            switch skillSet {
            case .Master:
                userSkill = user.masterSkills[safe: indexPath.item]
            case .Learning:
                userSkill = user.learningSkills[safe: indexPath.item]
            }

            if let userSkill = userSkill {
                return SkillCellSkill(ID: userSkill.skillID, localName: userSkill.localName, coverURLString: userSkill.coverURLString, category: userSkill.skillCategory)
            }
        }

        return nil
    }

    public func providerNameWithIndex(index: Int) -> String? {

        var providerName: String?

        switch self {

        case .DiscoveredUserType(let discoveredUser):
            if let provider = discoveredUser.socialAccountProviders.filter({ $0.enabled })[safe: index] {
                providerName = provider.name
            }

        case .UserType(let user):

            if user.friendState == UserFriendState.Me.rawValue {
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

    case Default(info: Info)
    case Picked(info: Info)
    case Selected(info: Info)

    public var info: Info {
        switch self {
        case .Default(let locationInfo):
            return locationInfo
        case .Picked(let locationInfo):
            return locationInfo
        case .Selected(let locationInfo):
            return locationInfo
        }
    }

    public var isPicked: Bool {
        switch self {
        case .Picked:
            return true
        default:
            return false
        }
    }
}


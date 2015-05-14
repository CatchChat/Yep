//
//  YepConfig.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepConfig {
    
    static let minMessageTextLabelWidth: CGFloat = 20.0
    
    static let minMessageSampleViewWidth: CGFloat = 25.0
    
    static let skillHomeHeaderViewHeight: CGFloat = 250.0
    
    static let skillHomeHeaderButtonHeight: CGFloat = 50.0
    
    class func clientType() -> Int {
        // TODO: clientType
        #if DEBUG
            return 2
        #else
            return 0
        #endif
    }
    
    class func getScreenRect() -> CGRect {
        return UIScreen.mainScreen().bounds
    }

    class func verifyCodeLength() -> Int {
        return 4
    }

    class func callMeInSeconds() -> Int {
        return 60
    }

    class func avatarMaxSize() -> CGSize {
        return CGSize(width: 600, height: 600)
    }

    class func chatCellAvatarSize() -> CGFloat {
        return 40.0
    }

    class func chatCellGapBetweenTextContentLabelAndAvatar() -> CGFloat {
        return 23
    }

    class func chatCellGapBetweenWallAndAvatar() -> CGFloat {
        return 15
    }

    class func chatTextGapBetweenWallAndContentLabel() -> CGFloat {
        return 50
    }

    class func avatarCompressionQuality() -> CGFloat {
        return 0.7
    }

    class func messageImageCompressionQuality() -> CGFloat {
        return 0.8
    }

    class func audioSampleWidth() -> CGFloat {
        return 2
    }

    class func audioSampleGap() -> CGFloat {
        return 1
    }

    class func editProfileAvatarSize() -> CGFloat {
        return 100
    }

    struct Profile {
        static let leftEdgeInset: CGFloat = 38
        static let rightEdgeInset: CGFloat = 38
        static let introductionLabelFont = UIFont(name: "HelveticaNeue-Thin", size: 12)!
    }
    
    struct Settings {
        static let userCellAvatarSize: CGFloat = 80

        static let introFont = UIFont(name: "Helvetica-Light", size: 12)!
        static let introInset: CGFloat = 20 + userCellAvatarSize + 20 + 11 + 20
    }

    struct EditProfile {
        static let introFont = UIFont(name: "Helvetica-Light", size: 15)!
        static let introInset: CGFloat = 20 + 20
    }

    struct SocialWorkGithub {
        struct Repo {
            static let leftEdgeInset: CGFloat = {
                switch UIDevice.screenWidthModel {
                case .Classic:
                    return 20
                case .Bigger:
                    return 40
                case .BiggerPlus:
                    return 40
                }
                }()
            static let rightEdgeInset = leftEdgeInset
        }
    }

}
//
//  UIStoryboard+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/9.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UIStoryboard {

    static var yep_show: UIStoryboard {
        return UIStoryboard(name: "Show", bundle: nil)
    }

    static var yep_main: UIStoryboard {
        return UIStoryboard(name: "Main", bundle: nil)
    }

    struct Scene {

        static var pickPhotos: PickPhotosViewController {
            return UIStoryboard(name: "PickPhotos", bundle: nil).instantiateViewControllerWithIdentifier("PickPhotosViewController") as! PickPhotosViewController
        }

        static var conversation: ConversationViewController {
            return UIStoryboard(name: "Conversation", bundle: nil).instantiateViewControllerWithIdentifier("ConversationViewController") as! ConversationViewController
        }

        static var profile: ProfileViewController {
            return UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("ProfileViewController") as! ProfileViewController
        }

        static var mediaPreview: MediaPreviewViewController {
            return UIStoryboard(name: "MediaPreview", bundle: nil).instantiateViewControllerWithIdentifier("MediaPreviewViewController") as! MediaPreviewViewController
        }

        static var meetGenius: MeetGeniusViewController {
            return UIStoryboard(name: "Discover", bundle: nil).instantiateViewControllerWithIdentifier("MeetGeniusViewController") as! MeetGeniusViewController
        }

        static var discover: DiscoverViewController {
            return UIStoryboard(name: "Discover", bundle: nil).instantiateViewControllerWithIdentifier("DiscoverViewController") as! DiscoverViewController
        }

        static var geniusInterview: GeniusInterviewViewController {
            return UIStoryboard(name: "GeniusInterview", bundle: nil).instantiateViewControllerWithIdentifier("GeniusInterviewViewController") as! GeniusInterviewViewController
        }

        static var registerSelectSkills: RegisterSelectSkillsViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewControllerWithIdentifier("RegisterSelectSkillsViewController") as! RegisterSelectSkillsViewController
        }

        static var registerPickSkills: RegisterPickSkillsViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewControllerWithIdentifier("RegisterPickSkillsViewController") as! RegisterPickSkillsViewController
        }

        static var registerPickName: RegisterPickNameViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewControllerWithIdentifier("RegisterPickNameViewController") as! RegisterPickNameViewController
        }

        static var loginByMobile: LoginByMobileViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewControllerWithIdentifier("LoginByMobileViewController") as! LoginByMobileViewController
        }
    }
}


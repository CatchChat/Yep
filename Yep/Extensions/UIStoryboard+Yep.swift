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

        static var showStepGenius: ShowStepGeniusViewController {
            return UIStoryboard.yep_show.instantiateViewController(withIdentifier: "ShowStepGeniusViewController") as! ShowStepGeniusViewController
        }

        static var showStepMatch: ShowStepMatchViewController {
            return UIStoryboard.yep_show.instantiateViewController(withIdentifier: "ShowStepMatchViewController") as! ShowStepMatchViewController
        }

        static var showStepMeet: ShowStepMeetViewController {
            return UIStoryboard.yep_show.instantiateViewController(withIdentifier: "ShowStepMeetViewController") as! ShowStepMeetViewController
        }

        static var pickPhotos: PickPhotosViewController {
            return UIStoryboard(name: "PickPhotos", bundle: nil).instantiateViewController(withIdentifier: "PickPhotosViewController") as! PickPhotosViewController
        }

        static var conversation: ConversationViewController {
            return UIStoryboard(name: "Conversation", bundle: nil).instantiateViewController(withIdentifier: "ConversationViewController") as! ConversationViewController
        }

        static var profile: ProfileViewController {
            return UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        }

        static var mediaPreview: MediaPreviewViewController {
            return UIStoryboard(name: "MediaPreview", bundle: nil).instantiateViewController(withIdentifier: "MediaPreviewViewController") as! MediaPreviewViewController
        }

        static var meetGenius: MeetGeniusViewController {
            return UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "MeetGeniusViewController") as! MeetGeniusViewController
        }

        static var discover: DiscoverViewController {
            return UIStoryboard(name: "Discover", bundle: nil).instantiateViewController(withIdentifier: "DiscoverViewController") as! DiscoverViewController
        }

        static var geniusInterview: GeniusInterviewViewController {
            return UIStoryboard(name: "GeniusInterview", bundle: nil).instantiateViewController(withIdentifier: "GeniusInterviewViewController") as! GeniusInterviewViewController
        }

        static var registerSelectSkills: RegisterSelectSkillsViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "RegisterSelectSkillsViewController") as! RegisterSelectSkillsViewController
        }

        static var registerPickSkills: RegisterPickSkillsViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "RegisterPickSkillsViewController") as! RegisterPickSkillsViewController
        }

        static var registerPickName: RegisterPickNameViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "RegisterPickNameViewController") as! RegisterPickNameViewController
        }

        static var loginByMobile: LoginByMobileViewController {
            return UIStoryboard(name: "Intro", bundle: nil).instantiateViewController(withIdentifier: "LoginByMobileViewController") as! LoginByMobileViewController
        }
    }
}


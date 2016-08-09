//
//  UIStoryboard+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/9.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UIStoryboard {

    static var yep_pickPhotos: PickPhotosViewController {
        return UIStoryboard(name: "PickPhotos", bundle: nil).instantiateViewControllerWithIdentifier("PickPhotosViewController") as! PickPhotosViewController
    }

    static var yep_conversation: ConversationViewController {
        return UIStoryboard(name: "Conversation", bundle: nil).instantiateViewControllerWithIdentifier("ConversationViewController") as! ConversationViewController
    }

    static var yep_profile: ProfileViewController {
        return UIStoryboard(name: "Profile", bundle: nil).instantiateViewControllerWithIdentifier("ProfileViewController") as! ProfileViewController
    }
}


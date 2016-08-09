//
//  UIStoryboard+Yep.swift
//  Yep
//
//  Created by NIX on 16/8/9.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

extension UIStoryboard {

    static var pickPhotosViewController: PickPhotosViewController {
        return UIStoryboard(name: "PickPhotos", bundle: nil).instantiateViewControllerWithIdentifier("PickPhotosViewController") as! PickPhotosViewController
    }

    static var conversationViewController: ConversationViewController {
        return UIStoryboard(name: "Conversation", bundle: nil).instantiateViewControllerWithIdentifier("ConversationViewController") as! ConversationViewController
    }
}


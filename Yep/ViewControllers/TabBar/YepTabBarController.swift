//
//  YepTabBarController.swift
//  Yep
//
//  Created by kevinzhow on 15/3/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        view.backgroundColor = UIColor.whiteColor()

        // 将 UITabBarItem 的 image 下移一些，也不显示 title 了
//        if let items = tabBar.items as? [UITabBarItem] {
//            for item in items {
//                item.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
//                item.title = nil
//            }
//        }

        if let items = tabBar.items as? [UITabBarItem] {

            let titles = [
                NSLocalizedString("Chats", comment: ""),
                NSLocalizedString("Contacts", comment: ""),
                NSLocalizedString("Discover", comment: ""),
                NSLocalizedString("Profile", comment: ""),
            ]

            for i in 0..<items.count {
                let item = items[i]
                item.title = titles[i]
            }
        }
    }
}

extension YepTabBarController: UITabBarControllerDelegate {

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {

        if selectedIndex == 1 {
            if let nvc = viewController as? UINavigationController, vc = nvc.topViewController as? ContactsViewController {
                syncFriendshipsAndDoFurtherAction {
                    dispatch_async(dispatch_get_main_queue()) { [weak vc] in
                        vc?.updateContactsTableView()
                    }
                }
            }
        }
    }
}


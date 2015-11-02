//
//  YepTabBarController.swift
//  Yep
//
//  Created by kevinzhow on 15/3/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepTabBarController: UITabBarController {

    var previousTab = Tab.Conversations

    struct Listener {
        static let lauchStyle = "YepTabBarController.lauchStyle"
    }

    deinit {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.lauchStyle.removeListenerWithName(Listener.lauchStyle)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        view.backgroundColor = UIColor.whiteColor()

        // 将 UITabBarItem 的 image 下移一些，也不显示 title 了
        /*
        if let items = tabBar.items as? [UITabBarItem] {
            for item in items {
                item.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                item.title = nil
            }
        }
        */

        if let items = tabBar.items {

            let titles = [
                NSLocalizedString("Chats", comment: ""),
                NSLocalizedString("Contacts", comment: ""),
                NSLocalizedString("Feeds", comment: ""),
                NSLocalizedString("Discover", comment: ""),
                NSLocalizedString("Profile", comment: ""),
            ]

            for i in 0..<items.count {
                let item = items[i]
                item.title = titles[i]
            }
        }

        // 处理启动切换

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.lauchStyle.bindListener(Listener.lauchStyle) { [weak self] style in
                if style == .Message {
                    self?.selectedIndex = 0
                }
            }
        }
    }
}

// MARK: - UITabBarControllerDelegate

extension YepTabBarController: UITabBarControllerDelegate {

    enum Tab: Int {

        case Conversations
        case Contacts
        case Feeds
        case Discover
        case Profile
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {

        guard
            let tab = Tab(rawValue: selectedIndex),
            let nvc = viewController as? UINavigationController else {
                return
        }

        if tab != previousTab {
            previousTab = tab
            return
        }

        switch tab {

        case .Conversations:
            let vc = nvc.topViewController as? ConversationsViewController

        case .Contacts:
            let vc = nvc.topViewController as? ContactsViewController

        case .Feeds:
            if let vc = nvc.topViewController as? FeedsViewController {

                println("vc.feedsTableView.contentOffset.y: \(vc.feedsTableView.contentOffset.y)")
                if vc.feedsTableView.contentOffset.y != 0 {
                    vc.feedsTableView.tryScrollsToTop()
                }
            }

        case .Discover:
            let vc = nvc.topViewController as? DiscoverViewController

        case .Profile:
            let vc = nvc.topViewController as? ProfileViewController

        }

        previousTab = tab

        /*
        if selectedIndex == 1 {
            if let nvc = viewController as? UINavigationController, vc = nvc.topViewController as? ContactsViewController {
                syncFriendshipsAndDoFurtherAction {
                    dispatch_async(dispatch_get_main_queue()) { [weak vc] in
                        vc?.updateContactsTableView()
                    }
                }
            }
        }
        */
    }
}


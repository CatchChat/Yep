//
//  YepTabBarController.swift
//  Yep
//
//  Created by kevinzhow on 15/3/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class YepTabBarController: UITabBarController {

    private enum Tab: Int {

        case Conversations
        case Contacts
        case Feeds
        case Discover
        case Profile

        var title: String {

            switch self {
            case .Conversations:
                return NSLocalizedString("Chats", comment: "")
            case .Contacts:
                return NSLocalizedString("Contacts", comment: "")
            case .Feeds:
                return NSLocalizedString("Feeds", comment: "")
            case .Discover:
                return NSLocalizedString("Discover", comment: "")
            case .Profile:
                return NSLocalizedString("Profile", comment: "")
            }
        }
    }

    private var previousTab = Tab.Conversations

    private var checkDoubleTapOnFeedsTimer: NSTimer?
    private var hasFirstTapOnFeedsWhenItIsAtTop = false {
        willSet {
            if newValue {
                let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "checkDoubleTapOnFeeds:", userInfo: nil, repeats: false)
                checkDoubleTapOnFeedsTimer = timer

            } else {
                checkDoubleTapOnFeedsTimer?.invalidate()
            }
        }
    }

    @objc private func checkDoubleTapOnFeeds(timer: NSTimer) {

        hasFirstTapOnFeedsWhenItIsAtTop = false
    }

    private struct Listener {
        static let lauchStyle = "YepTabBarController.lauchStyle"
    }

    deinit {
        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.lauchStyle.removeListenerWithName(Listener.lauchStyle)
        }

        println("deinit YepTabBar")
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

        // Set Titles

        if let items = tabBar.items {
            for i in 0..<items.count {
                let item = items[i]
                item.title = Tab(rawValue: i)?.title
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

    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {

        guard
            let tab = Tab(rawValue: selectedIndex),
            let nvc = viewController as? UINavigationController else {
                return false
        }

        if tab != previousTab {
            return true
        }

        if case .Feeds = tab {
            if let vc = nvc.topViewController as? FeedsViewController {
                guard let feedsTableView = vc.feedsTableView else {
                    return true
                }
                if feedsTableView.yep_isAtTop {
                    if !hasFirstTapOnFeedsWhenItIsAtTop {
                        hasFirstTapOnFeedsWhenItIsAtTop = true
                        return false
                    }
                }
            }
        }

        return true
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {

        guard
            let tab = Tab(rawValue: selectedIndex),
            let nvc = viewController as? UINavigationController else {
                return
        }

        // 不相等才继续，确保第一次 tap 不做事

        if tab != previousTab {
            previousTab = tab
            return
        }

        switch tab {

        case .Conversations:
            if let vc = nvc.topViewController as? ConversationsViewController {
                if !vc.conversationsTableView.yep_isAtTop {
                    vc.conversationsTableView.yep_scrollsToTop()
                }
            }

        case .Contacts:
            if let vc = nvc.topViewController as? ContactsViewController {
                if !vc.contactsTableView.yep_isAtTop {
                    vc.contactsTableView.yep_scrollsToTop()
                }
            }

        case .Feeds:
            if let vc = nvc.topViewController as? FeedsViewController {
                if !vc.feedsTableView.yep_isAtTop {
                    vc.feedsTableView.yep_scrollsToTop()

                } else {
                    if !vc.feeds.isEmpty && !vc.pullToRefreshView.isRefreshing {
                        vc.feedsTableView.setContentOffset(CGPoint(x: 0, y: -150), animated: true)
                        hasFirstTapOnFeedsWhenItIsAtTop = false
                    }
                }
            }

        case .Discover:
            if let vc = nvc.topViewController as? DiscoverViewController {
                if !vc.discoveredUsersCollectionView.yep_isAtTop {
                    vc.discoveredUsersCollectionView.yep_scrollsToTop()
                }
            }

        case .Profile:
            if let vc = nvc.topViewController as? ProfileViewController {
                if !vc.profileCollectionView.yep_isAtTop {
                    vc.profileCollectionView.yep_scrollsToTop()
                }
            }
        }

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


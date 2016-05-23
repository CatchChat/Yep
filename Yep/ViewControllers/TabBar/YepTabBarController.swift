//
//  YepTabBarController.swift
//  Yep
//
//  Created by kevinzhow on 15/3/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepConfig

final class YepTabBarController: UITabBarController {

    enum Tab: Int {

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

    private var previousTab: Tab = .Conversations
    var tab: Tab? {
        didSet {
            if let tab = tab {
                self.selectedIndex = tab.rawValue
            }
        }
    }

    private var checkDoubleTapOnFeedsTimer: NSTimer?
    private var hasFirstTapOnFeedsWhenItIsAtTop = false {
        willSet {
            if newValue {
                let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(YepTabBarController.checkDoubleTapOnFeeds(_:)), userInfo: nil, repeats: false)
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

    var isTabBarVisible: Bool {
        return self.tabBar.frame.origin.y < CGRectGetMaxY(view.frame)
    }

    func setTabBarHidden(hidden: Bool, animated: Bool) {

        guard isTabBarVisible == hidden else {
            return
        }

        let height = self.tabBar.frame.size.height
        let offsetY = (hidden ? height : -height)

        let duration = (animated ? 0.25 : 0.0)

        UIView.animateWithDuration(duration, animations: {
            let frame = self.tabBar.frame
            self.tabBar.frame = CGRectOffset(frame, 0, offsetY);
        }, completion: nil)
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

    func tryScrollsToTopOfFeedsViewController(vc: FeedsViewController) {

        guard let scrollView = vc.feedsTableView else {
            return
        }

        if !scrollView.yep_isAtTop {
            scrollView.yep_scrollsToTop()

        } else {
            if !vc.feeds.isEmpty && !vc.pullToRefreshView.isRefreshing {
                scrollView.setContentOffset(CGPoint(x: 0, y: -150), animated: true)
                hasFirstTapOnFeedsWhenItIsAtTop = false
            }
        }
    }

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {

        guard
            let tab = Tab(rawValue: selectedIndex),
            let nvc = viewController as? UINavigationController else {
                return
        }

        if tab != .Contacts {
            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.switchedToOthersFromContactsTab, object: nil)
        }

        // 不相等才继续，确保第一次 tap 不做事

        if tab != previousTab {
            previousTab = tab
            return
        }

        switch tab {

        case .Conversations:
            if let vc = nvc.topViewController as? ConversationsViewController {
                guard let scrollView = vc.conversationsTableView else {
                    break
                }
                if !scrollView.yep_isAtTop {
                    scrollView.yep_scrollsToTop()
                }
            }

        case .Contacts:
            if let vc = nvc.topViewController as? ContactsViewController {
                guard let scrollView = vc.contactsTableView else {
                    break
                }
                if !scrollView.yep_isAtTop {
                    scrollView.yep_scrollsToTop()
                }
            }

        case .Feeds:
            if let vc = nvc.topViewController as? FeedsViewController {
                tryScrollsToTopOfFeedsViewController(vc)
            }

        case .Discover:
            if let vc = nvc.topViewController as? DiscoverViewController {
                guard let scrollView = vc.discoveredUsersCollectionView else {
                    break
                }
                if !scrollView.yep_isAtTop {
                    scrollView.yep_scrollsToTop()
                }
            }

        case .Profile:
            if let vc = nvc.topViewController as? ProfileViewController {
                guard let scrollView = vc.profileCollectionView else {
                    break
                }
                if !scrollView.yep_isAtTop {
                    scrollView.yep_scrollsToTop()
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


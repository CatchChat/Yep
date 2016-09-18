//
//  YepTabBarController.swift
//  Yep
//
//  Created by kevinzhow on 15/3/28.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Proposer

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
                return String.trans_titleChats
            case .Contacts:
                return String.trans_titleContacts
            case .Feeds:
                return String.trans_titleFeeds
            case .Discover:
                return String.trans_titleDiscover
            case .Profile:
                return NSLocalizedString("Profile", comment: "")
            }
        }

        var canBeenDoubleTap: Bool {
            switch self {
            case .Feeds:
                return true
            default:
                return false
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

    private var checkDoubleTapTimer: NSTimer?
    private var hasFirstTapOnTabWhenItIsAtTop = false {
        willSet {
            checkDoubleTapTimer?.invalidate()

            if newValue {
                let timer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(YepTabBarController.checkDoubleTap(_:)), userInfo: nil, repeats: false)
                checkDoubleTapTimer = timer
            }
        }
    }

    @objc private func checkDoubleTap(timer: NSTimer) {

        hasFirstTapOnTabWhenItIsAtTop = false
    }

    private struct Listener {
        static let lauchStyle = "YepTabBarController.lauchStyle"
    }

    private let tabBarItemTextEnabledListenerName = "YepTabBarController.tabBarItemTextEnabled"

    deinit {
        checkDoubleTapTimer?.invalidate()

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.lauchStyle.removeListenerWithName(Listener.lauchStyle)
        }

        YepUserDefaults.tabBarItemTextEnabled.removeListenerWithName(tabBarItemTextEnabledListenerName)

        println("deinit YepTabBar")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        delegate = self

        view.backgroundColor = UIColor.whiteColor()

        YepUserDefaults.tabBarItemTextEnabled.bindAndFireListener(tabBarItemTextEnabledListenerName) { [weak self] _ in
            self?.adjustTabBarItems()
        }

        // 处理启动切换

        if let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            appDelegate.lauchStyle.bindListener(Listener.lauchStyle) { [weak self] style in
                if style == .Message {
                    self?.selectedIndex = 0
                }
            }
        }

        delay(3) {
            if PrivateResource.Location(.WhenInUse).isAuthorized {
                YepLocationService.turnOn()
            }
        }
    }

    func adjustTabBarItems() {

        let noNeedTitle: Bool
        if let tabBarItemTextEnabled = YepUserDefaults.tabBarItemTextEnabled.value {
            noNeedTitle = !tabBarItemTextEnabled
        } else {
            noNeedTitle = YepUserDefaults.appLaunchCount.value > YepUserDefaults.appLaunchCountThresholdForTabBarItemTextEnabled
        }

        if noNeedTitle {
            // 将 UITabBarItem 的 image 下移一些，也不显示 title 了
            if let items = tabBar.items {
                for item in items {
                    item.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0)
                    item.title = nil
                }
            }

        } else {
            // Set Titles
            if let items = tabBar.items {
                for i in 0..<items.count {
                    let item = items[i]
                    item.imageInsets = UIEdgeInsetsZero
                    item.title = Tab(rawValue: i)?.title
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

        UIView.animateWithDuration(duration, animations: { [weak self] in
            guard let strongSelf = self else {
                return
            }
            let frame = strongSelf.tabBar.frame
            strongSelf.tabBar.frame = CGRectOffset(frame, 0, offsetY)
        }, completion: nil)
    }
}

// MARK: - UITabBarControllerDelegate

extension YepTabBarController: UITabBarControllerDelegate {

    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {

        guard
            let tab = Tab(rawValue: selectedIndex),
            let nvc = viewController as? UINavigationController else {
                return
        }

        if tab != .Contacts {
            NSNotificationCenter.defaultCenter().postNotificationName(YepConfig.Notification.switchedToOthersFromContactsTab, object: nil)
        }

        // 相等才继续，确保第一次 tap 不做事
        guard tab == previousTab else {
            previousTab = tab
            hasFirstTapOnTabWhenItIsAtTop = false
            return
        }

        if tab.canBeenDoubleTap {
            if let vc = nvc.topViewController as? CanScrollsToTop, let scrollView = vc.scrollView {
                if scrollView.yep_isAtTop {
                    if !hasFirstTapOnTabWhenItIsAtTop {
                        hasFirstTapOnTabWhenItIsAtTop = true
                        return
                    }
                }
            }
        }

        if let vc = nvc.topViewController as? CanScrollsToTop {

            vc.scrollsToTopIfNeed(otherwise: { [weak self, weak vc] in

                guard tab.canBeenDoubleTap else { return }

                // 目前只特别处理 Feeds
                guard let scrollView = vc?.scrollView else { return }
                guard let vc = vc as? FeedsViewController else { return }

                if self?.hasFirstTapOnTabWhenItIsAtTop ?? false {
                    if !vc.feeds.isEmpty && !vc.pullToRefreshView.isRefreshing {
                        scrollView.setContentOffset(CGPoint(x: 0, y: -150), animated: true)
                        self?.hasFirstTapOnTabWhenItIsAtTop = false
                    }
                }
            })
        }
    }
}


//
//  GeniusInterviewViewController.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import WebKit
import YepKit
import RealmSwift
import RxSwift
import RxCocoa

class GeniusInterviewViewController: BaseViewController {

    var interview: InterviewRepresentation!

    private static let actionViewHeight: CGFloat = 50

    private lazy var disposeBag = DisposeBag()

    lazy var webView: WKWebView = {

        let view = WKWebView()

        view.navigationDelegate = self

        view.scrollView.scrollEnabled = false
        view.scrollView.contentInset.bottom = GeniusInterviewViewController.actionViewHeight
        view.scrollView.rx_contentOffset.map({ $0.y }).subscribeNext({ [weak self] (scrollViewContentOffsetY) in
            guard scrollViewContentOffsetY > 0, let scrollView = self?.webView.scrollView else {
                return
            }
            let scrollViewHeight = scrollView.bounds.height
            let scrollViewContentSizeHeight = scrollView.contentSize.height

            let y = (scrollViewContentOffsetY + scrollViewHeight) - scrollViewContentSizeHeight
            if y > 0 {
                let actionViewHeight = GeniusInterviewViewController.actionViewHeight
                UIView.animateWithDuration(0.5, animations: { [weak self] in
                    self?.actionViewTopConstraint?.constant = -actionViewHeight
                    self?.view.layoutIfNeeded()
                })
            } else {
                UIView.animateWithDuration(0.5, animations: { [weak self] in
                    self?.actionViewTopConstraint?.constant = 0
                    self?.view.layoutIfNeeded()
                })
            }
        }).addDisposableTo(self.disposeBag)

        return view
    }()

    lazy var indicatorView: UIActivityIndicatorView = {

        let view = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        view.hidesWhenStopped = true
        return view
    }()

    private var actionViewTopConstraint: NSLayoutConstraint?
    lazy var actionView: GeniusInterviewActionView = {

        let view = GeniusInterviewActionView()

        view.tapAvatarAction = { [weak self] in
            guard let user = self?.interview.user else {
                return
            }

            SafeDispatch.async { [weak self] in
                self?.performSegueWithIdentifier("showProfile", sender: Box<DiscoveredUser>(user))
            }
        }

        view.sayHiAction = { [weak self] in
            guard let user = self?.interview.user else {
                return
            }

            SafeDispatch.async { [weak self] in

                guard let realm = try? Realm() else {
                    return
                }

                realm.beginWrite()
                let conversation = conversationWithDiscoveredUser(user, inRealm: realm)
                _ = try? realm.commitWrite()

                if let conversation = conversation {
                    self?.performSegueWithIdentifier("showConversation", sender: conversation)

                    NSNotificationCenter.defaultCenter().postNotificationName(Config.Notification.changedConversation, object: nil)
                }
            }
        }

        view.shareAction = { [weak self] in
            guard let url = self?.interview.linkURL else {
                return
            }

            SafeDispatch.async { [weak self] in
                let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self?.presentViewController(activityViewController, animated: true, completion: nil)
            }
        }

        return view
    }()

    deinit {
        println("deinit GeniusInterview")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            webView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(webView)

            let leading = webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor)
            let trailing = webView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
            let top = webView.topAnchor.constraintEqualToAnchor(view.topAnchor)
            let bottom = webView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
            NSLayoutConstraint.activateConstraints([leading, trailing, top, bottom])
        }

        do {
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)

            let centerX = indicatorView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor)
            let top = indicatorView.topAnchor.constraintEqualToAnchor(view.topAnchor, constant: 64 + 120)
            NSLayoutConstraint.activateConstraints([centerX, top])
        }

        do {
            actionView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(actionView)

            let leading = actionView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor)
            let trailing = actionView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor)
            let top = actionView.topAnchor.constraintEqualToAnchor(view.bottomAnchor, constant: 0)
            self.actionViewTopConstraint = top
            let height = actionView.heightAnchor.constraintEqualToConstant(GeniusInterviewViewController.actionViewHeight)
            NSLayoutConstraint.activateConstraints([leading, trailing, top, height])
        }

        do {
            let request = NSURLRequest(URL: interview.linkURL)
            webView.loadRequest(request)

            indicatorView.startAnimating()
        }

        do {
            let avatar = PlainAvatar(avatarURLString: interview.user.avatarURLString, avatarStyle: miniAvatarStyle)
            actionView.avatarImageView.navi_setAvatar(avatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        navigationController?.hidesBarsOnSwipe = false
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":

            let vc = segue.destinationViewController as! ProfileViewController

            let discoveredUser = (sender as! Box<DiscoveredUser>).value
            vc.prepare(withDiscoveredUser: discoveredUser)

        case "showConversation":

            let vc = segue.destinationViewController as! ConversationViewController
            vc.conversation = sender as! Conversation

        default:
            break
        }
    }
}

// MARK: - WKNavigationDelegate

extension GeniusInterviewViewController: WKNavigationDelegate {

    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

        indicatorView.startAnimating()
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {

        delay(1) { [weak self] in
            self?.indicatorView.stopAnimating()

            webView.scrollView.scrollEnabled = true
        }
    }
}


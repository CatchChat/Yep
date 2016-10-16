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
import MonkeyKing

final class GeniusInterviewViewController: BaseViewController {

    var interview: InterviewRepresentation!

    fileprivate static let actionViewHeight: CGFloat = 49

    fileprivate lazy var disposeBag = DisposeBag()

    fileprivate lazy var webView: WKWebView = {

        let view = WKWebView()

        view.navigationDelegate = self

        view.scrollView.isScrollEnabled = false
        view.scrollView.contentInset.bottom = GeniusInterviewViewController.actionViewHeight
        view.scrollView.rx.contentOffset.map({ $0.y }).subscribe(onNext: { [weak self] (scrollViewContentOffsetY) in
            guard scrollViewContentOffsetY > 0, let scrollView = self?.webView.scrollView else {
                return
            }
            let scrollViewHeight = scrollView.bounds.height
            let scrollViewContentSizeHeight = scrollView.contentSize.height

            let y = (scrollViewContentOffsetY + scrollViewHeight) - scrollViewContentSizeHeight
            if y > 0 {
                let actionViewHeight = GeniusInterviewViewController.actionViewHeight
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    self?.actionViewTopConstraint?.constant = -actionViewHeight
                    self?.view.layoutIfNeeded()
                }) 
            } else {
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    self?.actionViewTopConstraint?.constant = 0
                    self?.view.layoutIfNeeded()
                }) 
            }
        }).addDisposableTo(self.disposeBag)

        return view
    }()

    fileprivate lazy var indicatorView: UIActivityIndicatorView = {

        let view = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        view.hidesWhenStopped = true
        return view
    }()

    fileprivate var actionViewTopConstraint: NSLayoutConstraint?
    lazy var actionView: GeniusInterviewActionView = {

        let view = GeniusInterviewActionView()

        view.tapAvatarAction = { [weak self] in
            guard let user = self?.interview.user else {
                return
            }

            SafeDispatch.async { [weak self] in
                self?.performSegue(withIdentifier: "showProfile", sender: user)
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
                    self?.performSegue(withIdentifier: "showConversation", sender: conversation)

                    NotificationCenter.default.post(name: Config.NotificationName.changedConversation, object: nil)
                }
            }
        }

        view.shareAction = { [weak self] in
            guard let url = self?.interview.linkURL else {
                return
            }

            let info = MonkeyKing.Info(
                title: nil,
                description: nil,
                thumbnail: nil,
                media: .url(url)
            )
            self?.yep_share(info: info, defaultActivityItem: url)
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

            let leading = webView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            let trailing = webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            let top = webView.topAnchor.constraint(equalTo: view.topAnchor)
            let bottom = webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            NSLayoutConstraint.activate([leading, trailing, top, bottom])
        }

        do {
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(indicatorView)

            let centerX = indicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            let top = indicatorView.topAnchor.constraint(equalTo: view.topAnchor, constant: 64 + 120)
            NSLayoutConstraint.activate([centerX, top])
        }

        do {
            actionView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(actionView)

            let leading = actionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
            let trailing = actionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            let top = actionView.topAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            self.actionViewTopConstraint = top
            let height = actionView.heightAnchor.constraint(equalToConstant: GeniusInterviewViewController.actionViewHeight)
            NSLayoutConstraint.activate([leading, trailing, top, height])
        }

        do {
            let request = URLRequest(url: interview.linkURL as URL)
            webView.load(request)

            indicatorView.startAnimating()
        }

        do {
            let avatar = PlainAvatar(avatarURLString: interview.user.avatarURLString, avatarStyle: miniAvatarStyle)
            actionView.avatarImageView.navi_setAvatar(avatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let identifier = segue.identifier else {
            return
        }

        switch identifier {

        case "showProfile":

            let vc = segue.destination as! ProfileViewController
            let discoveredUser = sender as! DiscoveredUser
            vc.prepare(with: discoveredUser)

        case "showConversation":

            let vc = segue.destination as! ConversationViewController
            vc.conversation = sender as! Conversation

        default:
            break
        }
    }
}

// MARK: - WKNavigationDelegate

extension GeniusInterviewViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {

        indicatorView.startAnimating()
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {

        _ = delay(1) { [weak self] in
            self?.indicatorView.stopAnimating()

            webView.scrollView.isScrollEnabled = true
        }
    }
}


//
//  SocialWorkGithubViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import MonkeyKing
import Navi

final class SocialWorkGithubViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var githubWork: GithubWork?

    var afterGetGithubWork: ((GithubWork) -> Void)?

    fileprivate lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(SocialWorkGithubViewController.share(_:)))
        return button
    }()

    @IBOutlet fileprivate weak var infoView: UIView!

    @IBOutlet fileprivate weak var avatarImageView: UIImageView!
    @IBOutlet fileprivate weak var followersCountLabel: UILabel!
    @IBOutlet fileprivate weak var starsCountLabel: UILabel!
    @IBOutlet fileprivate weak var followingCountLabel: UILabel!

    @IBOutlet fileprivate weak var githubTableView: UITableView!

    fileprivate var githubUser: GithubWork.User? {
        didSet {
            if let user = githubUser {
                shareButton.isEnabled = true

                infoView.isHidden = false

                let avatarSize = avatarImageView.bounds.width
                let avatarStyle: AvatarStyle = .roundedRectangle(size: CGSize(width: avatarSize, height: avatarSize), cornerRadius: avatarSize * 0.5, borderWidth: 0)
                let plainAvatar = PlainAvatar(avatarURLString: user.avatarURLString, avatarStyle: avatarStyle)
                avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

                followersCountLabel.text = "\(user.followersCount)"
                followingCountLabel.text = "\(user.followingCount)"
            }
        }
    }

    fileprivate var githubRepos = Array<GithubWork.Repo>() {
        didSet {
            let repos = githubRepos
            let starsCount = repos.reduce(0, { (result, repo) -> Int in
                result + repo.stargazersCount
            })

            starsCountLabel.text = "\(starsCount)"

            updateGithubTableView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let socialAccount = socialAccount {
            let accountImageView = UIImageView(image: UIImage(named: socialAccount.iconName)!)
            accountImageView.tintColor = socialAccount.tintColor
            navigationItem.titleView = accountImageView

        } else {
            title = "GitHub"
        }

        shareButton.isEnabled = false
        navigationItem.rightBarButtonItem = shareButton

        githubTableView.registerNibOf(GithubRepoCell.self)

        githubTableView.rowHeight = 100
        githubTableView.contentInset.bottom = YepConfig.SocialWorkGithub.Repo.rightEdgeInset - 10
        
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self) {
                    githubTableView.panGestureRecognizer.require(toFail: recognizer as! UIScreenEdgePanGestureRecognizer)
                    println("Require UIScreenEdgePanGestureRecognizer to failed")
                    break
                }
            }
        }

        // 获取 Github Work，如果必要的话

        if let githubWork = githubWork {
            githubUser = githubWork.user
            githubRepos = githubWork.repos

        } else {
            if let userID = profileUser?.userID {

                githubWorkOfUserWithUserID(userID, failureHandler: { [weak self] (reason, errorMessage) in
                    YepAlert.alertSorry(message: NSLocalizedString("Yep can't reach GitHub.\nWe blame GFW!", comment: ""), inViewController: self)

                }, completion: { githubWork in
                    //println("githubWork: \(githubWork)")

                    SafeDispatch.async { [weak self] in
                        self?.githubUser = githubWork.user
                        self?.githubRepos = githubWork.repos

                        self?.afterGetGithubWork?(githubWork)
                    }
                })
            }
        }
    }

    // MARK: Actions

    fileprivate func updateGithubTableView() {

        SafeDispatch.async { [weak self] in
            self?.githubTableView.reloadData()
        }
    }

    @objc fileprivate func share(_ sender: AnyObject) {

        guard let githubUser = githubUser else { return }
        guard let githubURL = URL(string: githubUser.htmlURLString) else { return }

        let title = String(format: NSLocalizedString("whosGitHub%@", comment: ""), githubUser.loginName)

        var thumbnail: UIImage?
        if let image = avatarImageView.image {
            thumbnail = image

        } else {
            if let socialAccount = socialAccount {
                thumbnail = UIImage(named: socialAccount.iconName)
            }
        }

        let info = MonkeyKing.Info(
            title: title,
            description: nil,
            thumbnail: thumbnail,
            media: .url(githubURL)
        )
        self.yep_share(info: info, defaultActivityItem: githubURL)
    }
}

extension SocialWorkGithubViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return githubRepos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: GithubRepoCell = tableView.dequeueReusableCell()

        let repo = githubRepos[indexPath.row]

        cell.nameLabel.text = repo.name
        cell.descriptionLabel.text = repo.description
        cell.starCountLabel.text = "\(repo.stargazersCount)" + "★"

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let repo = githubRepos[indexPath.row]

        if let URL = URL(string: repo.htmlURLString) {
            yep_openURL(URL)
        }
    }
}


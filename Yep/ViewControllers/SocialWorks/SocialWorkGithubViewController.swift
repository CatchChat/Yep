//
//  SocialWorkGithubViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SocialWorkGithubViewController: BaseViewController {

    var socialAccount: SocialAccount?
    var profileUser: ProfileUser?
    var githubWork: GithubWork?

    var afterGetGithubWork: (GithubWork -> Void)?


    lazy var shareButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")
        return button
        }()

    @IBOutlet weak var infoView: UIView!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var starsCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!

    @IBOutlet weak var githubTableView: UITableView!

    let githubRepoCellIdentifier = "GithubRepoCell"

    var githubUser: GithubWork.User? {
        didSet {
            if let user = githubUser {
                shareButton.enabled = true

                infoView.hidden = false

                AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(user.avatarURLString, withRadius: avatarImageView.bounds.width * 0.5) { [weak self] image in
                    self?.avatarImageView.image = image
                }

                followersCountLabel.text = "\(user.followersCount)"
                followingCountLabel.text = "\(user.followingCount)"
            }
        }
    }

    var githubRepos = Array<GithubWork.Repo>() {
        didSet {
            let repos = githubRepos
            let starsCount = repos.reduce(0, combine: { (result, repo) -> Int in
                result + repo.stargazersCount
            })

            starsCountLabel.text = "\(starsCount)"

            updateGithubTableView()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        animatedOnNavigationBar = false

        if let socialAccount = socialAccount {
            let accountImageView = UIImageView(image: UIImage(named: socialAccount.iconName)!)
            accountImageView.tintColor = socialAccount.tintColor
            navigationItem.titleView = accountImageView

        } else {
            title = "GitHub"
        }

        shareButton.enabled = false
        navigationItem.rightBarButtonItem = shareButton

        githubTableView.registerNib(UINib(nibName: githubRepoCellIdentifier, bundle: nil), forCellReuseIdentifier: githubRepoCellIdentifier)

        githubTableView.rowHeight = 100
        
        if let gestures = navigationController?.view.gestureRecognizers {
            for recognizer in gestures {
                if recognizer.isKindOfClass(UIScreenEdgePanGestureRecognizer) {
                    githubTableView.panGestureRecognizer.requireGestureRecognizerToFail(recognizer as! UIScreenEdgePanGestureRecognizer)
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
            var userID: String?

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    userID = discoveredUser.id
                case .UserType(let user):
                    userID = user.userID
                }
            }

            if let userID = userID {

                githubWorkOfUserWithUserID(userID, failureHandler: { [weak self] (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason, errorMessage)

                    YepAlert.alertSorry(message: NSLocalizedString("Yep can't reach GitHub.\nWe blame GFW!", comment: ""), inViewController: self)

                }, completion: { githubWork in
                    println("githubWork: \(githubWork)")

                    dispatch_async(dispatch_get_main_queue()) {
                        self.githubUser = githubWork.user
                        self.githubRepos = githubWork.repos

                        self.afterGetGithubWork?(githubWork)
                    }
                })
            }
        }
    }

    // MARK: Actions

    func updateGithubTableView() {
        dispatch_async(dispatch_get_main_queue()) {
            self.githubTableView.reloadData()
        }
    }

    func share() {
        if let user = githubUser, githubURL = NSURL(string: user.htmlURLString) {

            MonkeyKing.registerAccount(.WeChat(appID: YepConfig.ChinaSocialNetwork.WeChat.appID))

            var title: String?
            if let githubUser = githubUser {
                title = String(format: NSLocalizedString("%@'s GitHub", comment: ""), githubUser.loginName)
            }

            var thumbnail: UIImage?
            if let image = avatarImageView.image {
                thumbnail = image
            } else {
                if let socialAccount = socialAccount {
                    thumbnail = UIImage(named: socialAccount.iconName)
                }
            }

            let info = MonkeyKing.Message.WeChatSubtype.Info(
                title: title,
                description: nil,
                thumbnail: thumbnail,
                media: .URL(githubURL)
            )

            let sessionMessage = MonkeyKing.Message.WeChat(.Session(info))

            let weChatSessionActivity = AnyActivity(
                type: YepConfig.ChinaSocialNetwork.WeChat.sessionType,
                title: YepConfig.ChinaSocialNetwork.WeChat.sessionTitle,
                image: YepConfig.ChinaSocialNetwork.WeChat.sessionImage,
                canPerform: sessionMessage.canBeDelivered,
                perform: {
                    MonkeyKing.shareMessage(sessionMessage) { success in
                        println("share GitHub to WeChat Session success: \(success)")
                    }
                }
            )

            let timelineMessage = MonkeyKing.Message.WeChat(.Timeline(info))

            let weChatTimelineActivity = AnyActivity(
                type: YepConfig.ChinaSocialNetwork.WeChat.timelineType,
                title: YepConfig.ChinaSocialNetwork.WeChat.timelineTitle,
                image: YepConfig.ChinaSocialNetwork.WeChat.timelineImage,
                canPerform: timelineMessage.canBeDelivered,
                perform: {
                    MonkeyKing.shareMessage(timelineMessage) { success in
                        println("share GitHub to WeChat Timeline success: \(success)")
                    }
                }
            )

            let activityViewController = UIActivityViewController(activityItems: [githubURL], applicationActivities: [weChatSessionActivity, weChatTimelineActivity])

            presentViewController(activityViewController, animated: true, completion: nil)
        }
    }

}

extension SocialWorkGithubViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return githubRepos.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(githubRepoCellIdentifier) as! GithubRepoCell

        let repo = githubRepos[indexPath.row]

        cell.nameLabel.text = repo.name
        cell.descriptionLabel.text = repo.description
        cell.starCountLabel.text = "\(repo.stargazersCount)" + "★"

        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

        let repo = githubRepos[indexPath.row]

        UIApplication.sharedApplication().openURL(NSURL(string: repo.htmlURLString)!)
    }
}


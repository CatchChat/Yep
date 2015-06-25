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

                AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(user.avatarURLString, withRadius: avatarImageView.bounds.width * 0.5) { [unowned self] image in
                    self.avatarImageView.image = image
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
            title = "Github"
        }

        shareButton.enabled = false
        navigationItem.rightBarButtonItem = shareButton

        githubTableView.registerNib(UINib(nibName: githubRepoCellIdentifier, bundle: nil), forCellReuseIdentifier: githubRepoCellIdentifier)

        githubTableView.rowHeight = 100


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

                githubWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason, errorMessage)

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

            let activityViewController = UIActivityViewController(activityItems: [githubURL], applicationActivities: nil)

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


//
//  SocialWorkGithubViewController.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SocialWorkGithubViewController: UIViewController {

    var socialAccount: SocialAccount?


    lazy var gotoButton: UIBarButtonItem = {
        let button = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "gotoUserGithubHome")
        return button
        }()

    @IBOutlet weak var infoView: UIView!

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var starredCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!

    @IBOutlet weak var githubTableView: UITableView!

    let githubRepoCellIdentifier = "GithubRepoCell"

    var githubUser: GithubWork.User? {
        didSet {
            if let user = githubUser {
                gotoButton.enabled = true

                infoView.hidden = false

                AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(user.avatarURLString, withRadius: avatarImageView.bounds.width * 0.5) { image in
                    self.avatarImageView.image = image
                }

                followersCountLabel.text = "\(user.followersCount)"
                followingCountLabel.text = "\(user.followingCount)"
            }
        }
    }

    var githubRepos = Array<GithubWork.Repo>() {
        didSet {
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
            title = "Github"
        }

        gotoButton.enabled = false
        navigationItem.rightBarButtonItem = gotoButton

        githubTableView.registerNib(UINib(nibName: githubRepoCellIdentifier, bundle: nil), forCellReuseIdentifier: githubRepoCellIdentifier)

        githubTableView.rowHeight = 100


        // 获取 Github Work

        if let userID = YepUserDefaults.userID.value {

            githubWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                defaultFailureHandler(reason, errorMessage)

            }, completion: { githubWork in
                println("githubWork: \(githubWork)")

                dispatch_async(dispatch_get_main_queue()) {
                    self.githubUser = githubWork.user
                    self.githubRepos = githubWork.repos
                }
            })
        }
    }

    // MARK: Actions

    func updateGithubTableView() {
        githubTableView.reloadData()
    }

    func gotoUserGithubHome() {
        if let user = githubUser {
            UIApplication.sharedApplication().openURL(NSURL(string: user.htmlURLString)!)
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


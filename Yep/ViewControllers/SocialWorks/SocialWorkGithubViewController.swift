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

    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var starredCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!

    @IBOutlet weak var githubTableView: UITableView!

    let githubRepoCellIdentifier = "GithubRepoCell"

    var githubUser: GithubWork.User?
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

        let gotoButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "gotoUserGithubHome")
        navigationItem.rightBarButtonItem = gotoButton

        githubTableView.registerNib(UINib(nibName: githubRepoCellIdentifier, bundle: nil), forCellReuseIdentifier: githubRepoCellIdentifier)

        githubTableView.rowHeight = 100


        // 获取 github Work

        if let userID = YepUserDefaults.userID.value {

            githubWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                defaultFailureHandler(reason, errorMessage)

            }, completion: { githubWork in
                println("githubWork: \(githubWork)")

                self.githubUser = githubWork.user
                self.githubRepos = githubWork.repos
            })
        }
    }

    // MARK: Actions

    func updateGithubTableView() {
        githubTableView.reloadData()
    }

    func gotoUserGithubHome() {
        // TODO: gotoUserGithubHome
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
}


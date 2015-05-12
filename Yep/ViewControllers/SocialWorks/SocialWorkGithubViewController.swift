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
    }

    // MARK: Actions

    func gotoUserGithubHome() {
        // TODO: gotoUserGithubHome
    }

}

extension SocialWorkGithubViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 15
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(githubRepoCellIdentifier) as! GithubRepoCell
        return cell
    }
}


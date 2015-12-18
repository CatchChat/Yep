//
//  FeedGithubRepoCell.swift
//  Yep
//
//  Created by nixzhu on 15/12/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

class FeedGithubRepoCell: FeedBasicCell {

    var tapGithubRepoLinkAction: (NSURL -> Void)?

    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: SocialAccount.Github.iconName)
        imageView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        imageView.tintColor = SocialAccount.Github.tintColor
        return imageView
    }()

    lazy var githubRepoContainerView: FeedGithubRepoContainerView = {
        let view = FeedGithubRepoContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var socialWorkBorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "social_work_border")
        return imageView
    }()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(logoImageView)
        contentView.addSubview(githubRepoContainerView)
        contentView.addSubview(socialWorkBorderImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (80 + 15)

        return ceil(height)
    }

    override func configureWithFeed(feed: DiscoveredFeed, layoutCache: FeedCellLayout.Cache, needShowSkill: Bool) {

        var _newLayout: FeedCellLayout?
        super.configureWithFeed(feed, layoutCache: (layout: layoutCache.layout, update: { newLayout in
            _newLayout = newLayout
        }), needShowSkill: needShowSkill)

        if needShowSkill, let _ = feed.skill {
            logoImageView.frame.origin.x = skillButton.frame.origin.x - 8 - 18
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y

        } else {
            logoImageView.frame.origin.x = screenWidth - 18 - 15
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y
        }
        nicknameLabel.frame.size.width -= logoImageView.bounds.width + 10

        if let attachment = feed.attachment {
            if case let .Github(githubRepo) = attachment {
                githubRepoContainerView.nameLabel.text = githubRepo.name
                githubRepoContainerView.descriptionLabel.text = githubRepo.description
            }
        }

        githubRepoContainerView.tapAction = { [weak self] in
            guard let attachment = feed.attachment else {
                return
            }

            if case .GithubRepo = feed.kind {
                if case let .Github(repo) = attachment, let URL = NSURL(string: repo.URLString) {
                    self?.tapGithubRepoLinkAction?(URL)
                }
            }
        }

        if let githubRepoLayout = layoutCache.layout?.githubRepoLayout {
            githubRepoContainerView.frame = githubRepoLayout.githubRepoContainerViewFrame
            socialWorkBorderImageView.frame = githubRepoContainerView.frame

        } else {
            let y = messageTextView.frame.origin.y + messageTextView.frame.height + 15
            let height: CGFloat = leftBottomLabel.frame.origin.y - y - 15
            githubRepoContainerView.frame = CGRect(x: 65, y: y, width: screenWidth - 65 - 60, height: height)

            socialWorkBorderImageView.frame = githubRepoContainerView.frame
        }

        if layoutCache.layout == nil {

            let githubRepoLayout = FeedCellLayout.GithubRepoLayout(githubRepoContainerViewFrame: githubRepoContainerView.frame)
            _newLayout?.githubRepoLayout = githubRepoLayout

            if let newLayout = _newLayout {
                layoutCache.update(layout: newLayout)
            }
        }
    }
}


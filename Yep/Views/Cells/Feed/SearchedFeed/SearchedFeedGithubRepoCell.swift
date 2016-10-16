//
//  SearchedFeedGithubRepoCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

private let screenWidth: CGFloat = UIScreen.main.bounds.width

final class SearchedFeedGithubRepoCell: SearchedFeedBasicCell {

    override class func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

        let height = super.heightOfFeed(feed) + (10 + 80)

        return ceil(height)
    }

    var tapGithubRepoLinkAction: ((URL) -> Void)?

    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: SocialAccount.github.iconName)
        imageView.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        imageView.tintColor = YepConfig.SearchedItemCell.logoTintColor
        return imageView
    }()

    lazy var githubRepoContainerView: FeedGithubRepoContainerView = {
        let view = FeedGithubRepoContainerView()
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 200)
        return view
    }()

    lazy var socialWorkBorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_socialWorkBorder
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

    override func configureWithFeed(_ feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        super.configureWithFeed(feed, layout: layout, keyword: keyword)

        if let attachment = feed.attachment {
            if case let .github(githubRepo) = attachment {
                githubRepoContainerView.nameLabel.text = githubRepo.name
                githubRepoContainerView.descriptionLabel.text = githubRepo.description
            }
        }

        githubRepoContainerView.tapAction = { [weak self] in
            guard let attachment = feed.attachment else {
                return
            }

            if case .githubRepo = feed.kind {
                if case let .github(repo) = attachment, let URL = URL(string: repo.URLString) {
                    self?.tapGithubRepoLinkAction?(URL)
                }
            }
        }

        if let _ = feed.skill {
            logoImageView.frame.origin.x = skillButton.frame.origin.x - 10 - 18
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y

        } else {
            logoImageView.frame.origin.x = screenWidth - 18 - 15
            logoImageView.frame.origin.y = nicknameLabel.frame.origin.y
        }
        nicknameLabel.frame.size.width -= logoImageView.bounds.width + 10

        let githubRepoLayout = layout.githubRepoLayout!
        githubRepoContainerView.frame = githubRepoLayout.githubRepoContainerViewFrame
        socialWorkBorderImageView.frame = githubRepoContainerView.frame
    }
}


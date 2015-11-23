//
//  FeedSocialWorkCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/19.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedSocialWorkCell: FeedBasicCell {

    @IBOutlet weak var logoImageView: UIImageView!

    @IBOutlet weak var socialWorkContainerView: UIView!
    @IBOutlet weak var socialWorkImageView: UIImageView!
    @IBOutlet weak var githubRepoContainerView: UIView!
    @IBOutlet weak var githubRepoImageView: UIImageView!
    @IBOutlet weak var githubRepoNameLabel: UILabel!
    @IBOutlet weak var githubRepoDescriptionLabel: UILabel!

    //@IBOutlet weak var gapConstraintBetweenGithubRepoImageViewAndBubbleImageView: NSLayoutConstraint!
    @IBOutlet weak var githubRepoImageViewTrailingConstraint: NSLayoutConstraint!
    
    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedSocialWorkCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        var height: CGFloat = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15
        switch feed.kind {
        case .GithubRepo:
            height += (80 + 15)
        case .DribbbleShot:
            height += (80 + 15)
        default:
            break
        }

        return ceil(height)
    }

    private var updateConstraintsForSkill: (() -> Void)?

    override func layoutSubviews() {
        super.layoutSubviews()

        updateConstraintsForSkill?()
    }

    override func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {
        super.configureWithFeed(feed, needShowSkill: needShowSkill)

        updateConstraintsForSkill = { [weak self] in
            if let strongSelf = self {
                if needShowSkill, let _ = feed.skill {
                    strongSelf.githubRepoImageViewTrailingConstraint.constant = 10 + strongSelf.skillBubbleImageView.bounds.width + 15
                } else {
                    strongSelf.githubRepoImageViewTrailingConstraint.constant = 15
                }
            }
        }

        if let
            accountName = feed.kind.accountName,
            socialAccount = SocialAccount(rawValue: accountName) {
                logoImageView.image = UIImage(named: socialAccount.iconName)
                logoImageView.tintColor = socialAccount.tintColor
                logoImageView.hidden = false

        } else {
            logoImageView.hidden = true
        }

        var socialWorkImageURL: NSURL?

        switch feed.kind {

        case .GithubRepo:

            socialWorkImageView.hidden = true
            githubRepoContainerView.hidden = false

            githubRepoImageView.tintColor = UIColor.grayColor()

            if let attachment = feed.attachment {
                if case let .Github(githubRepo) = attachment {
                    githubRepoNameLabel.text = githubRepo.name
                    githubRepoDescriptionLabel.text = githubRepo.description
                }
            }

        case .DribbbleShot:

            socialWorkImageView.hidden = false
            githubRepoContainerView.hidden = true

            if let attachment = feed.attachment {
                if case let .Dribbble(dribbbleShot) = attachment {
                    socialWorkImageURL = NSURL(string: dribbbleShot.imageURLString)
                }
            }

        default:
            break
        }

        if let URL = socialWorkImageURL {
            socialWorkImageView.kf_setImageWithURL(URL, placeholderImage: nil)
        }
    }

    private func updateUIForSocialWork(socialWork: MessageSocialWork) {

        var socialWorkImageURL: NSURL?

        guard let socialWorkType = MessageSocialWorkType(rawValue: socialWork.type) else {
            return
        }

        switch socialWorkType {

        case .GithubRepo:

            socialWorkImageView.hidden = true
            githubRepoContainerView.hidden = false

            githubRepoImageView.tintColor = UIColor.grayColor()

            if let githubRepo = socialWork.githubRepo {
                githubRepoNameLabel.text = githubRepo.name
                githubRepoDescriptionLabel.text = githubRepo.repoDescription
            }

        case .DribbbleShot:

            socialWorkImageView.hidden = false
            githubRepoContainerView.hidden = true

            if let string = socialWork.dribbbleShot?.imageURLString {
                socialWorkImageURL = NSURL(string: string)
            }

        case .InstagramMedia:

            socialWorkImageView.hidden = false
            githubRepoContainerView.hidden = true

            if let string = socialWork.instagramMedia?.imageURLString {
                socialWorkImageURL = NSURL(string: string)
            }
        }
        
        if let URL = socialWorkImageURL {
            socialWorkImageView.kf_setImageWithURL(URL, placeholderImage: nil)
        }
    }
}


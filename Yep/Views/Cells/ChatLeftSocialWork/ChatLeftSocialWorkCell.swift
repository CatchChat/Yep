//
//  ChatLeftSocialWorkCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class ChatLeftSocialWorkCell: UICollectionViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!

    @IBOutlet weak var socialWorkImageView: UIImageView!

    @IBOutlet weak var githubRepoContainerView: UIView!
    @IBOutlet weak var githubRepoImageView: UIImageView!
    @IBOutlet weak var githubRepoNameLabel: UILabel!
    @IBOutlet weak var githubRepoDescriptionLabel: UILabel!

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var syncButton: BorderButton!
    
    @IBOutlet weak var centerLineImageView: UIImageView!

    lazy var maskImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "social_media_image_mask"))
        return imageView
    }()

    var socialWork: MessageSocialWork?
    var createFeedAction: ((socialWork: MessageSocialWork) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        socialWorkImageView.maskView = maskImageView

        githubRepoImageView.tintColor = UIColor.yepIconImageViewTintColor()

        syncButton.setTitle(NSLocalizedString("Sync to Feeds", comment: ""), forState: .Normal)
        syncButton.setTitle(NSLocalizedString("Synced to Feeds", comment: ""), forState: .Disabled)

        syncButton.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        syncButton.setTitleColor(UIColor.lightGrayColor(), forState: .Disabled)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        maskImageView.frame = socialWorkImageView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        socialWorkImageView.image = nil
        socialWork = nil
    }

    func configureWithMessage(message: Message) {

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        if let socialWork = message.socialWork {

            self.socialWork = socialWork

            var socialWorkImageURL: NSURL?

            guard let
                socialWorkType = MessageSocialWorkType(rawValue: socialWork.type),
                socialAccount = SocialAccount(rawValue: socialWorkType.accountName)
            else {
                return
            }

            logoImageView.image = UIImage(named: socialAccount.iconName)
            logoImageView.tintColor = socialAccount.tintColor

            switch socialWorkType {

            case .GithubRepo:

                socialWorkImageView.hidden = true
                githubRepoContainerView.hidden = false
                centerLineImageView.hidden = false

                if let githubRepo = socialWork.githubRepo {
                    githubRepoNameLabel.text = githubRepo.name
                    githubRepoDescriptionLabel.text = githubRepo.repoDescription

                    syncButton.enabled = !githubRepo.synced
                }

            case .DribbbleShot:

                socialWorkImageView.hidden = false
                githubRepoContainerView.hidden = true
                centerLineImageView.hidden = true

                if let dribbbleShot = socialWork.dribbbleShot {
                    socialWorkImageURL = NSURL(string: dribbbleShot.imageURLString)

                    syncButton.enabled = !dribbbleShot.synced
                }

            case .InstagramMedia:

                socialWorkImageView.hidden = false
                githubRepoContainerView.hidden = true
                centerLineImageView.hidden = true

                if let string = socialWork.instagramMedia?.imageURLString {
                    socialWorkImageURL = NSURL(string: string)
                }
            }

            if let URL = socialWorkImageURL {
                socialWorkImageView.kf_setImageWithURL(URL, placeholderImage: nil)
            }
        }
    }

    @IBAction func sync(sender: BorderButton) {

        guard let socialWork = socialWork else {
            return
        }

        createFeedAction?(socialWork: socialWork)
    }
}


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

    var createFeedAction: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        socialWorkImageView.maskView = maskImageView

        githubRepoImageView.tintColor = UIColor.grayColor()

        syncButton.setTitle(NSLocalizedString("Sync to Feeds", comment: ""), forState: .Normal)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        maskImageView.frame = socialWorkImageView.bounds
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        socialWorkImageView.image = nil
    }

    func configureWithMessage(message: Message) {

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar)
        }

        if let socialWork = message.socialWork {

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
                }

            case .DribbbleShot:

                socialWorkImageView.hidden = false
                githubRepoContainerView.hidden = true
                centerLineImageView.hidden = true

                if let string = socialWork.dribbbleShot?.imageURLString {
                    socialWorkImageURL = NSURL(string: string)
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
        createFeedAction?()
    }
}


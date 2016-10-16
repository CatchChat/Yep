//
//  ChatLeftSocialWorkCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Kingfisher

final class ChatLeftSocialWorkCell: UICollectionViewCell {

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
        let imageView = UIImageView(image: UIImage.yep_socialMediaImageMask)
        return imageView
    }()

    var socialWork: MessageSocialWork?
    var createFeedAction: ((_ socialWork: MessageSocialWork) -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        socialWorkImageView.mask = maskImageView

        githubRepoImageView.tintColor = UIColor.yepIconImageViewTintColor()

        syncButton.setTitle(NSLocalizedString("Sync to Feeds", comment: ""), for: .normal)
        syncButton.setTitle(NSLocalizedString("Synced to Feeds", comment: ""), for: .disabled)

        syncButton.setTitleColor(UIColor.yepTintColor(), for: .normal)
        syncButton.setTitleColor(UIColor.lightGray, for: .disabled)
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

    func configureWithMessage(_ message: Message) {

        if let sender = message.fromFriend {
            let userAvatar = UserAvatar(userID: sender.userID, avatarURLString: sender.avatarURLString, avatarStyle: nanoAvatarStyle)
            avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        }

        if let socialWork = message.socialWork {

            self.socialWork = socialWork

            var socialWorkImageURL: URL?

            guard let
                socialWorkType = MessageSocialWorkType(rawValue: socialWork.type),
                let socialAccount = SocialAccount(rawValue: socialWorkType.accountName)
            else {
                return
            }

            logoImageView.image = UIImage(named: socialAccount.iconName)
            logoImageView.tintColor = socialAccount.tintColor

            switch socialWorkType {

            case .githubRepo:

                socialWorkImageView.isHidden = true
                githubRepoContainerView.isHidden = false
                centerLineImageView.isHidden = false

                if let githubRepo = socialWork.githubRepo {
                    githubRepoNameLabel.text = githubRepo.name
                    githubRepoDescriptionLabel.text = githubRepo.repoDescription

                    syncButton.isEnabled = !githubRepo.synced
                }

            case .dribbbleShot:

                socialWorkImageView.isHidden = false
                githubRepoContainerView.isHidden = true
                centerLineImageView.isHidden = true

                if let dribbbleShot = socialWork.dribbbleShot {
                    socialWorkImageURL = URL(string: dribbbleShot.imageURLString)

                    syncButton.isEnabled = !dribbbleShot.synced
                }

            case .instagramMedia:

                socialWorkImageView.isHidden = false
                githubRepoContainerView.isHidden = true
                centerLineImageView.isHidden = true

                if let string = socialWork.instagramMedia?.imageURLString {
                    socialWorkImageURL = URL(string: string)
                }
            }

            if let URL = socialWorkImageURL {
                socialWorkImageView.kf.setImage(with: URL, placeholder: nil)
            }
        }
    }

    @IBAction func sync(_ sender: BorderButton) {

        guard let socialWork = socialWork else {
            return
        }

        createFeedAction?(socialWork)
    }
}


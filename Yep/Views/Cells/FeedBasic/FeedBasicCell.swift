//
//  FeedBasicCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/20.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedBasicCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!

    @IBOutlet weak var skillButton: UIButton!

    @IBOutlet weak var messageTextView: FeedTextView!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var leftBottomLabel: UILabel!

    @IBOutlet weak var messageCountLabel: UILabel!

    var tapAvatarAction: (UITableViewCell -> Void)?
    var tapSkillAction: (UITableViewCell -> Void)?

    var touchesBeganAction: (UITableViewCell -> Void)?
    var touchesEndedAction: (UITableViewCell -> Void)?
    var touchesCancelledAction: (UITableViewCell -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()

        messageTextView.text = nil
        messageTextView.attributedText = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageTextView.textColor = UIColor.yepMessageColor()
        leftBottomLabel.textColor = UIColor.grayColor()
        messageCountLabel.textColor = UIColor.yepTintColor()
        skillButton.setTitleColor(UIColor.yepTintColor(), forState: .Normal)

        messageTextView.font = UIFont.feedMessageFont()
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        messageTextView.dataDetectorTypes = .Link

        skillButton.titleLabel?.font = UIFont.feedSkillFont()

        let tapAvatar = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapAvatar)

        skillButton.addTarget(self, action: "tapSkill:", forControlEvents: .TouchUpInside)

        messageTextView.touchesBeganAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesBeganAction?(strongSelf)
            }
        }
        messageTextView.touchesEndedAction = { [weak self] in
            if let strongSelf = self {
                if strongSelf.editing {
                    return
                }
                strongSelf.touchesEndedAction?(strongSelf)
            }
        }
        messageTextView.touchesCancelledAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesCancelledAction?(strongSelf)
            }
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func calHeightOfMessageTextView() {

        let rect = messageTextView.text.boundingRectWithSize(CGSize(width: FeedCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)
        messageTextViewHeightConstraint.constant = ceil(rect.height)
    }

    func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {

        messageTextView.text = "\u{200B}\(feed.body)" // ref http://stackoverflow.com/a/25994821

        calHeightOfMessageTextView()

        if needShowSkill, let skill = feed.skill {
            skillButton.setTitle(skill.localName, forState: .Normal)
            skillButton.hidden = false

        } else {
            skillButton.hidden = true
        }

        let plainAvatar = PlainAvatar(avatarURLString: feed.creator.avatarURLString, avatarStyle: nanoAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = feed.creator.nickname

        leftBottomLabel.text = feed.timeAndDistanceString

        messageCountLabel.text = "\(feed.messagesCount)"
        messageCountLabel.hidden = (feed.messagesCount == 0)
    }

    // MARK: Actions

    func tapAvatar(sender: UITapGestureRecognizer) {

        tapAvatarAction?(self)
    }

    func tapSkill(sender: AnyObject) {

        tapSkillAction?(self)
    }
}


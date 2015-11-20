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
    @IBOutlet weak var skillBubbleImageView: UIImageView!
    @IBOutlet weak var skillLabel: UILabel!

    @IBOutlet weak var messageTextView: FeedTextView!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dotLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var messageCountLabel: UILabel!

    var tapAvatarAction: (UITableViewCell -> Void)?
    var tapSkillAction: (UITableViewCell -> Void)?

    var touchesBeganAction: (UITableViewCell -> Void)?
    var touchesEndedAction: (UITableViewCell -> Void)?
    var touchesCancelledAction: (UITableViewCell -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()

        nicknameLabel.textColor = UIColor.yepTintColor()
        messageTextView.textColor = UIColor.yepMessageColor()
        distanceLabel.textColor = UIColor.grayColor()
        timeLabel.textColor = UIColor.grayColor()
        dotLabel.textColor = UIColor.grayColor()
        messageCountLabel.textColor = UIColor.yepTintColor()
        skillLabel.textColor = UIColor.yepTintColor()

        messageTextView.font = UIFont.feedMessageFont()
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        messageTextView.dataDetectorTypes = .Link

        let tapAvatar = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        avatarImageView.userInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapAvatar)

        let tapSkill = UITapGestureRecognizer(target: self, action: "tapSkill:")
        skillBubbleImageView.userInteractionEnabled = true
        skillBubbleImageView.addGestureRecognizer(tapSkill)

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

    // MARK: Actions

    func tapAvatar(sender: UITapGestureRecognizer) {

        tapAvatarAction?(self)
    }

    func tapSkill(sender: UITapGestureRecognizer) {

        tapSkillAction?(self)
    }
}


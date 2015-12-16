//
//  FeedBasicCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/20.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

private let screenWidth = UIScreen.mainScreen().bounds.width

class FeedBasicCell: UITableViewCell {

    //@IBOutlet weak var avatarImageView: UIImageView!
    //@IBOutlet weak var nicknameLabel: UILabel!

    //@IBOutlet weak var skillButton: UIButton!

    //@IBOutlet weak var messageTextView: FeedTextView!
    //@IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!

    //@IBOutlet weak var leftBottomLabel: UILabel!

    //@IBOutlet weak var messageCountLabel: UILabel!

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 15, y: 10, width: 40, height: 40)
        imageView.contentMode = .ScaleAspectFit

        let tapAvatar = UITapGestureRecognizer(target: self, action: "tapAvatar:")
        imageView.userInteractionEnabled = true
        imageView.addGestureRecognizer(tapAvatar)

        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFontOfSize(15)
        label.frame = CGRect(x: 65, y: 21, width: 100, height: 18)
        return label
    }()

    lazy var skillButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage(named: "sill_bubble_empty"), forState: .Normal)
        button.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        button.titleLabel?.font = UIFont.feedSkillFont()

        let cellWidth = self.bounds.width
        let width: CGFloat = 60
        button.frame = CGRect(x: cellWidth - width - 15, y: 19, width: width, height: 22)

        button.addTarget(self, action: "tapSkill:", forControlEvents: .TouchUpInside)

        return button
    }()

    lazy var messageTextView: FeedTextView = {
        let textView = FeedTextView()
        textView.textColor = UIColor.yepMessageColor()
        textView.font = UIFont.feedMessageFont()
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.dataDetectorTypes = .Link

        let cellWidth = self.bounds.width
        textView.frame = CGRect(x: 65, y: 54, width: cellWidth - 65 - 15, height: 26)

        textView.touchesBeganAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesBeganAction?(strongSelf)
            }
        }
        textView.touchesEndedAction = { [weak self] in
            if let strongSelf = self {
                if strongSelf.editing {
                    return
                }
                strongSelf.touchesEndedAction?(strongSelf)
            }
        }
        textView.touchesCancelledAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesCancelledAction?(strongSelf)
            }
        }

        return textView
    }()

    lazy var leftBottomLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFontOfSize(14)
        label.textColor = UIColor.grayColor()

        return label
    }()

    lazy var messageCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFontOfSize(14)
        label.textColor = UIColor.grayColor()
        return label
    }()

    lazy var discussionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_discussion")
        return imageView
    }()




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

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(skillButton)

        contentView.addSubview(messageTextView)

        contentView.addSubview(leftBottomLabel)
        contentView.addSubview(messageCountLabel)
        contentView.addSubview(discussionImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func calHeightOfMessageTextView() {

        let rect = messageTextView.text.boundingRectWithSize(CGSize(width: FeedCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)
        //messageTextViewHeightConstraint.constant = ceil(rect.height)
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


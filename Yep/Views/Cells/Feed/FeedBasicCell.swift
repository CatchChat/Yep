//
//  FeedBasicCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/20.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

private let screenWidth: CGFloat = UIScreen.mainScreen().bounds.width

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
        button.setBackgroundImage(UIImage(named: "skill_bubble_empty"), forState: .Normal)
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
        textView.editable = false
        textView.scrollEnabled = false
        textView.dataDetectorTypes = .Link

        textView.frame = CGRect(x: 65, y: 54, width: screenWidth - 65 - 15, height: 26)

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
        label.textColor = UIColor.grayColor()
        label.font = UIFont.feedBottomLabelsFont()

        label.frame = CGRect(x: 65, y: 0, width: 200, height: 17)

        return label
    }()

    lazy var messageCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.feedBottomLabelsFont()

        label.frame = CGRect(x: 65, y: 0, width: 200, height: 17)

        return label
    }()

    lazy var discussionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_discussion")
        return imageView
    }()

    var feed: DiscoveredFeed?

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

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.mainScreen().bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
    }()

    class func heightOfFeed(feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRectWithSize(CGSize(width: FeedBasicCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        let height: CGFloat = ceil(rect.height) + 10 + 40 + 4 + 15 + 17 + 15

        return ceil(height)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    private func calHeightOfMessageTextView() {

        let rect = messageTextView.text.boundingRectWithSize(CGSize(width: FeedBasicCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        messageTextView.frame.size.height = ceil(rect.height)
    }

    func configureWithFeed(feed: DiscoveredFeed, needShowSkill: Bool) {

        self.feed = feed

        messageTextView.text = "\u{200B}\(feed.body)" // ref http://stackoverflow.com/a/25994821

        calHeightOfMessageTextView()

        if needShowSkill, let skill = feed.skill {
            skillButton.setTitle(skill.localName, forState: .Normal)
            skillButton.hidden = false

            let rect = skill.localName.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.skillTextAttributes, context: nil)

            let skillButtonWidth = rect.width + 20

            skillButton.frame = CGRect(x: screenWidth - skillButtonWidth - 15, y: 19, width: skillButtonWidth, height: 22)

            nicknameLabel.frame.size.width = screenWidth - 65 - skillButtonWidth - 15 - 16 - 18

        } else {
            skillButton.hidden = true

            nicknameLabel.frame.size.width = screenWidth - 65 - 15
        }

        let plainAvatar = PlainAvatar(avatarURLString: feed.creator.avatarURLString, avatarStyle: nanoAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = feed.creator.nickname

        leftBottomLabel.text = feed.timeAndDistanceString

        let messagesCountString = "\(feed.messagesCount)"
        messageCountLabel.text = messagesCountString
        messageCountLabel.hidden = (feed.messagesCount == 0)

        leftBottomLabel.frame.origin.y = contentView.bounds.height - leftBottomLabel.frame.height - 10

        let rect = messagesCountString.boundingRectWithSize(CGSize(width: 320, height: CGFloat(FLT_MAX)), options: [.UsesLineFragmentOrigin, .UsesFontLeading], attributes: YepConfig.FeedBasicCell.bottomLabelsTextAttributes, context: nil)

        messageCountLabel.frame = CGRect(x: screenWidth - rect.width - 45 - 8, y: leftBottomLabel.frame.origin.y, width: rect.width, height: 19)

        discussionImageView.frame = CGRect(x: screenWidth - 30 - 15, y: leftBottomLabel.frame.origin.y - 1, width: 30, height: 19)
    }

    // MARK: Actions

    func tapAvatar(sender: UITapGestureRecognizer) {

        tapAvatarAction?(self)
    }

    func tapSkill(sender: AnyObject) {

        tapSkillAction?(self)
    }
}


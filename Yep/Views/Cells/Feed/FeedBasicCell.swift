//
//  FeedBasicCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/20.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RxSwift

private let screenWidth: CGFloat = UIScreen.main.bounds.width

class FeedBasicCell: UITableViewCell {

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.main.bounds.width - (15 + 40 + 10 + 15)
        return maxWidth
    }()

    class func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRect(with: CGSize(width: FeedBasicCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        let height: CGFloat = 10 + 40 + ceil(rect.height) + 4 + 15 + 17 + 15

        return ceil(height)
    }

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()

        imageView.frame = CGRect(x: 15, y: 10, width: 40, height: 40)

        imageView.contentMode = .scaleAspectFit

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(FeedBasicCell.tapAvatar(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapAvatar)

        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFont(ofSize: 15)

        label.frame = CGRect(x: 65, y: 21, width: 100, height: 18)
        label.isOpaque = true
        label.backgroundColor = UIColor.white
        label.clipsToBounds = true

        return label
    }()

    lazy var skillButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage.yep_skillBubbleEmpty, for: UIControlState())
        button.setTitleColor(UIColor.yepTintColor(), for: UIControlState())
        button.titleLabel?.font = UIFont.feedSkillFont()

        let cellWidth = self.bounds.width
        let width: CGFloat = 60
        button.frame = CGRect(x: cellWidth - width - 15, y: 19, width: width, height: 22)

        button.addTarget(self, action: #selector(FeedBasicCell.tapSkill(_:)), for: .touchUpInside)

        return button
    }()

    lazy var messageTextView: FeedTextView = {
        let textView = FeedTextView()
        textView.textColor = UIColor.yepMessageColor()
        textView.font = UIFont.feedMessageFont()
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.showsHorizontalScrollIndicator = false
        textView.showsVerticalScrollIndicator = false
        textView.dataDetectorTypes = [.link]

        textView.frame = CGRect(x: 65, y: 54, width: screenWidth - 65 - 15, height: 26)
        textView.isOpaque = true
        textView.backgroundColor = UIColor.white

        textView.touchesBeganAction = { [weak self] in
            if let strongSelf = self {
                strongSelf.touchesBeganAction?(strongSelf)
            }
        }
        textView.touchesEndedAction = { [weak self] in
            if let strongSelf = self {
                if strongSelf.isEditing {
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
        label.textColor = UIColor.gray
        label.font = UIFont.feedBottomLabelsFont()

        label.frame = CGRect(x: 65, y: 0, width: screenWidth - 65 - 85, height: 17)
        label.isOpaque = true
        label.backgroundColor = UIColor.white
        label.clipsToBounds = true

        return label
    }()

    lazy var messageCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.feedBottomLabelsFont()
        label.textAlignment = .right

        label.frame = CGRect(x: 65, y: 0, width: 200, height: 17)
        label.isOpaque = true
        label.backgroundColor = UIColor.white
        label.clipsToBounds = true

        return label
    }()

    lazy var discussionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_iconDiscussion
        return imageView
    }()

    lazy var uploadingErrorContainerView: FeedUploadingErrorContainerView = {
        let view = FeedUploadingErrorContainerView(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        return view
    }()

    var messagesCountEqualsZero = false {
        didSet {
            messageCountLabel.isHidden = messagesCountEqualsZero
        }
    }
    var hasUploadingErrorMessage = false {
        didSet {
            uploadingErrorContainerView.isHidden = !hasUploadingErrorMessage

            leftBottomLabel.isHidden = hasUploadingErrorMessage
            messageCountLabel.isHidden = hasUploadingErrorMessage || (self.messagesCountEqualsZero)
            discussionImageView.isHidden = hasUploadingErrorMessage
        }
    }

    var feed: DiscoveredFeed?

    var needShowDistance: Bool = false

    var tapAvatarAction: ((UITableViewCell) -> Void)?
    var tapSkillAction: ((UITableViewCell) -> Void)?

    var touchesBeganAction: ((UITableViewCell) -> Void)?
    var touchesEndedAction: ((UITableViewCell) -> Void)?
    var touchesCancelledAction: ((UITableViewCell) -> Void)?

    var retryUploadingFeedAction: ((_ cell: FeedBasicCell) -> Void)?
    var deleteUploadingFeedAction: ((_ cell: FeedBasicCell) -> Void)?

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

    fileprivate var disposableTimer: Disposable?

    deinit {
        disposableTimer?.dispose()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        feed = nil

        messageTextView.text = nil
        messageTextView.attributedText = nil

        disposableTimer?.dispose()
    }

    func configureWithFeed(_ feed: DiscoveredFeed, layout: FeedCellLayout, needShowSkill: Bool) {

        self.feed = feed

        let plainAvatar = PlainAvatar(avatarURLString: feed.creator.avatarURLString, avatarStyle: nanoAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = feed.creator.nickname

        messageTextView.text = "\u{200B}\(feed.body)" // ref http://stackoverflow.com/a/25994821
        //println("messageTextView.text: >>>\(messageTextView.text)<<<")

        let configureLeftBottomLabel: () -> Void = { [weak self] in
            guard let strongSelf = self else { return }
            if strongSelf.needShowDistance {
                strongSelf.leftBottomLabel.text = feed.timeAndDistanceString
            } else {
                strongSelf.leftBottomLabel.text = feed.id.isEmpty ? String.trans_promptUploading : feed.timeString
            }
        }
        configureLeftBottomLabel()
        disposableTimer = Observable<Int>
            .interval(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                configureLeftBottomLabel()
            })

        let messagesCountString = feed.messagesCount > 99 ? "99+" : "\(feed.messagesCount)"

        messageCountLabel.text = messagesCountString
        messagesCountEqualsZero = (feed.messagesCount == 0)

        let basicLayout = layout.basicLayout
        messageTextView.frame = basicLayout.messageTextViewFrame

        if needShowSkill, let skill = feed.skill {
            skillButton.setTitle(skill.localName, for: .normal)
            skillButton.isHidden = false

            skillButton.frame = basicLayout.skillButtonFrame
            nicknameLabel.frame = basicLayout.nicknameLabelFrameWhen(hasLogo: false, hasSkill: true)

        } else {
            skillButton.isHidden = true

            nicknameLabel.frame = basicLayout.nicknameLabelFrameWhen(hasLogo: false, hasSkill: false)
        }

        leftBottomLabel.frame = basicLayout.leftBottomLabelFrame
        messageCountLabel.frame = basicLayout.messageCountLabelFrame
        discussionImageView.frame = basicLayout.discussionImageViewFrame

        do {
            if let message = feed.uploadingErrorMessage {
                hasUploadingErrorMessage = true

                let y = leftBottomLabel.frame.origin.y - (30 - leftBottomLabel.frame.height) * 0.5
                uploadingErrorContainerView.frame = CGRect(x: 65, y: y, width: screenWidth - 65, height: 30)
                uploadingErrorContainerView.errorMessageLabel.text = message

                uploadingErrorContainerView.retryAction = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.retryUploadingFeedAction?(strongSelf)
                    }
                }

                uploadingErrorContainerView.deleteAction = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.deleteUploadingFeedAction?(strongSelf)
                    }
                }

                if uploadingErrorContainerView.superview == nil {
                    contentView.addSubview(uploadingErrorContainerView)
                }

            } else {
                hasUploadingErrorMessage = false
            }
        }
    }

    // MARK: Actions

    func tapAvatar(_ sender: UITapGestureRecognizer) {

        tapAvatarAction?(self)
    }

    func tapSkill(_ sender: AnyObject) {

        tapSkillAction?(self)
    }
}


//
//  SearchedFeedBasicCell.swift
//  Yep
//
//  Created by NIX on 16/4/19.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

class SearchedFeedBasicCell: UITableViewCell {

    static let messageTextViewMaxWidth: CGFloat = {
        let maxWidth = UIScreen.main.bounds.width - (10 + 30 + 10 + 10)
        return maxWidth
    }()

    class func heightOfFeed(_ feed: DiscoveredFeed) -> CGFloat {

        let rect = feed.body.boundingRect(with: CGSize(width: SearchedFeedBasicCell.messageTextViewMaxWidth, height: CGFloat(FLT_MAX)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: YepConfig.FeedBasicCell.textAttributes, context: nil)

        let height: CGFloat = 15 + 30 + 4 + ceil(rect.height) + 15

        return ceil(height)
    }
    
    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()

        imageView.frame = CGRect(x: 10, y: 15, width: 30, height: 30)

        imageView.contentMode = .scaleAspectFit

        let tapAvatar = UITapGestureRecognizer(target: self, action: #selector(SearchedFeedBasicCell.tapAvatar(_:)))
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(tapAvatar)

        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yep_mangmorGrayColor()
        label.font = UIFont.systemFont(ofSize: 15)

        label.frame = CGRect(x: 65, y: 21, width: 100, height: 18)
        label.isOpaque = true
        label.backgroundColor = UIColor.white
        label.clipsToBounds = true

        return label
    }()

    lazy var skillButton: UIButton = {
        let button = UIButton()
        let tintColor = UIColor.yep_mangmorGrayColor()
        button.setBackgroundImage(UIImage.yep_skillBubbleEmptyGray, for: .normal)
        button.setTitleColor(tintColor, for: .normal)
        button.titleLabel?.font = UIFont.feedSkillFont()

        let cellWidth = self.bounds.width
        let width: CGFloat = 60
        button.frame = CGRect(x: cellWidth - width - 15, y: 19, width: width, height: 22)

        button.isUserInteractionEnabled = false

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

    var feed: DiscoveredFeed?
    
    var tapAvatarAction: ((UITableViewCell) -> Void)?

    var touchesBeganAction: ((UITableViewCell) -> Void)?
    var touchesEndedAction: ((UITableViewCell) -> Void)?
    var touchesCancelledAction: ((UITableViewCell) -> Void)?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(skillButton)

        contentView.addSubview(messageTextView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        feed = nil

        messageTextView.text = nil
        messageTextView.attributedText = nil
    }

    func configureWithFeed(_ feed: DiscoveredFeed, layout: SearchedFeedCellLayout, keyword: String?) {

        self.feed = feed

        let plainAvatar = PlainAvatar(avatarURLString: feed.creator.avatarURLString, avatarStyle: nanoAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = feed.creator.nickname

        let text = "\u{200B}\(feed.body)" // ref http://stackoverflow.com/a/25994821

        if let highlightedKeywordsBody = feed.highlightedKeywordsBody {

            let keywordSet = highlightedKeywordsBody.yep_keywordSetOfEmphasisTags()

            if let attributedText = text.yep_highlightWithKeywordSet(keywordSet, color: UIColor.yepTintColor(), baseFont: UIFont.feedMessageFont(), baseColor: UIColor.yepMessageColor()) {
                messageTextView.attributedText = attributedText

            } else {
                messageTextView.text = text
            }

        } else {
            messageTextView.text = text
        }

        // layout

        let basicLayout = layout.basicLayout
        avatarImageView.frame = basicLayout.avatarImageViewFrame
        messageTextView.frame = basicLayout.messageTextViewFrame

        if let skill = feed.skill {
            skillButton.setTitle(skill.localName, for: .normal)
            skillButton.isHidden = false
            skillButton.frame = basicLayout.skillButtonFrame
            nicknameLabel.frame = basicLayout.nicknameLabelFrameWhen(hasLogo: false, hasSkill: true)

        } else {
            skillButton.isHidden = true
            nicknameLabel.frame = basicLayout.nicknameLabelFrameWhen(hasLogo: false, hasSkill: false)
        }
    }

    // MARK: Actions

    func tapAvatar(_ sender: UITapGestureRecognizer) {

        tapAvatarAction?(self)
    }
}


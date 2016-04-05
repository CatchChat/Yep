//
//  SearchedUserCell.swift
//  Yep
//
//  Created by NIX on 16/4/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedUserCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = YepConfig.ContactsCell.separatorInset
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureWithUser(user: User, keyword: String?) {

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        if let keyword = keyword {

            let text = user.nickname
            let attributedString = NSMutableAttributedString(string: text)
            let textRange = NSMakeRange(0, (text as NSString).length)

            // highlight keyword

            let highlightTextAttributes: [String: AnyObject] = [
                NSForegroundColorAttributeName: UIColor.yepTintColor(),
            ]

            let highlightExpression = try! NSRegularExpression(pattern: keyword, options: [.CaseInsensitive])

            highlightExpression.enumerateMatchesInString(text, options: NSMatchingOptions(), range: textRange, usingBlock: { result, flags, stop in

                if let result = result {
                    attributedString.addAttributes(highlightTextAttributes, range: result.range )
                }
            })

            nicknameLabel.attributedText = attributedString
            
        } else {
            nicknameLabel.text = user.nickname
        }
    }
}

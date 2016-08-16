//
//  GithubRepoCell.swift
//  Yep
//
//  Created by NIX on 15/5/12.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class GithubRepoCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameLabelLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var starCountLabel: UILabel!
    @IBOutlet weak var starCountLabelTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.textColor = UIColor.yepTintColor()

        nameLabelLeadingConstraint.constant = YepConfig.SocialWorkGithub.Repo.rightEdgeInset
        starCountLabelTrailingConstraint.constant = YepConfig.SocialWorkGithub.Repo.leftEdgeInset
    }
}
    

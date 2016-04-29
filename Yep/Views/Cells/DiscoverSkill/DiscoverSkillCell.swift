//
//  DiscoverSkillCell.swift
//  Yep
//
//  Created by zhowkevin on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class DiscoverSkillCell: UICollectionViewCell {

    @IBOutlet weak var skillLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        skillLabel.font = UIFont.skillDiscoverTextFont()
        skillLabel.backgroundColor = UIColor.yepTintColor()
        // Initialization code
    }

}

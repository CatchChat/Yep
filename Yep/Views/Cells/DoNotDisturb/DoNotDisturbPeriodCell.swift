//
//  DoNotDisturbPeriodCell.swift
//  
//
//  Created by NIX on 15/8/3.
//
//

import UIKit

final class DoNotDisturbPeriodCell: UITableViewCell {

    @IBOutlet weak var fromPromptLabel: UILabel!

    @IBOutlet weak var toPromptLabel: UILabel!

    @IBOutlet weak var fromLabel: UILabel!

    @IBOutlet weak var toLabel: UILabel!

    @IBOutlet weak var accessoryImageView: UIImageView!

    
    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }
}
    

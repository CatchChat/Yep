//
//  DoNotDisturbPeriodCell.swift
//  
//
//  Created by NIX on 15/8/3.
//
//

import UIKit

class DoNotDisturbPeriodCell: UITableViewCell {

    @IBOutlet weak var fromPromptLabel: UILabel!

    @IBOutlet weak var toPromptLabel: UILabel!

    @IBOutlet weak var fromLabel: UILabel!

    @IBOutlet weak var toLabel: UILabel!


    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

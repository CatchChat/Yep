//
//  DoNotDisturbSwitchCell.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class DoNotDisturbSwitchCell: UITableViewCell {


    @IBOutlet weak var promptLabel: UILabel!

    @IBOutlet weak var toggleSwitch: UISwitch!


    var toggleAction: (Bool -> Void)?


    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - Actions

    @IBAction func toggleDoNotDisturb(sender: UISwitch) {
        toggleAction?(sender.on)
    }

}

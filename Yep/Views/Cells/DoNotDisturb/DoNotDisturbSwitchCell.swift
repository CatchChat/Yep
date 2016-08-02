//
//  DoNotDisturbSwitchCell.swift
//  Yep
//
//  Created by NIX on 15/8/3.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class DoNotDisturbSwitchCell: UITableViewCell {

    var toggleAction: (Bool -> Void)?

    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var toggleSwitch: UISwitch!

    // MARK: - Actions

    @IBAction func toggleDoNotDisturb(sender: UISwitch) {
        toggleAction?(sender.on)
    }
}


//
//  AddFriendSearchCell.swift
//  Yep
//
//  Created by NIX on 15/5/19.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class AddFriendSearchCell: UITableViewCell {

    @IBOutlet weak var searchTextField: UITextField!

    override func awakeFromNib() {
        super.awakeFromNib()

        searchTextField.placeholder = NSLocalizedString("Search User", comment: "")
    }
}
    

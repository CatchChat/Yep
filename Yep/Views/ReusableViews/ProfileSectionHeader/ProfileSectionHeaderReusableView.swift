//
//  ProfileSectionHeaderReusableView.swift
//  Yep
//
//  Created by NIX on 15/3/18.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileSectionHeaderReusableView: UICollectionReusableView {

    var tapAction: (() -> Void)?

    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let tap = UITapGestureRecognizer(target: self, action: "tap")
        addGestureRecognizer(tap)
    }

    func tap() {
        tapAction?()
    }
    
}

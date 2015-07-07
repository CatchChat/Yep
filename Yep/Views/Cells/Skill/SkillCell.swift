//
//  SkillCell.swift
//  Yep
//
//  Created by NIX on 15/4/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SkillCell: UICollectionViewCell {

    static let height: CGFloat = 24

    @IBOutlet weak var backgroundImageView: UIImageView!
    
    @IBOutlet weak var skillLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        skillLabel.font = UIFont.skillTextFont()
    }

    var tapped: Bool = false {
        willSet {
            UIView.animateWithDuration(0.1, delay: 0.0, options: .CurveEaseInOut, animations: { _ in
                self.backgroundImageView.tintColor = newValue ? UIColor.blackColor().colorWithAlphaComponent(0.25) : UIColor.yepTintColor()
            }, completion: { finished in
            })
        }
    }

    var skillID: String?
    var skillLocalName: String? {
        willSet {
            skillLabel.text = newValue
        }
    }

    var tapAction: ((skillID: String, skillLocalName: String) -> Void)?

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        tapped = true
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {

        delay(0.15) { [weak self] in
            self?.tapped = false

            if let skillID = self?.skillID, skillLocalName = self?.skillLocalName {
                self?.tapAction?(skillID: skillID, skillLocalName: skillLocalName)
            }
        }
    }

    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        tapped = false
    }
}

//
//  SkillCell.swift
//  Yep
//
//  Created by NIX on 15/4/8.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class SkillCell: UICollectionViewCell {

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

    class Skill: NSObject {
        let ID: String
        let localName: String
        let coverURLString: String?

        enum Category: String {
            case Art = "Art"
            case Technology = "Technology"
            case Sport = "Sport"
            case LifeStyle = "Life Style"

            var gradientImage: UIImage? {
                switch self {
                case .Art:
                    return UIImage(named: "gradient_art")
                case .Technology:
                    return UIImage(named: "gradient_tech")
                case .Sport:
                    return UIImage(named: "gradient_sport")
                case .LifeStyle:
                    return UIImage(named: "gradient_life")
                }
            }
        }
        let category: Category

        init(ID: String, localName: String, coverURLString: String?, category: Category?) {
            self.ID = ID
            self.localName = localName
            self.coverURLString = coverURLString
            self.category = category ?? .Art
        }
    }

    var skill: Skill? {
        willSet {
            skillLabel.text = newValue?.localName
        }
    }

    var tapAction: ((skill: Skill) -> Void)?

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        tapped = true
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {

        delay(0.15) { [weak self] in

            if let strongSelf = self {

                strongSelf.tapped = false

                if let skill = strongSelf.skill {
                    strongSelf.tapAction?(skill: skill)
                }
            }
        }
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        tapped = false
    }
}

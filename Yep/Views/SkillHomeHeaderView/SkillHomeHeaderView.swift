//
//  SkillHomeHeaderView.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SkillHomeHeaderView: UIView {
    
    lazy var headerImageView: UIImageView = {
        let tempImageView = UIImageView(frame: CGRectZero)
        tempImageView.contentMode = UIViewContentMode.ScaleAspectFill
        tempImageView.clipsToBounds = true
        return tempImageView;
    }()
    
    lazy var masterButton: SkillHomeSectionButton = {
        let button = createSkillHomeButtonWithText("Master", 100, YepConfig.skillHomeHeaderButtonHeight)
        return button
    }()
    
    lazy var learningButton: SkillHomeSectionButton = {
        let button = createSkillHomeButtonWithText("Learning", 100, YepConfig.skillHomeHeaderButtonHeight)
        return button
    }()

    var changeCoverAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }
    
    func setup() {
        headerImageView.image = UIImage(named: "Cover3")

        addSubview(headerImageView)
        addSubview(masterButton)
        addSubview(learningButton)

        backgroundColor = UIColor.lightGrayColor()

        headerImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: "tap")
        headerImageView.addGestureRecognizer(tap)
    }

    func tap() {
        changeCoverAction?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        masterButton.setActive()

        headerImageView.frame = self.bounds

        masterButton.frame = CGRectMake(0, self.frame.height - YepConfig.skillHomeHeaderButtonHeight, self.frame.size.width/2.0, YepConfig.skillHomeHeaderButtonHeight)
        
        masterButton.updateHightLightBounce()
        
        learningButton.frame = CGRectMake(masterButton.frame.size.width, self.frame.height - YepConfig.skillHomeHeaderButtonHeight, self.frame.size.width/2.0, YepConfig.skillHomeHeaderButtonHeight)
        
        learningButton.updateHightLightBounce()
    }

}

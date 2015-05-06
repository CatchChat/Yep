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
        
        var tempImageView = UIImageView(frame: CGRectZero)
        
        tempImageView.contentMode = UIViewContentMode.ScaleAspectFill
        tempImageView.clipsToBounds = true
        
        return tempImageView;
        
    }()
    
    lazy var masterButton: SkillHomeSectionButton = {
        var button = createSkillHomeButtonWithText("Master", 100, YepConfig.skillHomeHeaderButtonHeight)
        return button
    }()
    
    lazy var learningButton: SkillHomeSectionButton = {
        var button = createSkillHomeButtonWithText("Learning", 100, YepConfig.skillHomeHeaderButtonHeight)
        return button
    }()
    
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
        self.addSubview(headerImageView)
        self.addSubview(masterButton)
        self.addSubview(learningButton)
        self.backgroundColor = UIColor.lightGrayColor()

    }
    
    
    override func layoutSubviews() {
        masterButton.setActive()
        headerImageView.frame = self.bounds
        masterButton.frame = CGRectMake(0, self.frame.height - YepConfig.skillHomeHeaderButtonHeight, self.frame.size.width/2.0, YepConfig.skillHomeHeaderButtonHeight)
        
        masterButton.updateHightLightBounce()
        
        learningButton.frame = CGRectMake(masterButton.frame.size.width, self.frame.height - YepConfig.skillHomeHeaderButtonHeight, self.frame.size.width/2.0, YepConfig.skillHomeHeaderButtonHeight)
        
        learningButton.updateHightLightBounce()
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    

}

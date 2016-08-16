//
//  SkillHomeHeaderView.swift
//  Yep
//
//  Created by kevinzhow on 15/5/6.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Kingfisher

final class SkillHomeHeaderView: UIView {

    var skillCategory: SkillCellSkill.Category = .Art
    var skillCoverURLString: String? {
        willSet {
//            if let coverURLString = newValue, URL = NSURL(string: coverURLString) {
//                headerImageView.kf_setImageWithURL(URL, placeholderImage: skillCategory.gradientImage)
//
//            } else {
//                headerImageView.image = skillCategory.gradientImage
//            }
        }
    }
    
    lazy var headerImageView: UIImageView = {
        let tempImageView = UIImageView(frame: CGRectZero)
        tempImageView.contentMode = .ScaleAspectFill
        tempImageView.clipsToBounds = true
        tempImageView.backgroundColor = UIColor.whiteColor()
        return tempImageView;
    }()
    
    lazy var masterButton: SkillHomeSectionButton = {
        let button = createSkillHomeButtonWithText(SkillSet.Master.name, width: 100, height: YepConfig.skillHomeHeaderButtonHeight)
        return button
    }()
    
    lazy var learningButton: SkillHomeSectionButton = {
        let button = createSkillHomeButtonWithText(SkillSet.Learning.name, width: 100, height: YepConfig.skillHomeHeaderButtonHeight)
        return button
    }()

    var changeCoverAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }
    
    func setup() {

        addSubview(headerImageView)
        addSubview(masterButton)
        addSubview(learningButton)

        backgroundColor = UIColor.lightGrayColor()

        headerImageView.userInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(SkillHomeHeaderView.tap))
        headerImageView.addGestureRecognizer(tap)
    }

    func tap() {
        changeCoverAction?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        headerImageView.frame = self.bounds

        masterButton.frame = CGRectMake(0, self.frame.height - YepConfig.skillHomeHeaderButtonHeight, self.frame.size.width/2.0, YepConfig.skillHomeHeaderButtonHeight)
        
        masterButton.updateHightLightBounce()
        
        learningButton.frame = CGRectMake(masterButton.frame.size.width, self.frame.height - YepConfig.skillHomeHeaderButtonHeight, self.frame.size.width/2.0, YepConfig.skillHomeHeaderButtonHeight)
        
        learningButton.updateHightLightBounce()
    }
}


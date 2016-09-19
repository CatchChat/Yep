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
        let tempImageView = UIImageView(frame: CGRect.zero)
        tempImageView.contentMode = .scaleAspectFill
        tempImageView.clipsToBounds = true
        tempImageView.backgroundColor = UIColor.white
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

        backgroundColor = UIColor.lightGray

        headerImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(SkillHomeHeaderView.tap))
        headerImageView.addGestureRecognizer(tap)
    }

    func tap() {
        changeCoverAction?()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        headerImageView.frame = self.bounds

        masterButton.frame = CGRect(x: 0, y: self.frame.height - YepConfig.skillHomeHeaderButtonHeight, width: self.frame.size.width/2.0, height: YepConfig.skillHomeHeaderButtonHeight)
        
        masterButton.updateHightLightBounce()
        
        learningButton.frame = CGRect(x: masterButton.frame.size.width, y: self.frame.height - YepConfig.skillHomeHeaderButtonHeight, width: self.frame.size.width/2.0, height: YepConfig.skillHomeHeaderButtonHeight)
        
        learningButton.updateHightLightBounce()
    }
}


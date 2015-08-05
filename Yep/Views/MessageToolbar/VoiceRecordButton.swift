//
//  VoiceRecordButton.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class VoiceRecordButton: UIView {
    
    var touchesBegin : (() -> ())?
    
    var touchesEnded : (() -> ())?
    
    var touchesCancelled : (() -> ())?
    
    var touchesMoved : (() -> ())?
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesBegan(touches, withEvent: event)
        
        touchesBegin?()
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesEnded(touches, withEvent: event)
        
        touchesEnded?()
    }
    
    override func touchesCancelled(touches: Set<NSObject>!, withEvent event: UIEvent!) {
        super.touchesCancelled(touches, withEvent: event)
        
        touchesCancelled?()
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        super.touchesMoved(touches, withEvent: event)
        
        touchesMoved?()
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    private func makeUI() {

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFontOfSize(15.0)
        titleLabel.text = NSLocalizedString("Hold for Voice", comment: "")
        titleLabel.textAlignment = .Center
        titleLabel.textColor = self.tintColor

        self.addSubview(titleLabel)
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)

        let leftVoiceImageView = UIImageView(image: UIImage(named: "icon_voice_left"))
        leftVoiceImageView.contentMode = .Center
        leftVoiceImageView.tintColor = self.tintColor

        self.addSubview(leftVoiceImageView)
        leftVoiceImageView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let rightVoiceImageView = UIImageView(image: UIImage(named: "icon_voice_right"))
        rightVoiceImageView.contentMode = .Center
        rightVoiceImageView.tintColor = self.tintColor

        self.addSubview(rightVoiceImageView)
        rightVoiceImageView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "leftVoiceImageView": leftVoiceImageView,
            "titleLabel": titleLabel,
            "rightVoiceImageView": rightVoiceImageView,
        ]

        let leftVoiceImageViewConstraintCenterY = NSLayoutConstraint(item: leftVoiceImageView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self, attribute: NSLayoutAttribute.CenterY, multiplier: 1, constant: 0)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-10-[leftVoiceImageView(20)][titleLabel][rightVoiceImageView(==leftVoiceImageView)]-10-|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints([leftVoiceImageViewConstraintCenterY])
        NSLayoutConstraint.activateConstraints(constraintsH)
    }

}

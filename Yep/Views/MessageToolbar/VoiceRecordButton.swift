//
//  VoiceRecordButton.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class VoiceRecordButton: UIView {
    
    var touchesBegin: (() -> Void)?
    
    var touchesEnded: ((needAbort: Bool) -> Void)?
    
    var touchesCancelled: (() -> Void)?

    var checkAbort: ((topOffset: CGFloat) -> Bool)?

    var abort = false

    var titleLabel: UILabel?
    var leftVoiceImageView: UIImageView?
    var rightVoiceImageView: UIImageView?

    enum State {
        case Default
        case Touched
    }

    var state: State = .Default {
        willSet {
            let color: UIColor
            switch newValue {
            case .Default:
                color = UIColor.yepMessageToolbarSubviewBorderColor()
            case .Touched:
                color = UIColor.yepTintColor()
            }
            layer.borderColor = color.CGColor
            leftVoiceImageView?.tintColor = color
            rightVoiceImageView?.tintColor = color

            switch newValue {
            case .Default:
                titleLabel?.textColor = tintColor
            case .Touched:
                titleLabel?.textColor = UIColor.yepTintColor()
            }
        }
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        abort = false
        
        touchesBegin?()

        titleLabel?.text = NSLocalizedString("Release to Send", comment: "")
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesEnded(touches, withEvent: event)
        
        touchesEnded?(needAbort: abort)

        titleLabel?.text = NSLocalizedString("Hold for Voice", comment: "")
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        super.touchesCancelled(touches, withEvent: event)
        
        touchesCancelled?()

        titleLabel?.text = NSLocalizedString("Hold for Voice", comment: "")
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesMoved(touches, withEvent: event)
        
        if let touch = touches.first {
            let location = touch.locationInView(touch.view)

            if location.y < 0 {
                abort = checkAbort?(topOffset: abs(location.y)) ?? false
            }
        }
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

        self.titleLabel = titleLabel

        self.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let leftVoiceImageView = UIImageView(image: UIImage(named: "icon_voice_left"))
        leftVoiceImageView.contentMode = .Center
        leftVoiceImageView.tintColor = self.tintColor

        self.leftVoiceImageView = leftVoiceImageView

        self.addSubview(leftVoiceImageView)
        leftVoiceImageView.translatesAutoresizingMaskIntoConstraints = false

        let rightVoiceImageView = UIImageView(image: UIImage(named: "icon_voice_right"))
        rightVoiceImageView.contentMode = .Center
        rightVoiceImageView.tintColor = self.tintColor

        self.rightVoiceImageView = rightVoiceImageView

        self.addSubview(rightVoiceImageView)
        rightVoiceImageView.translatesAutoresizingMaskIntoConstraints = false

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


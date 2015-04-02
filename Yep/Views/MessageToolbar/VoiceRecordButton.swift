//
//  VoiceRecordButton.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class VoiceRecordButton: UIView {

    typealias longPressAction = (UILongPressGestureRecognizer) -> Void

    var pressBeganAction: longPressAction?

    var pressChangedAction: longPressAction?

    var pressEndedAction: longPressAction?

    var pressCancelledAction: longPressAction?


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        let longPress = UILongPressGestureRecognizer(target: self, action: "handleLongPressGestureRecognizer:")
        longPress.minimumPressDuration = 0.05
        
        self.addGestureRecognizer(longPress)
    }

    private func makeUI() {

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFontOfSize(15.0)
        titleLabel.text = NSLocalizedString("Hold for Voice", comment: "")
        titleLabel.textAlignment = .Center
        titleLabel.textColor = UIColor.lightGrayColor()

        self.addSubview(titleLabel)
        titleLabel.setTranslatesAutoresizingMaskIntoConstraints(false)

        let leftVoiceImageView = UIImageView(image: UIImage(named: "icon_voice_left"))
        leftVoiceImageView.contentMode = .Center

        self.addSubview(leftVoiceImageView)
        leftVoiceImageView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let rightVoiceImageView = UIImageView(image: UIImage(named: "icon_voice_right"))
        rightVoiceImageView.contentMode = .Center

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

    func handleLongPressGestureRecognizer(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        switch longPressGestureRecognizer.state {
        case .Began:
            if let pressBeganAction = pressBeganAction {
                pressBeganAction(longPressGestureRecognizer)
            }
        case .Changed:
            if let pressChangedAction = pressChangedAction {
                pressChangedAction(longPressGestureRecognizer)
            }
        case .Ended:
            if let pressEndedAction = pressEndedAction {
                pressEndedAction(longPressGestureRecognizer)
            }
        case .Cancelled:
            if let pressCancelledAction = pressCancelledAction {
                pressCancelledAction(longPressGestureRecognizer)
            }
        default:
            break
        }
    }
}

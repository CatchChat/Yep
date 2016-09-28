//
//  VoiceRecordButton.swift
//  Yep
//
//  Created by NIX on 15/4/2.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class VoiceRecordButton: UIView {
    
    var touchesBegin: (() -> Void)?
    
    var touchesEnded: ((_ needAbort: Bool) -> Void)?
    
    var touchesCancelled: (() -> Void)?

    var checkAbort: ((_ topOffset: CGFloat) -> Bool)?

    var abort = false

    var titleLabel: UILabel?
    var leftVoiceImageView: UIImageView?
    var rightVoiceImageView: UIImageView?

    enum State {
        case `default`
        case touched
    }

    var state: State = .default {
        willSet {
            let color: UIColor
            switch newValue {
            case .default:
                color = UIColor.yepMessageToolbarSubviewBorderColor()
            case .touched:
                color = UIColor.yepTintColor()
            }
            layer.borderColor = color.cgColor
            leftVoiceImageView?.tintColor = color
            rightVoiceImageView?.tintColor = color

            switch newValue {
            case .default:
                titleLabel?.textColor = tintColor
            case .touched:
                titleLabel?.textColor = UIColor.yepTintColor()
            }
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        abort = false
        
        touchesBegin?()

        titleLabel?.text = NSLocalizedString("Release to Send", comment: "")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        touchesEnded?(abort)

        titleLabel?.text = String.trans_promptHoldForVoice
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        touchesCancelled?()

        titleLabel?.text = String.trans_promptHoldForVoice
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        if let touch = touches.first {
            let location = touch.location(in: touch.view)

            if location.y < 0 {
                abort = checkAbort?(abs(location.y)) ?? false
            }
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    fileprivate func makeUI() {

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 15.0)
        titleLabel.text = String.trans_promptHoldForVoice
        titleLabel.textAlignment = .center
        titleLabel.textColor = self.tintColor

        self.titleLabel = titleLabel

        self.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let leftVoiceImageView = UIImageView(image: UIImage.yep_iconVoiceLeft)
        leftVoiceImageView.contentMode = .center
        leftVoiceImageView.tintColor = self.tintColor

        self.leftVoiceImageView = leftVoiceImageView

        self.addSubview(leftVoiceImageView)
        leftVoiceImageView.translatesAutoresizingMaskIntoConstraints = false

        let rightVoiceImageView = UIImageView(image: UIImage.yep_iconVoiceRight)
        rightVoiceImageView.contentMode = .center
        rightVoiceImageView.tintColor = self.tintColor

        self.rightVoiceImageView = rightVoiceImageView

        self.addSubview(rightVoiceImageView)
        rightVoiceImageView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "leftVoiceImageView": leftVoiceImageView,
            "titleLabel": titleLabel,
            "rightVoiceImageView": rightVoiceImageView,
        ]

        let leftVoiceImageViewConstraintCenterY = NSLayoutConstraint(item: leftVoiceImageView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-10-[leftVoiceImageView(20)][titleLabel][rightVoiceImageView(==leftVoiceImageView)]-10-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views)

        NSLayoutConstraint.activate([leftVoiceImageViewConstraintCenterY])
        NSLayoutConstraint.activate(constraintsH)
    }
}


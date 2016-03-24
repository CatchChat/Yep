//
//  MediaControlView.swift
//  Yep
//
//  Created by NIX on 15/5/7.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

//@IBDesignable
class MediaControlView: UIView {

    enum Type {
        case Image
        case Video
    }

    var type: Type = .Video {
        didSet {

            guard type != oldValue else {
                return
            }

            switch type {
                
            case .Image:
                timeLabel.hidden = true
                playButton.hidden = true
                shareButton.setImage(UIImage(named: "icon_more_image"), forState: .Normal)

            case .Video:
                timeLabel.hidden = false
                playButton.hidden = false
            }
        }
    }

    enum PlayState {
        case Playing
        case Pause
    }

    var playState: PlayState = .Pause {
        didSet {
            switch playState {
            case .Playing:
                playButton.setImage(UIImage(named: "icon_pause"), forState: .Normal)
            case .Pause:
                playButton.setImage(UIImage(named: "icon_play"), forState: .Normal)
            }
        }
    }

    var playAction: (MediaControlView -> Void)?
    var pauseAction: (MediaControlView -> Void)?

    var shareAction: (() -> Void)?

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        if #available(iOS 8.2, *) {
            label.font = UIFont.systemFontOfSize(14, weight: UIFontWeightLight)
        } else {
            label.font = UIFont(name: "HelveticaNeue-Light", size: 14)!
        }
        label.textColor = UIColor.whiteColor()
        label.text = "00:42"
        return label
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_play"), forState: .Normal)
        button.tintColor = UIColor.whiteColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: "playOrPause", forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }()

    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_more"), forState: .Normal)
        button.tintColor = UIColor.whiteColor()
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        button.addTarget(self, action: "share", forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clearColor()

        makeUI()
    }

    func makeUI() {
        addSubview(timeLabel)
        addSubview(playButton)
        addSubview(shareButton)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary = [
            "timeLable": timeLabel,
            "playButton": playButton,
            "shareButton": shareButton,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[timeLable]|", options: [], metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-30-[timeLable]-(>=0)-[playButton]-(>=0)-[shareButton]|", options: [.AlignAllCenterY, .AlignAllTop, .AlignAllBottom], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(constraintsV)
        NSLayoutConstraint.activateConstraints(constraintsH)

        let playButtonConstraintCenterX = NSLayoutConstraint(item: playButton, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints([playButtonConstraintCenterX])
    }

    // MARK: Actions

    func playOrPause() {

        switch playState {

        case .Playing:
            if let action = pauseAction {
                action(self)
            }

        case .Pause:
            if let action = playAction {
                action(self)
            }
        }
    }

    func share() {
        if let action = shareAction {
            action()
        }
    }

    override func drawRect(rect: CGRect) {

        let startColor: UIColor = UIColor.clearColor()
        let endColor: UIColor = UIColor.blackColor().colorWithAlphaComponent(0.2)

        let context = UIGraphicsGetCurrentContext()
        let colors = [startColor.CGColor, endColor.CGColor]

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let colorLocations:[CGFloat] = [0.0, 1.0]

        let gradient = CGGradientCreateWithColors(colorSpace, colors, colorLocations)

        let startPoint = CGPointZero
        let endPoint = CGPoint(x:0, y: rect.height)

        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, CGGradientDrawingOptions(rawValue: 0))
    }
}


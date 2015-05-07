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
            switch type {
                
            case .Image:
                timeLabel.hidden = true
                playButton.hidden = true

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

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .Center
        label.font = UIFont(name: "HelveticaNeue-Light", size: 14)
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
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: "share", forControlEvents: UIControlEvents.TouchUpInside)
        return button
        }()


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {
        addSubview(timeLabel)
        addSubview(playButton)
        addSubview(shareButton)

        timeLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        playButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        shareButton.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "timeLable": timeLabel,
            "playButton": playButton,
            "shareButton": shareButton,
        ]

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[timeLable]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-20-[timeLable]-(>=0)-[playButton]-(>=0)-[shareButton]|", options: .AlignAllCenterY | .AlignAllTop | .AlignAllBottom, metrics: nil, views: viewsDictionary)

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

}

//
//  MediaControlView.swift
//  Yep
//
//  Created by NIX on 15/5/7.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

//@IBDesignable
final class MediaControlView: UIView {

    enum Type {
        case image
        case video
    }

    var type: Type = .video {
        didSet {

            guard type != oldValue else {
                return
            }

            switch type {
                
            case .image:
                timeLabel.isHidden = true
                playButton.isHidden = true
                shareButton.setImage(UIImage.yep_iconMoreImage, for: UIControlState())

            case .video:
                timeLabel.isHidden = false
                playButton.isHidden = false
            }
        }
    }

    enum PlayState {
        case playing
        case pause
    }

    var playState: PlayState = .pause {
        didSet {
            switch playState {
            case .playing:
                playButton.setImage(UIImage.yep_iconPause, for: UIControlState())
            case .pause:
                playButton.setImage(UIImage.yep_iconPlay, for: UIControlState())
            }
        }
    }

    var playAction: ((MediaControlView) -> Void)?
    var pauseAction: ((MediaControlView) -> Void)?

    var shareAction: (() -> Void)?

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightLight)
        label.textColor = UIColor.white
        label.text = "00:42"
        return label
    }()

    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_iconPlay, for: UIControlState())
        button.tintColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        button.addTarget(self, action: #selector(MediaControlView.playOrPause), for: UIControlEvents.touchUpInside)
        return button
    }()

    lazy var shareButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_iconMore, for: UIControlState())
        button.tintColor = UIColor.white
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 30)
        button.addTarget(self, action: #selector(MediaControlView.share), for: UIControlEvents.touchUpInside)
        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clear

        makeUI()
    }

    func makeUI() {
        addSubview(timeLabel)
        addSubview(playButton)
        addSubview(shareButton)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        shareButton.translatesAutoresizingMaskIntoConstraints = false

        let viewsDictionary: [String: AnyObject] = [
            "timeLable": timeLabel,
            "playButton": playButton,
            "shareButton": shareButton,
        ]

        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[timeLable]|", options: [], metrics: nil, views: viewsDictionary)

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-30-[timeLable]-(>=0)-[playButton]-(>=0)-[shareButton]|", options: [.alignAllCenterY, .alignAllTop, .alignAllBottom], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activate(constraintsV)
        NSLayoutConstraint.activate(constraintsH)

        let playButtonConstraintCenterX = NSLayoutConstraint(item: playButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activate([playButtonConstraintCenterX])
    }

    // MARK: Actions

    func playOrPause() {

        switch playState {

        case .playing:
            if let action = pauseAction {
                action(self)
            }

        case .pause:
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

    override func draw(_ rect: CGRect) {

        let startColor: UIColor = UIColor.clear
        let endColor: UIColor = UIColor.black.withAlphaComponent(0.2)

        let context = UIGraphicsGetCurrentContext()
        let colors = [startColor.cgColor, endColor.cgColor]

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        let colorLocations:[CGFloat] = [0.0, 1.0]

        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)

        let startPoint = CGPoint.zero
        let endPoint = CGPoint(x:0, y: rect.height)

        context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))
    }
}


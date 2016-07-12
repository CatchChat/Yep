//
//  MeetGeniusShowView.swift
//  Yep
//
//  Created by NIX on 16/6/29.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Kingfisher

class MeetGeniusShowView: UIView {

    var tapAction: ((banner: GeniusInterviewBanner) -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .ScaleAspectFill
        view.userInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(MeetGeniusShowView.didTap(_:)))
        view.addGestureRecognizer(tap)

        return view
    }()

    lazy var showButton: UIButton = {
        let button = UIButton()
        button.setTitle("SHOW", forState: .Normal)
        button.backgroundColor = UIColor.blueColor()
        return button
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello World!"
        return label
    }()

    private var geniusInterviewBanner: GeniusInterviewBanner?

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()

        getLatestGeniusInterviewBanner()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeUI() {

        do {
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(backgroundImageView)

            let views = [
                "backgroundImageView": backgroundImageView,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }
    }

    func getLatestGeniusInterviewBanner() {

        latestGeniusInterviewBanner(failureHandler: nil, completion: { [weak self] geniusInterviewBanner in

            self?.geniusInterviewBanner = geniusInterviewBanner

            SafeDispatch.async { [weak self] in
                let imageURL = geniusInterviewBanner.imageURL
                self?.backgroundImageView.kf_setImageWithURL(imageURL, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
            }
        })
    }

    @objc private func didTap(sender: UITapGestureRecognizer) {

        if let banner = geniusInterviewBanner {
            tapAction?(banner: banner)
        }
    }
}


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

    var tapAction: ((_ banner: GeniusInterviewBanner) -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.isUserInteractionEnabled = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(MeetGeniusShowView.didTap(_:)))
        view.addGestureRecognizer(tap)

        return view
    }()

    lazy var showButton: UIButton = {
        let button = UIButton()
        button.setTitle("SHOW", for: UIControlState())
        button.backgroundColor = UIColor.blue
        return button
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hello World!"
        return label
    }()

    fileprivate var geniusInterviewBanner: GeniusInterviewBanner?

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()

        getLatestGeniusInterviewBanner()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func makeUI() {

        do {
            backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(backgroundImageView)

            let views = [
                "backgroundImageView": backgroundImageView,
            ]

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
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

    @objc fileprivate func didTap(_ sender: UITapGestureRecognizer) {

        if let banner = geniusInterviewBanner {
            tapAction?(banner: banner)
        }
    }
}


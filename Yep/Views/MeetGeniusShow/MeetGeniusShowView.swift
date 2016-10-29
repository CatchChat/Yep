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
import RealmSwift

class MeetGeniusShowView: UIView {

    var tapAction: ((_ banner: GeniusInterviewBanner) -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.isUserInteractionEnabled = true
        view.clipsToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(MeetGeniusShowView.didTap(_:)))
        view.addGestureRecognizer(tap)

        return view
    }()

    fileprivate var geniusInterviewBanner: GeniusInterviewBanner? {
        didSet {
            if let imageURL = geniusInterviewBanner?.imageURL {
                SafeDispatch.async { [weak self] in
                    self?.backgroundImageView.kf.setImage(with: imageURL, placeholder: nil, options: MediaOptionsInfos)
                }
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true

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

        if let realm = try? Realm(), let offlineJSON = OfflineJSON.withName(.geniusInterviewBanner, inRealm: realm) {
            if let data = offlineJSON.JSON {
                geniusInterviewBanner = GeniusInterviewBanner(data)
            }
        }

        latestGeniusInterviewBanner(failureHandler: nil, completion: { [weak self] geniusInterviewBanner in
            self?.geniusInterviewBanner = geniusInterviewBanner
        })
    }

    @objc fileprivate func didTap(_ sender: UITapGestureRecognizer) {

        if let banner = geniusInterviewBanner {
            tapAction?(banner)
        }
    }
}


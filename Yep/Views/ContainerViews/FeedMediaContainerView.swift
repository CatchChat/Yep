//
//  FeedMediaContainerView.swift
//  Yep
//
//  Created by nixzhu on 15/12/16.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepPreview
import Ruler

final class FeedMediaContainerView: UIView {

    var tapMediaAction: ((_ transitionReference: Reference) -> Void)?

    lazy var backgroundImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_feedContainerBackground
        return imageView
    }()

    lazy var mediaImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var horizontalLineView: HorizontalLineView = {
        let view = HorizontalLineView()
        view.atBottom = false
        view.backgroundColor = UIColor.white
        return view
    }()

    lazy var linkContainerView: LinkContainerView = {
        let view = LinkContainerView()
        return view
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        mediaImageView.isUserInteractionEnabled = true
        let tapMedia = UITapGestureRecognizer(target: self, action: #selector(FeedMediaContainerView.tapMedia(_:)))
        mediaImageView.addGestureRecognizer(tapMedia)
    }

    fileprivate func makeUI() {

        addSubview(backgroundImageView)
        addSubview(mediaImageView)
        addSubview(horizontalLineView)
        addSubview(linkContainerView)

        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        mediaImageView.translatesAutoresizingMaskIntoConstraints = false
        horizontalLineView.translatesAutoresizingMaskIntoConstraints = false
        linkContainerView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "backgroundImageView": backgroundImageView,
            "mediaImageView": mediaImageView,
            "horizontalLineView": horizontalLineView,
            "linkContainerView": linkContainerView,
        ]

        let backgroundH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        let backgroundV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[backgroundImageView]|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(backgroundH)
        NSLayoutConstraint.activate(backgroundV)

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[mediaImageView]|", options: [], metrics: nil, views: views)

        let linkContainerViewHeight: CGFloat = Ruler.iPhoneHorizontal(44, 50, 50).value

        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[mediaImageView][linkContainerView(linkContainerViewHeight)]|", options: [.alignAllLeading, .alignAllTrailing], metrics: ["linkContainerViewHeight": linkContainerViewHeight], views: views)

        let horizontalLineViewH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[horizontalLineView]|", options: [], metrics: nil, views: views)
        let horizontalLineViewV = NSLayoutConstraint.constraints(withVisualFormat: "V:[horizontalLineView(1)]", options: [], metrics: nil, views: views)
        let horizontalLineViewTop = NSLayoutConstraint(item: horizontalLineView, attribute: .top, relatedBy: .equal, toItem: linkContainerView, attribute: .top, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)

        NSLayoutConstraint.activate(horizontalLineViewH)
        NSLayoutConstraint.activate(horizontalLineViewV)
        NSLayoutConstraint.activate([horizontalLineViewTop])
    }

    @objc fileprivate func tapMedia(_ sender: UITapGestureRecognizer) {
        tapMediaAction?(transitionReference)
    }
}

extension FeedMediaContainerView: Previewable {

    var transitionReference: Reference {
        return Reference(view: mediaImageView, image: mediaImageView.image)
    }
}

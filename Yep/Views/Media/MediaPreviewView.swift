//
//  MediaPreviewView.swift
//  
//
//  Created by NIX on 15/6/15.
//
//

import UIKit

class MediaPreviewView: UIView {

    var message: Message?

    lazy var mediaView: MediaView = {
        let view = MediaView()
        return view
        }()

    lazy var mediaControlView: MediaControlView = {
        let view = MediaControlView()
        return view
        }()


    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {
        addSubview(mediaView)
        addSubview(mediaControlView)

        mediaView.setTranslatesAutoresizingMaskIntoConstraints(false)
        mediaControlView.setTranslatesAutoresizingMaskIntoConstraints(false)

        let viewsDictionary = [
            "mediaView": mediaView,
            "mediaControlView": mediaControlView,
        ]

        let mediaViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[mediaView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let mediaViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mediaView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(mediaViewConstraintsV)
        NSLayoutConstraint.activateConstraints(mediaViewConstraintsH)


        let mediaControlViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[mediaControlView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        let mediaControlViewConstraintHeight = NSLayoutConstraint(item: mediaControlView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 50)

        let mediaControlViewConstraintBottom = NSLayoutConstraint(item: mediaControlView, attribute: .Bottom, relatedBy: .Equal, toItem: self, attribute: .Bottom, multiplier: 1.0, constant: 0)

        NSLayoutConstraint.activateConstraints(mediaControlViewConstraintsH)
        NSLayoutConstraint.activateConstraints([mediaControlViewConstraintHeight, mediaControlViewConstraintBottom])
    }


    func showMessage(message: Message, inView view: UIView?) {
        if let superView = view {

            superView.addSubview(self)

            frame = superView.bounds

            backgroundColor = UIColor.redColor()
        }
    }
}

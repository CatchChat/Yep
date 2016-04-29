//
//  ActivityIndicatorTitleView.swift
//  Yep
//
//  Created by nixzhu on 15/9/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class ActivityIndicatorTitleView: UIView {

    enum State {
        case Normal
        case Active
    }
    var state: State = .Normal {
        willSet {
            switch newValue {

            case .Normal:
                activityIndicator?.stopAnimating()

                singleTitleLabel?.hidden = false
                rightTitleLabel?.hidden = true

            case .Active:
                activityIndicator?.startAnimating()

                singleTitleLabel?.hidden = true
                rightTitleLabel?.hidden = false
            }
        }
    }

    private var singleTitleLabel: UILabel?

    private var activityIndicator: UIActivityIndicatorView?
    private var rightTitleLabel: UILabel?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()
    }

    func makeUI() {

        do {
            let label = UILabel()
            label.text = NSLocalizedString("Yep", comment: "")
            label.textColor = UIColor.yepNavgationBarTitleColor()
            label.font = UIFont.navigationBarTitleFont()
            label.textAlignment = .Center

            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)

            self.singleTitleLabel = label

            let viewsDictionary: [String: AnyObject] = [
                "label": label,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
            let helperView = UIView()
            helperView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(helperView)

            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
            activityIndicator.tintColor = UIColor.yepNavgationBarTitleColor()
            activityIndicator.hidesWhenStopped = true

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false

            self.activityIndicator = activityIndicator

            helperView.addSubview(activityIndicator)

            let label = UILabel()
            label.text = NSLocalizedString("Fetching", comment: "")
            label.textColor = UIColor.yepNavgationBarTitleColor()

            label.translatesAutoresizingMaskIntoConstraints = false

            self.rightTitleLabel = label

            helperView.addSubview(label)

            let helperViewCenterX = NSLayoutConstraint(item: helperView, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0)
            let helperViewCenterY = NSLayoutConstraint(item: helperView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)

            NSLayoutConstraint.activateConstraints([helperViewCenterX, helperViewCenterY])

            let viewsDictionary: [String: AnyObject] = [
                "activityIndicator": activityIndicator,
                "label": label,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[activityIndicator]-[label]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)
            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[activityIndicator]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: viewsDictionary)
            
            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        state = .Normal
    }
}


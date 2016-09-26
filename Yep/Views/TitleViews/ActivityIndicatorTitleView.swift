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
        case normal
        case active
    }
    var state: State = .normal {
        willSet {
            switch newValue {

            case .normal:
                activityIndicator?.stopAnimating()

                singleTitleLabel?.isHidden = false
                rightTitleLabel?.isHidden = true

            case .active:
                activityIndicator?.startAnimating()

                singleTitleLabel?.isHidden = true
                rightTitleLabel?.isHidden = false
            }
        }
    }

    fileprivate var singleTitleLabel: UILabel?

    fileprivate var activityIndicator: UIActivityIndicatorView?
    fileprivate var rightTitleLabel: UILabel?

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
            label.textAlignment = .center

            label.translatesAutoresizingMaskIntoConstraints = false
            addSubview(label)

            self.singleTitleLabel = label

            let viewsDictionary: [String: AnyObject] = [
                "label": label,
            ]

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[label]|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: viewsDictionary)
            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[label]|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: viewsDictionary)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
        }

        do {
            let helperView = UIView()
            helperView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(helperView)

            let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
            activityIndicator.tintColor = UIColor.yepNavgationBarTitleColor()
            activityIndicator.hidesWhenStopped = true

            activityIndicator.translatesAutoresizingMaskIntoConstraints = false

            self.activityIndicator = activityIndicator

            helperView.addSubview(activityIndicator)

            let label = UILabel()
            label.text = String.trans_promptFetching
            label.textColor = UIColor.yepNavgationBarTitleColor()

            label.translatesAutoresizingMaskIntoConstraints = false

            self.rightTitleLabel = label

            helperView.addSubview(label)

            let helperViewCenterX = NSLayoutConstraint(item: helperView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)
            let helperViewCenterY = NSLayoutConstraint(item: helperView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)

            NSLayoutConstraint.activate([helperViewCenterX, helperViewCenterY])

            let viewsDictionary: [String: AnyObject] = [
                "activityIndicator": activityIndicator,
                "label": label,
            ]

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[activityIndicator]-[label]|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: viewsDictionary)
            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[activityIndicator]|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: viewsDictionary)
            
            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
        }

        state = .normal
    }
}


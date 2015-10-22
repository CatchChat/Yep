//
//  PickFeedSkillView.swift
//  Yep
//
//  Created by nixzhu on 15/10/22.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class PickFeedSkillView: UIView {

    lazy var skillsCollectionView: UICollectionView = {
        let view = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
        view.backgroundColor = UIColor.redColor()
        return view
        }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        makeUI()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        makeUI()
    }

    private func makeUI() {

        backgroundColor = UIColor.lightGrayColor()

        addSubview(skillsCollectionView)
        skillsCollectionView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "skillsCollectionView": skillsCollectionView,
        ]

        let skillsCollectionViewConstraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[skillsCollectionView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)

        let skillsCollectionViewConstraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[skillsCollectionView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(skillsCollectionViewConstraintsH)
        NSLayoutConstraint.activateConstraints(skillsCollectionViewConstraintsV)
    }
}


//
//  PickFeedSkillView.swift
//  Yep
//
//  Created by nixzhu on 15/10/22.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class PickFeedSkillView: UIView {

    let pickFeedSkillCellID = "PickFeedSkillCell"

    lazy var skillsCollectionView: UICollectionView = {

        let layout = PickFeedSkillLayout()

        let view = UICollectionView(frame: CGRectZero, collectionViewLayout: layout)

        view.pagingEnabled = true

        view.backgroundColor = UIColor.lightGrayColor()

        view.registerNib(UINib(nibName: self.pickFeedSkillCellID, bundle: nil), forCellWithReuseIdentifier: self.pickFeedSkillCellID)

        view.dataSource = self
        view.delegate = self

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

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate

extension PickFeedSkillView: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 15
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(pickFeedSkillCellID, forIndexPath: indexPath) as! PickFeedSkillCell

        cell.skillLabel.text = "Swift \(indexPath.item)"

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSize(width: collectionView.bounds.width, height: 44)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {

        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}


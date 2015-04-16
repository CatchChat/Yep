//
//  RegisterSelectSkillsViewController.swift
//  Yep
//
//  Created by NIX on 15/4/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class RegisterSelectSkillsViewController: UIViewController {

    var annotationText: String = ""

    @IBOutlet weak var annotationLabel: UILabel!

    @IBOutlet weak var skillCategoriesCollectionView: UICollectionView!

    let skillCategoryCellIdentifier = "SkillCategoryCell"

    lazy var collectionViewWidth: CGFloat = {
        return CGRectGetWidth(self.skillCategoriesCollectionView.bounds)
        }()

    var skillCategories = [
        [
            "categoryName": "Technology",
            "categoryImage": UIImage(named: "icon_skill_tech")!,
        ],
        [
            "categoryName": "Art",
            "categoryImage": UIImage(named: "icon_skill_art")!,
        ],
        [
            "categoryName": "Music",
            "categoryImage": UIImage(named: "icon_skill_music")!,
        ],
        [
            "categoryName": "Life Style",
            "categoryImage": UIImage(named: "icon_skill_life")!,
        ],
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        skillCategoriesCollectionView.registerNib(UINib(nibName: skillCategoryCellIdentifier, bundle: nil), forCellWithReuseIdentifier: skillCategoryCellIdentifier)

        annotationLabel.text = annotationText

        let tap = UITapGestureRecognizer(target: self, action: "dismiss")
        view.addGestureRecognizer(tap)
    }

    func dismiss() {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: UICollectionViewDataSource, UICollectionViewDelegate

extension RegisterSelectSkillsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return skillCategories.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(skillCategoryCellIdentifier, forIndexPath: indexPath) as! SkillCategoryCell

        let skillCategoryInfo = skillCategories[indexPath.item]

        cell.categoryTitle = skillCategoryInfo["categoryName"] as? String
        cell.categoryImage = skillCategoryInfo["categoryImage"] as? UIImage

        return cell
    }

    func collectionView(collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, sizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {

        return CGSizeMake(collectionViewWidth, 60)
    }
}